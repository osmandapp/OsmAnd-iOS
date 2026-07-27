//
//  SelectFavoriteGroupViewController.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 27.07.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

@objc protocol SelectFavoriteGroupDelegate: AnyObject {
    func onGroupSelected(_ selectedGroupName: String)
    func addNewGroup(withName name: String, iconName: String, color: UIColor, backgroundIconName: String)
    func selectColorItem(_ colorItem: PaletteItemSolid)
    @discardableResult func addAndGetNewColorItem(_ color: UIColor) -> PaletteItemSolid?
    @objc(changeColorItem:withColor:)
    func changeColorItem(_ colorItem: PaletteItemSolid, with color: UIColor)
    @discardableResult func duplicateColorItem(_ colorItem: PaletteItemSolid) -> PaletteItemSolid?
    func deleteColorItem(_ colorItem: PaletteItemSolid)
}

@objcMembers
final class SelectFavoriteGroupViewController: OABaseNavbarViewController {
    private enum RowKey: String {
        case addNewGroup
        case group
    }

    private enum ItemKey {
        static let title = "title"
        static let value = "value"
        static let description = "description"
        static let isSelected = "isSelected"
        static let color = "color"
    }
    
    weak var delegate: SelectFavoriteGroupDelegate?

    private let selectedGroupName: String?
    private let favoriteGroupNames: [String]?
    private let groupedGpxWpts: [[String: String]]?

    init(selectedGroupName: String?) {
        self.selectedGroupName = selectedGroupName
        favoriteGroupNames = nil
        groupedGpxWpts = nil
        super.init()
        initTableData()
    }

    init(selectedGroupName: String?, favoriteGroupNames: [String]) {
        self.selectedGroupName = selectedGroupName
        self.favoriteGroupNames = favoriteGroupNames.sorted {
            $0.localizedCaseInsensitiveCompare($1) == .orderedAscending
        }
        groupedGpxWpts = nil
        super.init()
        initTableData()
    }

    init(selectedGroupName: String?, gpxWptGroups: [[String: String]]) {
        self.selectedGroupName = selectedGroupName
        favoriteGroupNames = nil
        groupedGpxWpts = gpxWptGroups
        super.init()
        initTableData()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.separatorColor = .customSeparator
        tableView.tintColor = .iconColorActive
        tableView.keyboardDismissMode = .onDrag
    }

    override func registerCells() {
        addCell(OARightIconTableViewCell.reuseIdentifier)
        addCell(OASimpleTableViewCell.reuseIdentifier)
    }

    override func getTitle() -> String {
        localizedString("select_group")
    }

    override func getLeftNavbarButtonTitle() -> String {
        localizedString("shared_string_cancel")
    }

    override func getTableHeaderDescription() -> String {
        localizedString("select_group_descr")
    }

    override func hideFirstHeader() -> Bool {
        true
    }

    override func generateData() {
        tableData.clearAllData()

        let addGroupSection = tableData.createNewSection()
        let addGroupRow = addGroupSection.createNewRow()
        addGroupRow.cellType = OARightIconTableViewCell.reuseIdentifier
        addGroupRow.key = RowKey.addNewGroup.rawValue
        addGroupRow.title = localizedString("fav_add_new_group")
        addGroupRow.iconName = "ic_custom_add"

        let foldersSection = tableData.createNewSection()
        if let groupedGpxWpts {
            addGpxWptGroupRows(to: foldersSection, groups: groupedGpxWpts)
        } else {
            addFavoriteGroupRows(to: foldersSection)
        }
    }

    override func getRow(_ indexPath: IndexPath) -> UITableViewCell {
        let item = tableData.item(for: indexPath)

        if item.cellType == OARightIconTableViewCell.reuseIdentifier,
           let cell = tableView.dequeueReusableCell(withIdentifier: OARightIconTableViewCell.reuseIdentifier) as? OARightIconTableViewCell {
            cell.leftIconVisibility(false)
            cell.descriptionVisibility(false)
            cell.titleLabel.textColor = .textColorActive
            cell.rightIconView.tintColor = .iconColorActive
            cell.titleLabel.font = .preferredFont(forTextStyle: .headline)
            cell.titleLabel.text = item.title
            cell.rightIconView.image = UIImage.templateImageNamed(item.iconName)
            return cell
        }

        if item.cellType == OASimpleTableViewCell.reuseIdentifier,
           let cell = tableView.dequeueReusableCell(withIdentifier: OASimpleTableViewCell.reuseIdentifier) as? OASimpleTableViewCell {
            cell.titleLabel.numberOfLines = 3
            cell.titleLabel.lineBreakMode = .byTruncatingTail
            cell.titleLabel.text = item.title
            cell.descriptionLabel.text = item.descr
            cell.leftIconView.image = UIImage.templateImageNamed(item.iconName)
            cell.leftIconView.tintColor = (item.obj(forKey: ItemKey.color) as? UIColor) ?? .iconColorActive
            cell.accessoryType = item.bool(forKey: ItemKey.isSelected) ? .checkmark : .none
            return cell
        }

        return UITableViewCell()
    }

    override func onRowSelected(_ indexPath: IndexPath) {
        let item = tableData.item(for: indexPath)

        if item.key == RowKey.addNewGroup.rawValue {
            guard let groupEditor = OAFavoriteGroupEditorViewController(new: ()) else { return }
            groupEditor.delegate = self
            showModalViewController(groupEditor)
        } else if item.key == RowKey.group.rawValue {
            let selectedName = item.string(forKey: ItemKey.value) ?? item.title ?? ""
            if !item.bool(forKey: ItemKey.isSelected) {
                delegate?.onGroupSelected(selectedName)
            }
            dismiss(animated: true)
        }
    }

    private func addFavoriteGroupRows(to section: OATableSectionData) {
        let usesAllFavoriteGroups = favoriteGroupNames == nil
        let selectedName = selectedGroupName ?? ""
        let selectedDisplayName = OAFavoritesBridgeHelper.displayName(forFavoriteGroup: selectedName)
        let defaultGroupDisplayName = localizedString("favorites_item")

        if usesAllFavoriteGroups && !OAFavoritesBridgeHelper.hasFavoriteGroup("") {
            addGroupRow(
                to: section,
                title: defaultGroupDisplayName,
                description: "0",
                isSelected: defaultGroupDisplayName == selectedDisplayName,
                color: OADefaultFavorite.getDefaultColor()
            )
        }

        for groupName in favoriteGroupNames ?? OAFavoritesBridgeHelper.favoriteGroupNames() {
            let displayName = OAFavoritesBridgeHelper.displayName(forFavoriteGroup: groupName)
            addGroupRow(
                to: section,
                title: displayName,
                value: usesAllFavoriteGroups ? nil : groupName,
                description: String(OAFavoritesBridgeHelper.pointsCount(forFavoriteGroup: groupName)),
                isSelected: usesAllFavoriteGroups ? displayName == selectedDisplayName : groupName == selectedName,
                color: OAFavoritesBridgeHelper.color(forFavoriteGroup: groupName)
            )
        }
    }

    private func addGpxWptGroupRows(to section: OATableSectionData, groups: [[String: String]]) {
        for group in groups {
            let title = group[ItemKey.title] ?? ""
            addGroupRow(
                to: section,
                title: title,
                description: String(Int(group["count"] ?? "") ?? 0),
                isSelected: title == selectedGroupName,
                color: group[ItemKey.color].flatMap { UIColor(argb: Int(UIColor.toNumber(from: $0))) } ?? .iconColorActive
            )
        }
    }

    private func addGroupRow(to section: OATableSectionData,
                             title: String,
                             value: String? = nil,
                             description: String,
                             isSelected: Bool,
                             color: UIColor?) {
        let row = section.createNewRow()
        section.headerText = localizedString("available_groups")
        row.cellType = OASimpleTableViewCell.reuseIdentifier
        row.key = RowKey.group.rawValue
        row.title = title
        row.descr = description
        row.iconName = "ic_custom_folder"
        row.setObj(isSelected, forKey: ItemKey.isSelected)
        if let value {
            row.setObj(value, forKey: ItemKey.value)
        }
        if let color {
            row.setObj(color, forKey: ItemKey.color)
        }
    }
}

// MARK: - OAEditorDelegate
extension SelectFavoriteGroupViewController: OAEditorDelegate {
    func addNewItem(withName name: String?, iconName: String, color: UIColor, backgroundIconName: String) {
        dismiss(animated: true)
        delegate?.addNewGroup(withName: name ?? "", iconName: iconName, color: color, backgroundIconName: backgroundIconName)
    }

    func onEditorUpdated() {}

    func selectColorItem(_ colorItem: PaletteItemSolid) {
        delegate?.selectColorItem(colorItem)
    }

    @discardableResult
    func addAndGetNewColorItem(_ color: UIColor) -> PaletteItemSolid? {
        delegate?.addAndGetNewColorItem(color)
    }

    func changeColorItem(_ colorItem: PaletteItemSolid, with color: UIColor) {
        delegate?.changeColorItem(colorItem, with: color)
    }

    @discardableResult
    func duplicateColorItem(_ colorItem: PaletteItemSolid) -> PaletteItemSolid? {
        delegate?.duplicateColorItem(colorItem) ?? colorItem
    }

    func deleteColorItem(_ colorItem: PaletteItemSolid) {
        delegate?.deleteColorItem(colorItem)
    }
}
