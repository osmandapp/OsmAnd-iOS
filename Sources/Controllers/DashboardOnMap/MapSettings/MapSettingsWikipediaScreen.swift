//
//  MapSettingsWikipediaScreen.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 22.12.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

private enum RowKey: String {
    case wikipediaSwitchRowKey
    case languagesRowKey
    case dataSourceRowKey
    case showImagePreviewsRowKey
    case mapItemRowKey
}

private enum ObjKey {
    static let isEnabled = "isEnabled"
    static let resourceId = "resourceId"
    static let resourceItem = "resourceItem"
    static let isOffline = "isOffline"
}

@objcMembers
final class MapSettingsWikipediaScreen: NSObject, OAMapSettingsScreen {
    private static let mapCellType = "mapCell"
    
    var settingsScreen: EMapSettingsScreen = .wikipedia
    var vwController: OADashboardViewController?
    var tblView: UITableView?
    var title: String?
    var isOnlineMapSource = false
    var tableData: [Any]?
    
    private let app = OsmAndApp.swiftInstance()
    private let wikiPlugin = OAPluginsHelper.getPlugin(OAWikipediaPlugin.self) as! OAWikipediaPlugin
    private let settings = OAAppSettings.sharedManager()
    private let mapViewController = OARootViewController.instance().mapPanel.mapViewController
    
    private var iapHelper = OAIAPHelper.sharedInstance()
    private var downloadingHelper = DownloadingCellResourceHelper()
    private var data = OATableDataModel()
    private var isWikipediaEnabled: Bool
    private var mapItems: [OAResourceSwiftItem] = []
    
    init(table tableView: UITableView, viewController: OADashboardViewController) {
        isWikipediaEnabled = app?.data.wikipedia ?? false
        super.init()
        self.tblView = tableView
        self.vwController = viewController
        self.title = wikiPlugin.popularPlacesTitle()
        setupDownloadingHelper()
    }
    
    init(table tableView: UITableView, viewController: OADashboardViewController, param: Any) {
        fatalError("init(table:viewController:param:)")
    }
    
    func setupView() {
        registerCells()
        updateResources()
    }
    
    func initData() {
        data.clearAllData()
        
        let wikipediaSwitchSection = data.createNewSection()
        let switchRow = wikipediaSwitchSection.createNewRow()
        switchRow.cellType = OASwitchTableViewCell.reuseIdentifier
        switchRow.key = RowKey.wikipediaSwitchRowKey.rawValue
        switchRow.title = localizedString(isWikipediaEnabled ? "shared_string_enabled" : "rendering_value_disabled_name")
        switchRow.icon = UIImage.templateImageNamed(isWikipediaEnabled ? "ic_custom_show" : "ic_custom_hide")
        switchRow.iconTintColor = isWikipediaEnabled ? .iconColorSelected : .iconColorDisabled
        switchRow.setObj(isWikipediaEnabled, forKey: ObjKey.isEnabled)
        guard isWikipediaEnabled else { return }
        
        let langSection = data.createNewSection()
        let langRow = langSection.createNewRow()
        langRow.cellType = OAValueTableViewCell.reuseIdentifier
        langRow.key = RowKey.languagesRowKey.rawValue
        langRow.title = localizedString("shared_string_language")
        langRow.icon = UIImage.templateImageNamed("ic_custom_map_languge")
        langRow.iconTintColor = .iconColorSelected
        langRow.descr = wikiPlugin.getLanguagesSummary()
        langSection.footerText = localizedString("select_wikipedia_article_langs")
        
        let previewSection = data.createNewSection()
        let isOffline = settings.wikiDataSourceType.get() == .offline
        let previewsEnabled = settings.wikiShowImagePreviews.get()
        let sourceRow = previewSection.createNewRow()
        sourceRow.cellType = OAButtonTableViewCell.reuseIdentifier
        sourceRow.key = RowKey.dataSourceRowKey.rawValue
        sourceRow.title = localizedString("poi_source")
        sourceRow.icon = (isOffline ? DataSourceType.offline : .online).icon?.withRenderingMode(.alwaysTemplate)
        sourceRow.iconTintColor = isOffline ? UIColor.iconColorDisabled : UIColor.iconColorSelected
        sourceRow.setObj(isOffline, forKey: ObjKey.isOffline)
        let previewsRow = previewSection.createNewRow()
        previewsRow.cellType = OASwitchTableViewCell.reuseIdentifier
        previewsRow.key = RowKey.showImagePreviewsRowKey.rawValue
        previewsRow.title = localizedString("show_image_previews")
        previewsRow.icon = UIImage.templateImageNamed(previewsEnabled ? "ic_custom_photo" : "ic_custom_photo_disable")
        previewsRow.iconTintColor = previewsEnabled ? .iconColorSelected : .iconColorDisabled
        previewsRow.setObj(previewsEnabled, forKey: ObjKey.isEnabled)
        
        if !mapItems.isEmpty {
            let availableSection = data.createNewSection()
            availableSection.headerText = localizedString("available_maps")
            availableSection.footerText = localizedString("wiki_menu_download_descr")
            for item in mapItems {
                let row = availableSection.createNewRow()
                row.cellType = Self.mapCellType
                row.key = RowKey.mapItemRowKey.rawValue
                row.icon = UIImage.templateImageNamed("ic_custom_wikipedia")
                row.setObj(item, forKey: ObjKey.resourceItem)
                row.setObj(item.resourceId() as Any, forKey: ObjKey.resourceId)
            }
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        Int(data.sectionCount())
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        Int(data.rowCount(UInt(section)))
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        data.sectionData(for: UInt(section)).headerText
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        data.sectionData(for: UInt(section)).footerText
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = data.item(for: indexPath)
        if item.cellType == OASwitchTableViewCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: OASwitchTableViewCell.reuseIdentifier) as! OASwitchTableViewCell
            cell.descriptionVisibility(false)
            cell.titleLabel.text = item.title
            cell.leftIconView.image = item.icon
            cell.leftIconView.tintColor = item.iconTintColor
            cell.switchView.setOn(item.bool(forKey: ObjKey.isEnabled), animated: false)
            cell.switchView.tag = indexPath.section << 10 | indexPath.row
            cell.switchView.removeTarget(nil, action: nil, for: .allEvents)
            cell.switchView.addTarget(self, action: #selector(onSwitchChanged(_:)), for: .valueChanged)
            return cell
        }
        if item.cellType == OAValueTableViewCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: OAValueTableViewCell.reuseIdentifier) as! OAValueTableViewCell
            cell.accessoryType = .disclosureIndicator
            cell.descriptionVisibility(false)
            cell.titleLabel.text = item.title
            cell.valueLabel.text = item.descr
            cell.leftIconView.image = item.icon
            cell.leftIconView.tintColor = item.iconTintColor
            return cell
        }
        if item.cellType == OAButtonTableViewCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: OAButtonTableViewCell.reuseIdentifier) as! OAButtonTableViewCell
            if cell.contentHeightConstraint == nil {
                let constraint = cell.contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 48.0)
                constraint.isActive = true
                cell.contentHeightConstraint = constraint
            }
            cell.selectionStyle = .none
            cell.descriptionVisibility(false)
            cell.titleLabel.text = item.title
            cell.leftIconView.image = item.icon
            cell.leftIconView.tintColor = item.iconTintColor
            var config = UIButton.Configuration.plain()
            config.contentInsets = .zero
            cell.button.configuration = config
            cell.button.menu = createDataSourceMenu(for: cell)
            cell.button.showsMenuAsPrimaryAction = true
            cell.button.changesSelectionAsPrimaryAction = true
            cell.button.setContentHuggingPriority(.required, for: .horizontal)
            cell.button.setContentCompressionResistancePriority(.required, for: .horizontal)
            return cell
        }
        if item.cellType == Self.mapCellType {
            if let resourceItem = item.obj(forKey: ObjKey.resourceItem) as? OAResourceSwiftItem, let cell = downloadingHelper.getOrCreateCell(resourceItem.resourceId(), swiftResourceItem: resourceItem) {
                return cell
            }
        }
        
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        let item = data.item(for: indexPath)
        return item.key == RowKey.wikipediaSwitchRowKey.rawValue ? nil : indexPath
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = data.item(for: indexPath)
        switch item.key {
        case RowKey.languagesRowKey.rawValue:
            guard let controller = WikipediaLanguagesViewController(appMode: settings.applicationMode.get()) else { break }
            controller.wikipediaDelegate = self
            vwController?.showModalViewController(controller)
        case RowKey.mapItemRowKey.rawValue:
            if let resourceId = item.string(forKey: ObjKey.resourceId) {
                downloadingHelper.onCellClicked(resourceId)
            }
        default:
            break
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    private func createDataSourceMenu(for cell: OAButtonTableViewCell) -> UIMenu {
        let isOffline = settings.wikiDataSourceType.get() == .offline
        let online = UIAction(title: DataSourceType.online.title, state: isOffline ? .off : .on) { [weak self, weak cell] _ in
            guard let self else { return }
            self.settings.wikiDataSourceType.set(.online)
            cell?.leftIconView.image = DataSourceType.online.icon?.withRenderingMode(.alwaysTemplate)
            cell?.leftIconView.tintColor = .iconColorSelected
            self.refreshPOI()
        }
        
        let offline = UIAction(title: DataSourceType.offline.title, state: isOffline ? .on : .off) { [weak self, weak cell] _ in
            guard let self else { return }
            self.settings.wikiDataSourceType.set(.offline)
            cell?.leftIconView.image = DataSourceType.offline.icon?.withRenderingMode(.alwaysTemplate)
            cell?.leftIconView.tintColor = .iconColorDisabled
            self.refreshPOI()
        }
        
        return UIMenu.composedMenu(from: [[online, offline]])
    }
    
    private func updateResources() {
        mapItems = OAResourcesUISwiftHelper.findWikiMapRegionsAtCurrentMapLocation()
        initData()
        tblView?.reloadData()
    }
    
    private func refreshPOI() {
        OARootViewController.instance()?.mapPanel.refreshMap()
        mapViewController.updatePoiLayer()
    }
    
    private func registerCells() {
        tblView?.register(UINib(nibName: OASwitchTableViewCell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: OASwitchTableViewCell.reuseIdentifier)
        tblView?.register(UINib(nibName: OAButtonTableViewCell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: OAButtonTableViewCell.reuseIdentifier)
        tblView?.register(UINib(nibName: OAValueTableViewCell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: OAValueTableViewCell.reuseIdentifier)
    }
    
    private func setupDownloadingHelper() {
        downloadingHelper.hostViewController = vwController
        downloadingHelper.setHostTableView(tblView)
        downloadingHelper.delegate = self
        downloadingHelper.rightIconStyle = .hideIconAfterDownloading
    }
    
    @objc private func onSwitchChanged(_ sender: Any) -> Bool {
        guard let sw = sender as? UISwitch else { return false }
        let indexPath = IndexPath(row: sw.tag & 0x3FF, section: sw.tag >> 10)
        let item = data.item(for: indexPath)
        switch item.key {
        case RowKey.wikipediaSwitchRowKey.rawValue:
            (OAPluginsHelper.getPlugin(OAWikipediaPlugin.self) as? OAWikipediaPlugin)?.wikipediaChanged(sw.isOn)
            if let app {
                isWikipediaEnabled = app.data.wikipedia
            } else {
                isWikipediaEnabled = sw.isOn
            }
            updateResources()
        case RowKey.showImagePreviewsRowKey.rawValue:
            settings.wikiShowImagePreviews.set(sw.isOn)
            initData()
            tblView?.reloadRows(at: [indexPath], with: .none)
            refreshPOI()
        default:
            break
        }
        
        return false
    }
}

extension MapSettingsWikipediaScreen: DownloadingCellResourceHelperDelegate {
    func onDownloadingCellResourceNeedUpdate(_ task: OADownloadTask?) {
        DispatchQueue.main.async { [weak self] in
            self?.updateResources()
        }
    }
    
    func onStopDownload(_ resourceItem: OAResourceSwiftItem) {
    }
}

extension MapSettingsWikipediaScreen: WikipediaScreenDelegate {
    func updateWikipediaSettings() {
        initData()
        tblView?.reloadData()
    }
}
