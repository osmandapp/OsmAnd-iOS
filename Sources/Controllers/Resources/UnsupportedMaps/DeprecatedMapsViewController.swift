//
//  DeprecatedMapsViewController.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 26.11.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
final class DeprecatedMapsViewController: OASuperViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var deleteAllButton: UIButton!
    
    var region: OAWorldRegion?
    
    private let emptyStateHeaderView: IconEmptyStateView = {
        let emptyStateHeaderView: IconEmptyStateView = .init()
        emptyStateHeaderView.configure(image: .icCustomUpdateDisabled.withRenderingMode(.alwaysTemplate), tintColor: .iconColorDefault, description: localizedString("deleted_maps_prompt"))
        emptyStateHeaderView.layoutSubviews()
        return emptyStateHeaderView
    }()
    private let deleteAllButtonCornerRadius: CGFloat = 10
    private let titleFontSize: CGFloat = 15
    private let unsupportedMapsHeaderHeight: CGFloat = 35
    
    private var tableData = OATableDataModel()
    private var downloadingCellResourceHelper: DownloadingCellResourceHelper?
    private var unsupportedMaps: [OAResourceSwiftItem] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupDownloadingCellResourceHelper()
        setupTableView()
        setupBottomButton()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavbar()
        generateData()
        tableView.reloadData()
    }
    
    private func setupNavbar() {
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationItem.title = localizedString("unsupported_maps")
        navigationController?.navigationBar.topItem?.setRightBarButton(nil, animated: false)
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .navBarBgColorPrimary
        appearance.shadowColor = .navBarBgColorPrimary
        appearance.titleTextAttributes = [
            .font: UIFont.preferredFont(forTextStyle: .headline),
            .foregroundColor: UIColor.navBarTextColorPrimary as Any
        ]

        let blurAppearance = UINavigationBarAppearance()
        blurAppearance.backgroundEffect = UIBlurEffect(style: .regular)
        blurAppearance.backgroundColor = .navBarBgColorPrimary
        blurAppearance.titleTextAttributes = [
            .font: UIFont.preferredFont(forTextStyle: .headline),
            .foregroundColor: UIColor.navBarTextColorPrimary as Any
        ]

        navigationController?.navigationBar.standardAppearance = blurAppearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = .navBarTextColorPrimary
        navigationController?.navigationBar.prefersLargeTitles = false
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    private func setupDownloadingCellResourceHelper() {
        downloadingCellResourceHelper = DownloadingCellResourceHelper();
        downloadingCellResourceHelper?.setHostTableView(tableView)
        downloadingCellResourceHelper?.rightIconStyle = .showInfoAndShevronAfterDownloading
        downloadingCellResourceHelper?.isAlwaysClickable = true
    }
    
    private func generateData() {
        tableData.clearAllData()
        
        fetchResources()
        
        tableData.createNewSection()
        
        if !unsupportedMaps.isEmpty {
            let unsupportedMapsSection = tableData.createNewSection()
            unsupportedMapsSection.headerText = localizedString("unsupported_maps")
            
            for _ in unsupportedMaps {
                let unsupportedMapsRow = unsupportedMapsSection.createNewRow()
                unsupportedMapsRow.cellType = DownloadingCell.reuseIdentifier
            }
        }
    }
    
    private func setupBottomButton() {
        deleteAllButton.setTitle(localizedString("shared_string_delete_all"), for: .normal)
        deleteAllButton.addTarget(self, action: #selector(onDeleteAllButtonPressed), for: .touchUpInside)
        deleteAllButton.backgroundColor = .buttonBgColorPrimary
        deleteAllButton.setTitleColor(.buttonTextColorPrimary, for: .normal)
        deleteAllButton.titleLabel?.font = .systemFont(ofSize: titleFontSize, weight: .semibold)
        deleteAllButton.layer.cornerRadius = deleteAllButtonCornerRadius
    }
    
    private func showDeleteAllAlert() {
        guard !unsupportedMaps.isEmpty else { return }
        let alert = UIAlertController(title: localizedString("shared_string_delete_all"),
                                      message: String(format: localizedString("deleted_maps_alert_message"), unsupportedMaps.count),
                                      preferredStyle: .alert)

        let deleteAction = UIAlertAction(title: localizedString("shared_string_delete"), style: .destructive) { _ in
            OAResourcesUISwiftHelper.deleteResources(of: self.unsupportedMaps, progressHUD: nil) { [weak self] in
                self?.generateData()
                self?.tableView.reloadData()
            }
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
    
    @objc private func onDeleteAllButtonPressed() {
        showDeleteAllAlert()
    }
    
    // MARK: - TableView
    
    func numberOfSections(in tableView: UITableView) -> Int {
        Int(tableData.sectionCount())
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        Int(tableData.rowCount(UInt(section)))
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        tableData.sectionCount() > 0 ? tableData.sectionData(for: UInt(section)).headerText : nil
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        section == 1 ? unsupportedMapsHeaderHeight : UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        section == 0 ? emptyStateHeaderView : nil
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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
            }
            else {
                title = mapItem.title()
            }
            
            if let type = mapItem.type(), mapItem.sizePkg() > 0 {
                let date = mapItem.getDate()
                let dateDescription = date != nil ? "  •  \(date!)" : ""
                description = "\(type)  •  \(ByteCountFormatter.string(fromByteCount: mapItem.sizePkg(), countStyle: .file))\(dateDescription)"
            }
            else {
                description = mapItem.type();
            }
            
            let cell = downloadingCellResourceHelper?.getOrCreateCell(mapItem.resourceId(), swiftResourceItem: mapItem)
            cell?.titleLabel.text = title;
            cell?.descriptionLabel.text = description;
            outCell = cell
        }
        
        return outCell ?? UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = tableData.item(for: indexPath)
        guard item.cellType == DownloadingCell.reuseIdentifier else { return }
        let mapItem = unsupportedMaps[indexPath.row]
        OAResourcesUISwiftHelper.showLocalResourceInformationViewController(mapItem, navigationController: navigationController)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
