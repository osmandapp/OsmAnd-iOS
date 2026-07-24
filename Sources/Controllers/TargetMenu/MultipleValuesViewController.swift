//
//  MultipleValuesViewController.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 04.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

enum MultipleValueKind {
    case generic
    case url
    case phone
}

struct MultipleValuesConfiguration {
    let title: String
    let values: [String]
    let onSelect: (String) -> Void
    var valueKind: MultipleValueKind = .generic
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

    @objc init(title: String, urls: [String], onSelect: @escaping (String) -> Void) {
        self.configuration = MultipleValuesConfiguration(title: title, values: urls, onSelect: onSelect, valueKind: .url, lineBreakMode: .byTruncatingMiddle)
        super.init()
    }

    @objc init(title: String, phones: [String], lineBreakMode: NSLineBreakMode, onSelect: @escaping (String) -> Void) {
        self.configuration = MultipleValuesConfiguration(title: title, values: phones, onSelect: onSelect, valueKind: .phone, lineBreakMode: lineBreakMode)
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
    
    override func systemLeftBarButtonItem() -> UIBarButtonItem {
        UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(closePressed))
    }
    
    override func registerCells() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: UITableViewCell.reuseIdentifier)
    }
    
    override func getRow(_ indexPath: IndexPath) -> UITableViewCell? {
        let item = tableData.item(for: indexPath)
        let title = item.title ?? ""
        
        var contentConfiguration = UIListContentConfiguration.cell()
        
        contentConfiguration.text = title
        contentConfiguration.textProperties.color = .textColorActive
        contentConfiguration.textProperties.font = .preferredFont(forTextStyle: .body)
        contentConfiguration.textProperties.adjustsFontForContentSizeCategory = true
        contentConfiguration.textProperties.numberOfLines = 1
        contentConfiguration.textProperties.lineBreakMode = configuration.lineBreakMode
        
        let cell = tableView.dequeueReusableCell(withIdentifier: UITableViewCell.reuseIdentifier, for: indexPath)
        cell.contentConfiguration = contentConfiguration
        cell.accessibilityTraits = .none
        cell.accessibilityLabel = accessibilityLabel(for: title)
        cell.accessibilityTraits = valueAccessibilityTraits
        
        return cell
    }

    override func onRowSelected(_ indexPath: IndexPath) {
        let item = tableData.item(for: indexPath)
        guard let value = item.obj(forKey: linkKey) as? String else { return }

        let onSelect = configuration.onSelect
        dismiss(animated: true) {
            onSelect(value)
        }
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

// MARK: - Accessibility
extension MultipleValuesViewController {

    private var valueAccessibilityTraits: UIAccessibilityTraits {
        switch configuration.valueKind {
        case .url:
            .link
        case .generic, .phone:
            .button
        }
    }

    private func accessibilityLabel(for value: String) -> String {
        switch configuration.valueKind {
        case .generic:
            value
        case .url:
            urlAccessibilityValue(from: value)
        case .phone:
            phoneAccessibilityValue(from: value)
        }
    }

    private func urlAccessibilityValue(from value: String) -> String {
        guard let url = URL(string: value) else { return value }

        var result = url.host ?? value
        if !url.path.isEmpty, url.path != "/" {
            result += url.path
        }

        return result
    }

    private func phoneAccessibilityValue(from value: String) -> String {
        value
            .filter { $0.isNumber || $0 == "+" }
            .map(String.init)
            .joined(separator: " ")
    }
}
