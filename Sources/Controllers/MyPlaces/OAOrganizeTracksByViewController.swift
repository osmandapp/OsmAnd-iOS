import UIKit
import OsmAndShared

protocol OAOrganizeTracksByDelegate: AnyObject {
    func onOrganizeByParamsApplied()
}

final class OAOrganizeTracksByViewController: OABaseNavbarViewController {

    // MARK: - Type Properties

    private static let noneCellKey = "none"
    private static let typeCellKey = "type"
    private static let isSelectedKey = "isSelected"
    private static let isLockedKey = "isLocked"

    // MARK: - Private Types

    private struct RowData {
        let key: String
        let title: String
        let iconName: String
        let type: OrganizeByType?
        let isSelected: Bool
        let isLocked: Bool
    }

    private struct SectionData {
        let headerText: String?
        let rows: [RowData]
    }

    // MARK: - Instance Properties

    private let smartFolder: SmartFolder

    weak var delegate: OAOrganizeTracksByDelegate?

    private var selectedType: OrganizeByType?
    private var isInitialLoad = true
    private var prefetchedSections: [SectionData]?
    private var prefetchedType: OrganizeByType?

    // MARK: - Initializers

    init(smartFolder: SmartFolder) {
        self.smartFolder = smartFolder
        super.init()
        prefetchDataInBackground()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = OAOrganizeByTypeCell.minHeight
        if let button = navigationItem.leftBarButtonItem?.customView as? UIButton {
            button.tintColor = .textColorPrimary
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard isInitialLoad else { return }
        isInitialLoad = false
        if let sections = prefetchedSections {
            applyLoadedData(type: prefetchedType, sections: sections)
        }
    }

    override func registerCells() {
        tableView.register(OAOrganizeByTypeCell.self, forCellReuseIdentifier: OAOrganizeByTypeCell.cellReuseIdentifier)
    }

    override func getTitle() -> String {
        localizedString("organize_by")
    }

    override func getTableHeaderDescriptionAttr() -> NSAttributedString {
        NSAttributedString(
            string: localizedString("organize_by_summary"),
            attributes: [
                .font: UIFont.systemFont(ofSize: 16, weight: .regular),
                .foregroundColor: UIColor.textColorSecondary as Any
            ]
        )
    }

    override func getCustomIconForLeftNavbarButton() -> UIImage? {
        .templateImageNamed("ic_navbar_close")
    }

    override func tableStyle() -> UITableView.Style {
        .insetGrouped
    }

    override func getRightNavbarButtons() -> [UIBarButtonItem] {
        var config = UIButton.Configuration.filled()
        config.title = localizedString("shared_string_apply")
        config.baseBackgroundColor = .menuButton
        config.baseForegroundColor = .white
        config.cornerStyle = .capsule
        config.background.strokeColor = .clear
        config.background.strokeWidth = 0
        let button = UIButton(configuration: config)
        button.addTarget(self, action: #selector(onApplyButtonPressed), for: .touchUpInside)
        return [UIBarButtonItem(customView: button)]
    }

    override func generateData() {
        tableData.clearAllData()
        guard !isInitialLoad else { return }

        let noneSection = tableData.createNewSection()
        let noneRow = noneSection.createNewRow()
        noneRow.cellType = OAOrganizeByTypeCell.cellReuseIdentifier
        noneRow.key = Self.noneCellKey
        noneRow.title = localizedString("shared_string_none")
        noneRow.iconName = "ic_custom_list"
        noneRow.setObj(selectedType == nil, forKey: Self.isSelectedKey)

        let proAvailable = OAIAPHelper.isOsmAndProAvailable()
        for category in OrganizeByCategory.entries {
            let types = OrganizeByType.companion.valuesOf(category: category)
            guard !types.isEmpty else { continue }
            let section = tableData.createNewSection()
            section.headerText = category.getName()
            for type in types {
                let row = section.createNewRow()
                row.cellType = OAOrganizeByTypeCell.cellReuseIdentifier
                row.key = Self.typeCellKey
                row.title = type.getName()
                row.iconName = type.iosIconName
                row.setObj(type, forKey: Self.typeCellKey)
                row.setObj(selectedType == type, forKey: Self.isSelectedKey)
                row.setObj(type.isPro && !proAvailable, forKey: Self.isLockedKey)
            }
        }
    }

    override func getRow(_ indexPath: IndexPath?) -> UITableViewCell? {
        guard let indexPath else { return nil }
        let item = tableData.item(for: indexPath)

        guard let cell = tableView.dequeueReusableCell(withIdentifier: OAOrganizeByTypeCell.cellReuseIdentifier) as? OAOrganizeByTypeCell else { return nil }
        cell.configure(
            title: item.title,
            iconName: item.iconName,
            isSelected: item.bool(forKey: Self.isSelectedKey),
            isLocked: item.bool(forKey: Self.isLockedKey)
        )
        return cell
    }

    override func onRowSelected(_ indexPath: IndexPath) {
        let item = tableData.item(for: indexPath)

        if item.key == Self.noneCellKey {
            selectedType = nil
            generateData()
            tableView.reloadData()
            return
        }

        guard let type = item.obj(forKey: Self.typeCellKey) as? OrganizeByType else { return }
        if item.bool(forKey: Self.isLockedKey) {
            openChoosePlan()
            return
        }
        selectedType = type
        generateData()
        tableView.reloadData()
    }

    @objc private func onApplyButtonPressed() {
        guard let type = selectedType, type.isRangeRelated() else {
            applyDirectly()
            return
        }
        applyAndOpenStepSize()
    }

    private func applyDirectly() {
        let params: OrganizeByParams? = selectedType.map { OrganizeByParams(type: $0) }
        SharedLibSmartFolderHelper.shared.setOrganizeByParams(folderId: smartFolder.getId(), params: params)
        dismiss(animated: true) { [weak self] in
            self?.delegate?.onOrganizeByParamsApplied()
        }
    }

    private func applyAndOpenStepSize() {
        guard let type = selectedType else {
            applyDirectly()
            return
        }
        let params = OrganizeByRangeParams(type: type, stepSize: type.getDefaultStepInBaseUnits())
        SharedLibSmartFolderHelper.shared.setOrganizeByParams(folderId: smartFolder.getId(), params: params)
        dismiss(animated: true) { [weak self] in
            self?.delegate?.onOrganizeByParamsApplied()
        }
    }

    private func prefetchDataInBackground() {
        let folder = smartFolder
        let proAvailable = OAIAPHelper.isOsmAndProAvailable()
        DispatchQueue.global(qos: .default).async { [weak self] in
            guard let self else { return }
            let currentType = folder.getOrganizeByType()
            _ = OrganizeByCategory.entries
            let sections = self.buildSections(proAvailable: proAvailable, selectedType: currentType)
            DispatchQueue.main.async {
                self.prefetchedType = currentType
                self.prefetchedSections = sections
                if !self.isInitialLoad {
                    self.applyLoadedData(type: currentType, sections: sections)
                }
            }
        }
    }

    private func applyLoadedData(type: OrganizeByType?, sections: [SectionData]) {
        selectedType = type
        populateTableData(sections)
        tableView.reloadData()
    }

    private func openChoosePlan() {
        guard let navigationController else { return }
        OAChoosePlanHelper.showChoosePlanScreen(with: OAFeature.advanced_WIDGETS(), navController: navigationController)
    }

    private func buildSections(proAvailable: Bool, selectedType: OrganizeByType?) -> [SectionData] {
        var sections: [SectionData] = []

        let noneRow = RowData(
            key: Self.noneCellKey,
            title: localizedString("shared_string_none"),
            iconName: "ic_custom_list",
            type: nil,
            isSelected: selectedType == nil,
            isLocked: false
        )
        sections.append(SectionData(headerText: nil, rows: [noneRow]))

        for category in OrganizeByCategory.entries {
            let types = OrganizeByType.companion.valuesOf(category: category)
            guard !types.isEmpty else { continue }
            var rows: [RowData] = []
            for type in types {
                rows.append(RowData(
                    key: Self.typeCellKey,
                    title: type.getName(),
                    iconName: type.iosIconName,
                    type: type,
                    isSelected: selectedType == type,
                    isLocked: type.isPro && !proAvailable
                ))
            }
            sections.append(SectionData(headerText: category.getName(), rows: rows))
        }

        return sections
    }

    private func populateTableData(_ sections: [SectionData]) {
        tableData.clearAllData()
        for sectionData in sections {
            let section = tableData.createNewSection()
            section.headerText = sectionData.headerText ?? ""
            for rowData in sectionData.rows {
                let row = section.createNewRow()
                row.cellType = OAOrganizeByTypeCell.cellReuseIdentifier
                row.key = rowData.key
                row.title = rowData.title
                row.iconName = rowData.iconName
                if let type = rowData.type {
                    row.setObj(type, forKey: Self.typeCellKey)
                }
                row.setObj(rowData.isSelected, forKey: Self.isSelectedKey)
                row.setObj(rowData.isLocked, forKey: Self.isLockedKey)
            }
        }
    }
}
