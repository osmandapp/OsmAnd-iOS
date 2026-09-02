//
//  CoordinateFormatSelectorViewController.swift
//  OsmAnd Maps
//
//  Created by Vitaliy Sova on 13.08.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

@objc protocol CoordinateFormatSelectorDelegate: AnyObject {
    func coordinateFormatSelector(_ selector: CoordinateFormatSelectorViewController,
                                  didSelectFormatId formatId: String)
    func coordinateFormatSelectorDidRequestOtherFormat(_ selector: CoordinateFormatSelectorViewController)
}

@objcMembers
final class CoordinateFormatSelectorViewController: OABaseNavbarViewController {
    private enum Key: String {
        case formatId, isSelected, isPrimary, selectOther
    }

    weak var selectorDelegate: CoordinateFormatSelectorDelegate?

    private let selectedFormatId: String
    private let showSelectOther: Bool
    private var preferredFormats: [CoordinateFormat] = []
    private var recentFormats: [CoordinateFormat] = []

    private var storage: CoordinateFormatSettingsStorage {
        OAAppSettings.sharedManager().coordinateFormatSettingsStorage
    }

    // MARK: - Init

    init(selectedFormatId: String?, showSelectOther: Bool = true) {
        let settings = OAAppSettings.sharedManager()
        let primary = settings.coordinateFormatSettingsStorage.getPrimaryId(
            settings.applicationMode.get()
        )
        self.selectedFormatId = CoordinateFormatIds.normalize(selectedFormatId) ?? primary
        self.showSelectOther = showSelectOther
        super.init()
    }

    @objc convenience init(selectedFormatId: String?) {
        self.init(selectedFormatId: selectedFormatId, showSelectOther: true)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc static func present(from presenter: UIViewController,
                              selectedFormatId: String?,
                              delegate: CoordinateFormatSelectorDelegate?) {
        let vc = CoordinateFormatSelectorViewController(selectedFormatId: selectedFormatId)
        vc.selectorDelegate = delegate
        presenter.showMediumToLargeSheetViewController(vc)
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.sectionHeaderTopPadding = 0
        reloadFormats()
    }

    // MARK: - Navbar

    override func getTitle() -> String? {
        localizedString("coords_format")
    }

    override func systemLeftBarButtonItem() -> UIBarButtonItem? {
        UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(closePressed))
    }

    // MARK: - Table setup

    override func registerCells() {
        addCell(OASimpleTableViewCell.reuseIdentifier)
    }
    
    override func getCustomHeight(forHeader section: Int) -> CGFloat {
        let selectOtherSection = recentFormats.isEmpty ? 1 : 2
        if section == 0 || section == selectOtherSection {
            return 16
        }
        return UITableView.automaticDimension
    }
    
    override func getCustomHeight(forFooter section: Int) -> CGFloat {
        if section == 0 {
            return UITableView.automaticDimension
        }
        return CGFloat.leastNormalMagnitude
    }

    override func generateData() {
        tableData.clearAllData()

        let preferredSection = tableData.createNewSection()
        for (index, format) in preferredFormats.enumerated() {
            appendFormatRow(format,
                            to: preferredSection,
                            selected: format.id == selectedFormatId,
                            primary: index == 0)
        }

        if !recentFormats.isEmpty {
            let recentSection = tableData.createNewSection()
            recentSection.headerText = localizedString("shared_string_recent")
            for format in recentFormats {
                appendFormatRow(format,
                                to: recentSection,
                                selected: format.id == selectedFormatId,
                                primary: false)
            }
        }

        if showSelectOther {
            let otherSection = tableData.createNewSection()
            let row = otherSection.createNewRow()
            row.cellType = OASimpleTableViewCell.reuseIdentifier
            row.title = localizedString("coordinate_format_select_other")
            row.key = Key.selectOther.rawValue
        }
    }

    override func getRow(_ indexPath: IndexPath?) -> UITableViewCell? {
        guard let indexPath else { return nil }
        let item = tableData.item(for: indexPath)
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: OASimpleTableViewCell.reuseIdentifier,
            for: indexPath
        ) as? OASimpleTableViewCell else { return nil }

        cell.selectionStyle = .default
        cell.accessoryType = .none

        if item.key == Key.selectOther.rawValue {
            cell.leftIconVisibility(false)
            cell.descriptionVisibility(false)
            cell.titleLabel.text = item.title
            cell.titleLabel.textColor = .textColorActive
            cell.configureAccessibility(withTitle: item.title, selected: false)
            return cell
        }

        cell.titleLabel.textAlignment = .natural
        cell.titleLabel.textColor = .textColorPrimary
        cell.titleLabel.text = item.title

        let isPrimary = (item.obj(forKey: Key.isPrimary.rawValue) as? NSNumber)?.boolValue == true
        let descr: String
        if isPrimary {
            let example = item.descr ?? ""
            descr = example.isEmpty
                ? localizedString("coordinate_format_primary")
                : "\(localizedString("coordinate_format_primary")) • \(example)"
        } else {
            descr = item.descr ?? ""
        }
        cell.descriptionVisibility(!descr.isEmpty)
        cell.descriptionLabel.text = descr
        cell.descriptionLabel.font = .preferredFont(forTextStyle: .subheadline)

        let selected = (item.obj(forKey: Key.isSelected.rawValue) as? NSNumber)?.boolValue == true
        cell.leftIconVisibility(true)
        if selected {
            cell.leftIconView.image = .icCheckmarkDefault
            cell.leftIconView.tintColor = .iconColorActive
        } else {
            cell.leftIconView.image = UIImage()
            cell.leftIconView.tintColor = .clear
        }
        
        cell.textStackView.spacing = 4
        
        let accessibilityTitle: String
        if let title = item.title, !descr.isEmpty {
            accessibilityTitle = "\(title), \(descr)"
        } else {
            accessibilityTitle = item.title ?? ""
        }
        cell.configureAccessibility(withTitle: accessibilityTitle, selected: selected)
        
        return cell
    }

    override func getTitleForHeader(_ section: Int) -> String? {
        tableData.sectionData(for: UInt(section)).headerText
    }

    override func onRowSelected(_ indexPath: IndexPath?) {
        guard let indexPath else { return }
        let item = tableData.item(for: indexPath)

        if item.key == Key.selectOther.rawValue {
            let delegate = selectorDelegate
            dismiss(animated: true) {
                delegate?.coordinateFormatSelectorDidRequestOtherFormat(self)
            }
            return
        }

        guard let formatId = item.obj(forKey: Key.formatId.rawValue) as? String else { return }
        let delegate = selectorDelegate
        dismiss(animated: true) {
            delegate?.coordinateFormatSelector(self, didSelectFormatId: formatId)
        }
    }

    // MARK: - Data
    
    private func appendFormatRow(_ format: CoordinateFormat,
                                 to section: OATableSectionData,
                                 selected: Bool,
                                 primary: Bool) {
        let row = section.createNewRow()
        row.cellType = OASimpleTableViewCell.reuseIdentifier
        row.title = format.title
        if let code = format.epsgCode {
            row.descr = "EPSG:\(code)"
        } else {
            row.descr = CoordinateFormatHelper.exampleString(format)
        }
        row.setObj(format.id, forKey: Key.formatId.rawValue)
        row.setObj(NSNumber(value: selected), forKey: Key.isSelected.rawValue)
        row.setObj(NSNumber(value: primary), forKey: Key.isPrimary.rawValue)
    }

    private func reloadFormats() {
        let mode = OAAppSettings.sharedManager().applicationMode.get()
        let preferredIds = storage.preferredIds(mode)
        var recentIds = storage.getRecentIds().filter { !preferredIds.contains($0) }

        if !preferredIds.contains(selectedFormatId),
           !recentIds.contains(selectedFormatId) {
            recentIds.insert(selectedFormatId, at: 0)
        }

        preferredFormats = CoordinateFormatHelper.resolve(preferredIds)
        recentFormats = CoordinateFormatHelper.resolve(recentIds)
        generateData()
        tableView.reloadData()
    }
    
    // MARK: - Actions
    
    @objc private func closePressed() {
        dismiss(animated: true)
    }
}

@objcMembers
final class CoordinateFormatSelectorRouter: NSObject {
    @objc static func presentAdd(from presenter: UIViewController,
                                 excludedIds: [String],
                                 onSelected: @escaping (String) -> Void) {
        let mode = OAAppSettings.sharedManager().applicationMode.get()
        let addVC = CoordinatesFormatAddViewController(appMode: mode, excludedIds: excludedIds)
        addVC.onFormatAdded = { id in
            OAAppSettings.sharedManager().coordinateFormatSettingsStorage.addRecentId(id)
            presenter.dismiss(animated: true) { onSelected(id) }
        }
        let navVC = UINavigationController(rootViewController: addVC)
        navVC.modalPresentationStyle = .pageSheet
        presenter.present(navVC, animated: true)
    }
}
