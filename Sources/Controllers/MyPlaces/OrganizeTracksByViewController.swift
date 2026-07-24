import UIKit
import OsmAndShared

protocol OrganizeTracksByDelegate: AnyObject {
    func onOrganizeByRangeParamsApplied(type: OrganizeByType, originalParams: OrganizeByParams?)
    func onOrganizeByParamsApplied()
}

final class OrganizeTracksByViewController: OABaseNavbarViewController {

    // MARK: - Private Types

    private enum RowKey: String {
        case none
        case type
    }

    private enum DataKey: String {
        case image
        case isSelected
        case isLocked
    }

    private struct RowData {
        let key: RowKey
        let title: String
        let image: UIImage?
        let type: OrganizeByType?
        let isSelected: Bool
        let isLocked: Bool
    }

    private struct SectionData {
        let headerText: String?
        let rows: [RowData]
    }

    // MARK: - Instance Properties

    weak var delegate: OrganizeTracksByDelegate?

    private let smartFolder: SmartFolder
    private var selectedType: OrganizeByType?

    // MARK: - Initializers

    init(smartFolder: SmartFolder) {
        self.smartFolder = smartFolder
        super.init()
        selectedType = smartFolder.getOrganizeByType()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = OrganizeByTypeCell.minHeight
        if let button = navigationItem.leftBarButtonItem?.customView as? UIButton {
            button.tintColor = .textColorPrimary
            button.accessibilityLabel = localizedString("shared_string_close")
        }
    }

    override func registerCells() {
        tableView.register(OrganizeByTypeCell.self, forCellReuseIdentifier: OrganizeByTypeCell.reuseIdentifier)
    }

    override func getTitle() -> String {
        localizedString("organize_by")
    }

    override func getTableHeaderDescription() -> String { "" }

    override func getTableHeaderDescriptionAttr() -> NSAttributedString? {
        let text = localizedString("organize_by_summary")
        return NSAttributedString(string: text, attributes: [
            .font: UIFont.preferredFont(forTextStyle: .body),
            .foregroundColor: UIColor.textColorSecondary
        ])
    }

    override func getCustomIconForLeftNavbarButton() -> UIImage? {
        .templateImageNamed("ic_navbar_close")
    }

    override func systemRightBarButtonItems() -> [UIBarButtonItem]? {
        return [UIBarButtonItem(title: localizedString("shared_string_apply"), style: .done, target: self, action: #selector(onApplyButtonPressed))]
    }

    override func generateData() {
        let proAvailable = OAIAPHelper.isOsmAndProAvailable()
        let sections = buildSections(proAvailable: proAvailable, selectedType: selectedType)
        populateTableData(sections)
    }

    override func getRow(_ indexPath: IndexPath?) -> UITableViewCell? {
        guard let indexPath else { return nil }
        let item = tableData.item(for: indexPath)

        guard let cell = tableView.dequeueReusableCell(withIdentifier: OrganizeByTypeCell.reuseIdentifier) as? OrganizeByTypeCell else { return nil }
        cell.configure(
            title: item.title,
            icon: item.obj(forKey: DataKey.image.rawValue) as? UIImage,
            isSelected: item.bool(forKey: DataKey.isSelected.rawValue),
            isLocked: item.bool(forKey: DataKey.isLocked.rawValue)
        )
        cell.onProBadgeTapped = { [weak self] in
            self?.openChoosePlan()
        }
        return cell
    }

    override func onRowSelected(_ indexPath: IndexPath) {
        let item = tableData.item(for: indexPath)

        if item.key == RowKey.none.rawValue {
            selectedType = nil
        } else {
            guard let type = item.obj(forKey: RowKey.type.rawValue) as? OrganizeByType else { return }
            selectedType = type
        }
        generateData()
        tableView.reloadData()
    }

    private func applyDirectly() {
        let params: OrganizeByParams? = selectedType.map { OrganizeByParams(type: $0) }
        SharedLibSmartFolderHelper.shared.setOrganizeByParams(folderId: smartFolder.getId(), params: params)
        smartFolder.setOrganizeByParams(organizeByParams: params)
        delegate?.onOrganizeByParamsApplied()
        dismiss(animated: true)
    }

    private func applyAndOpenStepSize(type: OrganizeByType) {
        let originalParams = smartFolder.organizeByParams
        let stepSize: Double
        if let existingRange = originalParams as? OrganizeByRangeParams, existingRange.type == type {
            stepSize = existingRange.stepSize
        } else {
            stepSize = type.getDefaultStepInBaseUnits()
        }
        let params = OrganizeByRangeParams(type: type, stepSize: stepSize)
        SharedLibSmartFolderHelper.shared.setOrganizeByParams(folderId: smartFolder.getId(), params: params)
        smartFolder.setOrganizeByParams(organizeByParams: params)
        dismiss(animated: true) { [weak self] in
            guard let self else { return }
            self.delegate?.onOrganizeByRangeParamsApplied(type: type, originalParams: originalParams)
        }
    }

    private func openChoosePlan() {
        guard let navigationController else { return }
        OAChoosePlanHelper.showChoosePlanScreen(with: OAFeature.advanced_WIDGETS(), navController: navigationController)
    }

    private func buildSections(proAvailable: Bool, selectedType: OrganizeByType?) -> [SectionData] {
        var sections: [SectionData] = []

        let noneRow = RowData(
            key: .none,
            title: localizedString("shared_string_none"),
            image: .icCustomList,
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
                    key: .type,
                    title: type.getName(),
                    image: type.image,
                    type: type,
                    isSelected: selectedType == type,
                    isLocked: type.isLockedBehindPro && !proAvailable
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
                row.cellType = OrganizeByTypeCell.reuseIdentifier
                row.key = rowData.key.rawValue
                row.title = rowData.title
                row.setObj(rowData.image as Any, forKey: DataKey.image.rawValue)
                if let type = rowData.type {
                    row.setObj(type, forKey: RowKey.type.rawValue)
                }
                row.setObj(rowData.isSelected, forKey: DataKey.isSelected.rawValue)
                row.setObj(rowData.isLocked, forKey: DataKey.isLocked.rawValue)
            }
        }
    }

    @objc private func onApplyButtonPressed() {
        guard let type = selectedType else {
            applyDirectly()
            return
        }
        if type.isRangeRelated() {
            applyAndOpenStepSize(type: type)
            return
        }
        if type.isLockedBehindPro, !OAIAPHelper.isOsmAndProAvailable() {
            openChoosePlan()
            return
        }
        applyDirectly()
    }
}
