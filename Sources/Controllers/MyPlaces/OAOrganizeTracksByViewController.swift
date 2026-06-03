import UIKit
import OsmAndShared

protocol OAOrganizeTracksByDelegate: AnyObject {
    func onOrganizeByRangeParamsApplied(type: OrganizeByType)
    func onOrganizeByParamsApplied()
}

final class OAOrganizeTracksByViewController: OABaseNavbarViewController {

    // MARK: - Private Types

    private enum RowKey: String {
        case none
        case type
    }

    private enum DataKey: String {
        case type
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
        config.baseBackgroundColor = .systemBlue
        config.baseForegroundColor = .white
        config.cornerStyle = .capsule
        let button = UIButton(configuration: config)
        button.addTarget(self, action: #selector(onApplyButtonPressed), for: .touchUpInside)
        button.sizeToFit()
        return [UIBarButtonItem(customView: button)]
    }

    override func generateData() {
        tableData.clearAllData()
        guard !isInitialLoad else { return }

        let noneSection = tableData.createNewSection()
        let noneRow = noneSection.createNewRow()
        noneRow.cellType = OAOrganizeByTypeCell.cellReuseIdentifier
        noneRow.key = RowKey.none.rawValue
        noneRow.title = localizedString("shared_string_none")
        noneRow.setObj(UIImage.templateImageNamed("ic_custom_list") as Any, forKey: DataKey.type.rawValue)
        noneRow.setObj(selectedType == nil, forKey: DataKey.isSelected.rawValue)

        let proAvailable = OAIAPHelper.isOsmAndProAvailable()
        for category in OrganizeByCategory.entries {
            let types = OrganizeByType.companion.valuesOf(category: category)
            guard !types.isEmpty else { continue }
            let section = tableData.createNewSection()
            section.headerText = category.getName()
            for type in types {
                let row = section.createNewRow()
                row.cellType = OAOrganizeByTypeCell.cellReuseIdentifier
                row.key = RowKey.type.rawValue
                row.title = type.getName()
                row.setObj(type.image as Any, forKey: DataKey.type.rawValue)
                row.setObj(type, forKey: RowKey.type.rawValue)
                row.setObj(selectedType == type, forKey: DataKey.isSelected.rawValue)
                row.setObj(type.isPro && !proAvailable, forKey: DataKey.isLocked.rawValue)
            }
        }
    }

    override func getRow(_ indexPath: IndexPath?) -> UITableViewCell? {
        guard let indexPath else { return nil }
        let item = tableData.item(for: indexPath)

        guard let cell = tableView.dequeueReusableCell(withIdentifier: OAOrganizeByTypeCell.cellReuseIdentifier) as? OAOrganizeByTypeCell else { return nil }
        cell.configure(
            title: item.title,
            icon: item.obj(forKey: DataKey.type.rawValue) as? UIImage,
            isSelected: item.bool(forKey: DataKey.isSelected.rawValue),
            isLocked: item.bool(forKey: DataKey.isLocked.rawValue)
        )
        return cell
    }

    override func onRowSelected(_ indexPath: IndexPath) {
        let item = tableData.item(for: indexPath)

        if item.key == RowKey.none.rawValue {
            selectedType = nil
            generateData()
            tableView.reloadData()
            return
        }

        guard let type = item.obj(forKey: RowKey.type.rawValue) as? OrganizeByType else { return }
        if item.bool(forKey: DataKey.isLocked.rawValue) {
            openChoosePlan()
            return
        }
        selectedType = type
        generateData()
        tableView.reloadData()
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
        let existingParams = smartFolder.organizeByParams as? OrganizeByRangeParams
        let stepSize = existingParams?.stepSize ?? type.getDefaultStepInBaseUnits()
        let params = OrganizeByRangeParams(type: type, stepSize: stepSize)
        SharedLibSmartFolderHelper.shared.setOrganizeByParams(folderId: smartFolder.getId(), params: params)
        dismiss(animated: true) { [weak self] in
            self?.delegate?.onOrganizeByRangeParamsApplied(type: type)
        }
    }

    private func prefetchDataInBackground() {
        let folder = smartFolder
        let proAvailable = OAIAPHelper.isOsmAndProAvailable()
        DispatchQueue.global(qos: .default).async { [weak self] in
            guard let self else { return }
            let currentType = folder.getOrganizeByType()
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
            key: .none,
            title: localizedString("shared_string_none"),
            image: .templateImageNamed("ic_custom_list"),
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
                row.key = rowData.key.rawValue
                row.title = rowData.title
                row.setObj(rowData.image as Any, forKey: DataKey.type.rawValue)
                if let type = rowData.type {
                    row.setObj(type, forKey: RowKey.type.rawValue)
                }
                row.setObj(rowData.isSelected, forKey: DataKey.isSelected.rawValue)
                row.setObj(rowData.isLocked, forKey: DataKey.isLocked.rawValue)
            }
        }
    }

    @objc private func onApplyButtonPressed() {
        guard let type = selectedType, type.isRangeRelated() else {
            applyDirectly()
            return
        }
        applyAndOpenStepSize()
    }
}
