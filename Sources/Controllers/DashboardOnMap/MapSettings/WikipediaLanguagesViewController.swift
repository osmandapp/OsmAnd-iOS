//
//  WikipediaLanguagesViewController.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 25.12.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objc protocol WikipediaScreenDelegate: AnyObject {
    func updateWikipediaSettings()
}

@objcMembers
final class WikiLanguageItem: NSObject {
    let locale: String
    let title: String
    let preferred: Bool
    var checked: Bool
    
    init(locale: String, title: String, checked: Bool, preferred: Bool) {
        self.locale = locale
        self.title = title
        self.checked = checked
        self.preferred = preferred
    }
    
    func compare(_ object: WikiLanguageItem) -> ComparisonResult {
        if checked != object.checked {
            return checked ? .orderedAscending : .orderedDescending
        }
        
        return (title as NSString).localizedCaseInsensitiveCompare(object.title)
    }
}

private enum RowKey: String {
    case allLanguagesSwitchRow
    case languageRow
}

@objcMembers
final class WikipediaLanguagesViewController: OABaseSettingsViewController {
    weak var wikipediaDelegate: WikipediaScreenDelegate?
    
    private static let itemKey = "itemKey"
    
    private let app = OsmAndApp.swiftInstance()
    private let wikiPlugin = OAPluginsHelper.getPlugin(OAWikipediaPlugin.self) as! OAWikipediaPlugin
    
    private var languages: [WikiLanguageItem] = []
    private var isGlobalWikiPoiEnabled = false
    private var data = OATableDataModel()
    
    override func postInit() {
        languages.removeAll()
        var preferredLocales: [String] = []
        for langCode in Locale.preferredLanguages {
            guard let dash = langCode.firstIndex(of: "-"), dash < langCode.index(before: langCode.endIndex) else { continue }
            preferredLocales.append(String(langCode[..<dash]))
        }
        
        isGlobalWikiPoiEnabled = wikiPlugin.isShowAllLanguages(appMode)
        let allLocales: [String] = OAPOIHelper.sharedInstance().getAllAvailableWikiLocales() ?? []
        if wikiPlugin.hasLanguagesFilter(appMode) {
            let enabledWikiPoiLocales: [String] = wikiPlugin.getLanguagesToShow(appMode) ?? []
            for locale in allLocales {
                let checked = enabledWikiPoiLocales.contains(locale)
                let preferred = preferredLocales.contains(locale)
                languages.append(WikiLanguageItem(locale: locale, title: OAUtilities.translatedLangName(locale), checked: checked, preferred: preferred))
            }
        } else {
            isGlobalWikiPoiEnabled = true
            for locale in allLocales {
                let preferred = preferredLocales.contains(locale)
                languages.append(WikiLanguageItem(locale: locale, title: OAUtilities.translatedLangName(locale), checked: false, preferred: preferred))
            }
        }
        
        languages.sort { $0.compare($1) == .orderedAscending }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.setEditing(true, animated: true)
        tableView.allowsMultipleSelectionDuringEditing = true
    }
    
    override func registerCells() {
        tableView.register(UINib(nibName: OASwitchTableViewCell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: OASwitchTableViewCell.reuseIdentifier)
        tableView.register(UINib(nibName: OASimpleTableViewCell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: OASimpleTableViewCell.reuseIdentifier)
    }
    
    override func getTitle() -> String {
        localizedString("shared_string_language")
    }
    
    override func getSubtitle() -> String {
        ""
    }
    
    override func getLeftNavbarButtonTitle() -> String {
        localizedString("shared_string_cancel")
    }
    
    override func getRightNavbarButtons() -> [UIBarButtonItem] {
        [createRightNavbarButton(localizedString("shared_string_done"), iconName: nil, action: #selector(onRightNavbarButtonPressed), menu: nil)]
    }
    
    override func getTableHeaderDescription() -> String {
        "\(localizedString("some_articles_may_not_available_in_lang"))\n\n\(localizedString("select_wikipedia_article_langs"))"
    }
    
    override func hideFirstHeader() -> Bool {
        true
    }
    
    override func generateData() {
        data.clearAllData()
        
        let switchSection = data.createNewSection()
        let switchRow = switchSection.createNewRow()
        switchRow.cellType = OASwitchTableViewCell.reuseIdentifier
        switchRow.key = RowKey.allLanguagesSwitchRow.rawValue
        switchRow.title = localizedString("shared_string_all_languages")
        if !isGlobalWikiPoiEnabled {
            let preferredSection = data.createNewSection()
            preferredSection.headerText = localizedString("preferred_languages")
            let availableSection = data.createNewSection()
            availableSection.headerText = localizedString("available_languages")
            for lang in languages {
                let target = lang.preferred ? preferredSection : availableSection
                let row = target.createNewRow()
                row.cellType = OASimpleTableViewCell.reuseIdentifier
                row.key = RowKey.languageRow.rawValue
                row.title = lang.title.capitalized
                row.setObj(lang, forKey: Self.itemKey)
            }
        }
    }
    
    override func sectionsCount() -> Int {
        Int(data.sectionCount())
    }
    
    override func rowsCount(_ section: Int) -> Int {
        Int(data.rowCount(UInt(section)))
    }
    
    override func getTitleForHeader(_ section: Int) -> String {
        data.sectionData(for: UInt(section)).headerText
    }
    
    override func getRow(_ indexPath: IndexPath) -> UITableViewCell {
        let item = data.item(for: indexPath)
        if item.cellType == OASwitchTableViewCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: OASwitchTableViewCell.reuseIdentifier) as! OASwitchTableViewCell
            cell.leftIconVisibility(false)
            cell.descriptionVisibility(false)
            cell.titleLabel.text = item.title
            cell.switchView.setOn(isGlobalWikiPoiEnabled, animated: false)
            cell.switchView.tag = indexPath.section << 10 | indexPath.row
            cell.switchView.removeTarget(nil, action: nil, for: .allEvents)
            cell.switchView.addTarget(self, action: #selector(onSwitchPressed(_:)), for: .valueChanged)
            return cell
        }
        if item.cellType == OASimpleTableViewCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: OASimpleTableViewCell.reuseIdentifier) as! OASimpleTableViewCell
            cell.leftIconVisibility(false)
            cell.descriptionVisibility(false)
            cell.titleLabel.text = item.title
            return cell
        }
        
        return UITableViewCell()
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        data.item(for: indexPath).cellType == OASimpleTableViewCell.reuseIdentifier
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let item = data.item(for: indexPath)
        guard item.cellType == OASimpleTableViewCell.reuseIdentifier, let lang = item.obj(forKey: Self.itemKey) as? WikiLanguageItem else { return }
        cell.setSelected(lang.checked, animated: false)
        if lang.checked {
            tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        } else {
            tableView.deselectRow(at: indexPath, animated: false)
        }
    }
    
    override func onRowSelected(_ indexPath: IndexPath!) {
        let item = data.item(for: indexPath)
        guard item.cellType == OASimpleTableViewCell.reuseIdentifier, let lang = item.obj(forKey: Self.itemKey) as? WikiLanguageItem else { return }
        lang.checked.toggle()
    }
    
    override func onRowDeselected(_ indexPath: IndexPath!) {
        let item = data.item(for: indexPath)
        guard item.cellType == OASimpleTableViewCell.reuseIdentifier, let lang = item.obj(forKey: Self.itemKey) as? WikiLanguageItem else { return }
        lang.checked.toggle()
    }
    
    override func onRightNavbarButtonPressed() {
        applyPreference(applyToAllProfiles: false)
        wikipediaDelegate?.updateWikipediaSettings()
        dismiss()
    }
    
    private func applyPreference(applyToAllProfiles: Bool) {
        languages.sort { $0.compare($1) == .orderedAscending }
        let localesForSaving: [String] = languages.compactMap { $0.checked ? $0.locale : nil }
        let showAll = localesForSaving.isEmpty ? true : isGlobalWikiPoiEnabled
        if applyToAllProfiles {
            let modes = OAApplicationMode.allPossibleValues() ?? []
            for mode in modes {
                wikiPlugin.setLanguagesToShow(mode, languagesToShow: localesForSaving)
                wikiPlugin.setShowAllLanguages(mode, showAllLanguages: showAll)
            }
        } else {
            wikiPlugin.setLanguagesToShow(appMode, languagesToShow: localesForSaving)
            wikiPlugin.setShowAllLanguages(appMode, showAllLanguages: showAll)
        }
        
        wikiPlugin.updateWikipediaState()
    }
    
    @objc private func onSwitchPressed(_ sw: UISwitch) {
        isGlobalWikiPoiEnabled = sw.isOn
        generateData()
        tableView.reloadData()
    }
}
