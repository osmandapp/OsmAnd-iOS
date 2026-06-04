//
//  MultipleValuesViewController.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 04.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

struct MultipleValuesConfiguration {
    let title: String
    let values: [String]
    let onSelect: (String) -> Void
    var lineBreakMode: NSLineBreakMode = .byTruncatingTail
}

@objcMembers
final class MultipleValuesViewController: OABaseNavbarViewController {
    
    private let configuration: MultipleValuesConfiguration
    private let linkKey = "linkKey"
    
    init(configuration: MultipleValuesConfiguration) {
        self.configuration = configuration
        super.init()
    }
    
    @objc init(title: String, values: [String], lineBreakMode: NSLineBreakMode, onSelect: @escaping (String) -> Void) {
        self.configuration = MultipleValuesConfiguration(title: title, values: values, onSelect: onSelect, lineBreakMode: lineBreakMode)
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureSheet()
    }
    
    override func getTitle() -> String {
        configuration.title
    }
    
    override func tableStyle() -> UITableView.Style {
        .insetGrouped
    }
    
    override func registerCells() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: UITableViewCell.reuseIdentifier)
    }
    
    override func getRow(_ indexPath: IndexPath) -> UITableViewCell? {
        let item = tableData.item(for: indexPath)
        
        var contentConfiguration = UIListContentConfiguration.cell()
        
        contentConfiguration.text = item.title
        contentConfiguration.textProperties.color = .textColorActive
        contentConfiguration.textProperties.font = .preferredFont(forTextStyle: .body)
        contentConfiguration.textProperties.numberOfLines = 1
        contentConfiguration.textProperties.lineBreakMode = configuration.lineBreakMode
        
        let cell = tableView.dequeueReusableCell(withIdentifier: UITableViewCell.reuseIdentifier, for: indexPath)
        cell.contentConfiguration = contentConfiguration
        cell.accessibilityLabel = item.title
        
        return cell
    }
    
    override func onRowSelected(_ indexPath: IndexPath) {
        let item = tableData.item(for: indexPath)
        guard let value = item.obj(forKey: linkKey) as? String else { return }
        
        configuration.onSelect(value)
    }
    
    override func generateData() {
        tableData.clearAllData()
        let section = tableData.createNewSection()
        
        configuration.values.forEach {
            let linkRow = section.createNewRow()
            linkRow.title = $0
            linkRow.setObj($0, forKey: linkKey)
        }
    }
    
    override func systemLeftBarButtonItem() -> UIBarButtonItem {
        UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(closePressed))
    }
    
    private func configureSheet() {
        guard let sheet = sheetPresentationController else { return }
        sheet.detents = [.medium(), .large()]
        sheet.prefersGrabberVisible = true
        sheet.preferredCornerRadius = 20
    }
    
    @objc private func closePressed() {
        dismiss(animated: true)
    }
}
