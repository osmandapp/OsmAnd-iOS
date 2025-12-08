//
//  DeletedMapsViewController.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 26.11.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
final class DeletedMapsViewController: OABaseButtonsViewController {
    var region: OAWorldRegion?
    
    private let emptyStateHeaderView: IconEmptyStateView = {
        let emptyStateHeaderView: IconEmptyStateView = .init()
        emptyStateHeaderView.configure(image: .icCustomUpdateDisabled.withRenderingMode(.alwaysTemplate), tintColor: .iconColorDefault, description: localizedString("deleted_maps_prompt"))
        return emptyStateHeaderView
    }()
    
    private var downloadingCellResourceHelper: DownloadingCellResourceHelper?
    private var unsupportedMaps: [OAResourceSwiftItem] = []
    private var lastHeaderHeight: CGFloat = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupDownloadingCellResourceHelper()
        setupTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        generateDataAndReload()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if lastHeaderHeight == 0 {
            setupHeader()
        }
    }
    
    override func getTitle() -> String {
        localizedString("unsupported_maps")
    }
    
    override func getNavbarColorScheme() -> EOABaseNavbarColorScheme {
        .orange
    }
    
    override func getBottomAxisMode() -> NSLayoutConstraint.Axis {
        .vertical
    }
    
    override func getBottomButtonColorScheme() -> EOABaseButtonColorScheme {
        .purple
    }
    
    override func onBottomButtonPressed() {
        showDeleteAllAlert()
    }
    
    override func getBottomButtonTitle() -> String {
        localizedString("shared_string_delete_all")
    }
    
    override func getBottomColorScheme() -> EOABaseBottomColorScheme {
        .blank
    }
    
    override func useCustomTableViewHeader() -> Bool {
        true
    }
    
    override func isBottomSeparatorVisible() -> Bool {
        false
    }
    
    override func generateData() {
        tableData.clearAllData()
        fetchResources()
        
        if !unsupportedMaps.isEmpty {
            let unsupportedMapsSection = tableData.createNewSection()
            unsupportedMapsSection.headerText = localizedString("unsupported_maps")
            
            unsupportedMaps.forEach { _ in
                let unsupportedMapsRow = unsupportedMapsSection.createNewRow()
                unsupportedMapsRow.cellType = DownloadingCell.reuseIdentifier
            }
        }
    }
    
    override func getRow(_ indexPath: IndexPath) -> UITableViewCell? {
        let item = tableData.item(for: indexPath)
        var outCell: UITableViewCell?
        
        if item.cellType == DownloadingCell.reuseIdentifier {
            let mapItem = unsupportedMaps[indexPath.row]
            let title: String
            let description: String
            
            if mapItem.worldRegion() != nil && mapItem.worldRegion().subregions != nil {
                if let countryName = OAResourcesUISwiftHelper.getCountryName(mapItem), let mapTitle = mapItem.title() {
                    title = "\(countryName) - \(mapTitle)"
                } else {
                    title = mapItem.title()
                }
            } else {
                title = mapItem.title()
            }
            
            if let type = mapItem.type(), mapItem.sizePkg() > 0 {
                let date = mapItem.getDate()
                let dateDescription = date.flatMap { "  •  \($0)" } ?? ""
                description = "\(type)  •  \(ByteCountFormatter.string(fromByteCount: mapItem.sizePkg(), countStyle: .file))\(dateDescription)"
            } else {
                description = mapItem.type()
            }
            
            let cell = downloadingCellResourceHelper?.getOrCreateCell(mapItem.resourceId(), swiftResourceItem: mapItem)
            cell?.titleLabel.text = title
            cell?.descriptionLabel.text = description
            outCell = cell
        }
        
        return outCell ?? UITableViewCell()
    }
    
    override func onRowSelected(_ indexPath: IndexPath) {
        let item = tableData.item(for: indexPath)
        guard item.cellType == DownloadingCell.reuseIdentifier else { return }
        let mapItem = unsupportedMaps[indexPath.row]
        OAResourcesUISwiftHelper.showLocalResourceInformationViewController(mapItem, navigationController: navigationController)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    private func setupHeader() {
        let size = emptyStateHeaderView.systemLayoutSizeFitting(
            CGSize(width: tableView.bounds.width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )

        emptyStateHeaderView.frame.size.height = size.height
        lastHeaderHeight = emptyStateHeaderView.frame.size.height
        tableView.tableHeaderView = emptyStateHeaderView
    }
    
    private func setupDownloadingCellResourceHelper() {
        downloadingCellResourceHelper = DownloadingCellResourceHelper()
        downloadingCellResourceHelper?.setHostTableView(tableView)
        downloadingCellResourceHelper?.rightIconStyle = .showInfoAndShevronAfterDownloading
        downloadingCellResourceHelper?.isAlwaysClickable = true
    }
    
    private func generateDataAndReload() {
        generateData()
        tableView.reloadData()
    }
    
    private func showDeleteAllAlert() {
        guard !unsupportedMaps.isEmpty else { return }
        let alert = UIAlertController(title: localizedString("shared_string_delete_all"),
                                      message: String(format: localizedString("deleted_maps_alert_message"), unsupportedMaps.count),
                                      preferredStyle: .alert)

        let deleteAction = UIAlertAction(title: localizedString("shared_string_delete"), style: .destructive) { _ in
            OAResourcesUISwiftHelper.deleteResources(of: self.unsupportedMaps, progressHUD: nil, executeAfterSuccess: self.generateDataAndReload)
        }

        let cancelAction = UIAlertAction(title: localizedString("shared_string_cancel"), style: .default, handler: nil)

        alert.addAction(cancelAction)
        alert.addAction(deleteAction)
        alert.preferredAction = deleteAction

        present(alert, animated: true, completion: nil)
    }
    
    private func fetchResources() {
        guard let region else { return }
        unsupportedMaps = OAResourcesUISwiftHelper.getUnsupportedResources(with: region)
    }
}
