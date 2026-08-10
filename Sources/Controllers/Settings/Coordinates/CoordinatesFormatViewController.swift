//
//  CoordinatesFormatViewController.swift
//  OsmAnd Maps
//
//  Created by Vitaliy Sova on 07.08.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

@objcMembers
final class CoordinatesFormatViewController: OABaseSettingsViewController {

    private static let formatIdKey = "formatId"
    private static let exampleLat = 50.43855
    private static let exampleLon = 30.50124
    
    private let toolbarView = UIView()
    
    private var formatStorage: CoordinateFormatSettingsStorage {
        OAAppSettings.sharedManager().coordinateFormatSettingsStorage
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        makeToolbar()
        tableView.sectionHeaderTopPadding = 0
        generateData()
        tableView.reloadData()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateTableBottomInset()
        relayoutTableHeaderViewIfNeeded()
    }
    
    override func registerCells() {
        addCell(OASimpleTableViewCell.reuseIdentifier)
    }

    override func getTitle() -> String? {
        localizedString("coordinates_format")
    }
    
    override func getSubtitle() -> String? {
        nil
    }

    override func getLeftNavbarButtonTitle() -> String? {
        nil
    }

    override func getRightNavbarButtons() -> [UIBarButtonItem] {
        let copyAction = UIAction(
            title: localizedString("copy_from_other_profile"),
            image: .icCustomCopy
        ) { [weak self] _ in
            self?.onCopyFromAnotherProfile()
        }
        let resetAction = UIAction(
            title: localizedString("reset_to_default"),
            image: .icCustomReset
        ) { [weak self] _ in
            self?.onResetToDefault()
        }
        let menu = UIMenu(children: [copyAction, resetAction])
        guard let button = Self.createRightNavbarButton(
            nil,
            icon: .icCustomOverflowMenuStroke,
            color: .label,
            action: nil,
            target: self,
            menu: menu
        ) else { return [] }
        
        button.accessibilityLabel = localizedString("shared_string_options")
        
        return [button]
    }
    
    override func setupTableHeaderView() {
        let text = localizedString("coordinate_format_description")
        let attr = NSAttributedString(
            string: text,
            attributes: [
                .font: UIFont.preferredFont(forTextStyle: .footnote),
                .foregroundColor: UIColor.textColorSecondary
            ]
        )

        let width = view.bounds.width
        let horizontalInset: CGFloat = 36 + OAUtilities.getLeftMargin()
        let top: CGFloat = 12
        let bottom: CGFloat = 8
        let textWidth = max(0, width - horizontalInset * 2)
        let textHeight = OAUtilities.calculateTextBounds(attr, width: textWidth).height

        let header = UIView(frame: CGRect(x: 0, y: 0, width: width, height: top + textHeight + bottom))
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.attributedText = attr
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.textAlignment = .natural
        label.adjustsFontForContentSizeCategory = true
        header.addSubview(label)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: horizontalInset),
            label.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -horizontalInset),
            label.topAnchor.constraint(equalTo: header.topAnchor, constant: top),
            label.bottomAnchor.constraint(equalTo: header.bottomAnchor, constant: -bottom)
        ])

        tableView.tableHeaderView = header
    }
    
    override func hideFirstHeader() -> Bool {
        true
    }

    override func generateData() {
        tableData.clearAllData()

        let section = tableData.createNewSection()

        let formats = resolveFormats(formatStorage.preferredIds(appMode))
        for (index, format) in formats.enumerated() {
            let row = section.createNewRow()
            row.cellType = OASimpleTableViewCell.reuseIdentifier
            row.title = format.title
            row.descr = formatSummary(format, primary: index == 0)
            row.setObj(format.id, forKey: Self.formatIdKey)
        }
    }

    override func getRow(_ indexPath: IndexPath?) -> UITableViewCell? {
        guard let indexPath else { return nil }
        let item = tableData.item(for: indexPath)
        guard item.cellType == OASimpleTableViewCell.reuseIdentifier,
              let cell = tableView.dequeueReusableCell(
                withIdentifier: OASimpleTableViewCell.reuseIdentifier,
                for: indexPath
              ) as? OASimpleTableViewCell else { return nil }

        cell.selectionStyle = .none
        cell.accessoryType = .none
        cell.leftIconVisibility(false)
        cell.descriptionVisibility(!(item.descr ?? "").isEmpty)
        cell.titleLabel.text = item.title
        cell.descriptionLabel.text = item.descr
        cell.descriptionLabel.font = .preferredFont(forTextStyle: .subheadline)
        
        cell.isAccessibilityElement = true
        cell.accessibilityLabel = item.title
        cell.accessibilityValue = item.descr
        cell.accessibilityTraits = .staticText
        cell.accessibilityHint = nil

        cell.setCustomLeftSeparatorInset(true)
        cell.separatorInset = UIEdgeInsets(top: 0,
                                           left: 16,
                                           bottom: 0,
                                           right: 16)
        
        return cell
    }

    override func getTopButtonTitle() -> String {
        ""
    }

    override func getBottomButtonTitle() -> String {
        ""
    }
    
    // MARK: - Layout
    
    private func updateTableBottomInset() {
        let bottom = toolbarView.bounds.height
        guard tableView.contentInset.bottom != bottom else { return }
        var inset = tableView.contentInset
        inset.bottom = bottom
        tableView.contentInset = inset
        tableView.verticalScrollIndicatorInsets.bottom = bottom
    }
    
    private func relayoutTableHeaderViewIfNeeded() {
        guard let header = tableView.tableHeaderView else { return }
        let width = tableView.bounds.width
        let target = CGSize(width: width, height: UIView.layoutFittingCompressedSize.height)
        let height = header.systemLayoutSizeFitting(
            target,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height
        guard abs(header.frame.height - height) > 0.5 || abs(header.frame.width - width) > 0.5 else { return }
        header.frame.size = CGSize(width: width, height: height)
        tableView.tableHeaderView = header
    }
    
    // MARK: - Toolbar
    
    private func makeToolbar() {
        toolbarView.translatesAutoresizingMaskIntoConstraints = false

        let addButton = makeToolbarButton(localizedString("shared_string_add"))
        addButton.addTarget(self, action: #selector(onAddAction), for: .touchUpInside)
        let editButton = makeToolbarButton(localizedString("shared_string_edit"))
        editButton.addTarget(self, action: #selector(onEditAction), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [editButton, addButton])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.distribution = .equalSpacing
        stack.alignment = .center

        view.addSubview(toolbarView)
        toolbarView.addSubview(stack)

        NSLayoutConstraint.activate([
            toolbarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbarView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            toolbarView.heightAnchor.constraint(greaterThanOrEqualToConstant: 84),

            stack.leadingAnchor.constraint(equalTo: toolbarView.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: toolbarView.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            stack.topAnchor.constraint(equalTo: toolbarView.safeAreaLayoutGuide.topAnchor, constant: 4),
            stack.bottomAnchor.constraint(equalTo: toolbarView.safeAreaLayoutGuide.bottomAnchor, constant: -4)
        ])
    }
    
    private func makeToolbarButton(_ title: String) -> UIButton {
        var config: UIButton.Configuration
        if #available(iOS 26.0, *) {
            config = .glass()
        } else {
            config = UIButton.Configuration.plain()
        }
        
        config.title = title
        config.contentInsets = .init(top: 11, leading: 12, bottom: 11, trailing: 12)
        config.cornerStyle = .capsule
        config.titleTextAttributesTransformer = .init { attributes in
            var attributes = attributes
            attributes.font = .preferredFont(forTextStyle: .body)
            attributes.foregroundColor = .textColorPrimary
            return attributes
        }
        
        let button = UIButton(configuration: config)
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        
        if #available(iOS 26.0, *) {
            return button
        } else {
            let blur = UIVisualEffectView(
                effect: UIBlurEffect(style: .systemUltraThinMaterial)
            )
            blur.isUserInteractionEnabled = false
            blur.translatesAutoresizingMaskIntoConstraints = false
            
            button.insertSubview(blur, at: 0)
            button.clipsToBounds = true
            
            NSLayoutConstraint.activate([
                blur.leadingAnchor.constraint(equalTo: button.leadingAnchor),
                blur.trailingAnchor.constraint(equalTo: button.trailingAnchor),
                blur.topAnchor.constraint(equalTo: button.topAnchor),
                blur.bottomAnchor.constraint(equalTo: button.bottomAnchor)
            ])
            
            return button
        }
    }

    // MARK: - Format helpers

    private func resolveFormats(_ ids: [String]) -> [CoordinateFormat] {
        ids.compactMap { BuiltInCoordinateFormat.resolve($0) }
    }

    private func formatSummary(_ format: CoordinateFormat, primary: Bool) -> String {
        if let epsgCode = format.epsgCode {
            return "EPSG:\(epsgCode)"
        }

        let example = formatExample(format)
        if primary {
            return "\(localizedString("coordinate_format_primary")) • \(example)"
        }
        if format.id == CoordinateFormatIds.builtinUtm {
            return "UTM • \(example)"
        }
        if format.id == CoordinateFormatIds.builtinOlc {
            return "OLC • \(example)"
        }
        return example
    }

    private func formatExample(_ format: CoordinateFormat) -> String {
        guard let legacy = format.legacyFormat else { return "—" }
        let location = OsmAndApp.swiftInstance().locationServices?.lastKnownLocation
        let lat = location?.coordinate.latitude ?? Self.exampleLat
        let lon = location?.coordinate.longitude ?? Self.exampleLon
        return OAOsmAndFormatter.getFormattedCoordinates(withLat: lat, lon: lon, outputFormat: legacy) ?? "—"
    }

    private func onCopyFromAnotherProfile() {
        let bottomSheet = OACopyProfileBottomSheetViewControler(mode: appMode)
        bottomSheet?.delegate = self
        bottomSheet?.present(in: self)
    }

    private func onResetToDefault() {
        formatStorage.resetPreferredIds(appMode)
        generateData()
        tableView.reloadData()
        delegate?.onSettingsChanged()
    }
    
    @objc private func onAddAction() {
        
    }
    
    @objc private func onEditAction() {
        
    }
}

// MARK: - OACopyProfileBottomSheetDelegate

extension CoordinatesFormatViewController: OACopyProfileBottomSheetDelegate {
    func onCopyProfileCompleted() { }
    
    func onCopyProfile(_ fromMode: OAApplicationMode!) {
        formatStorage.copyPreferredIds(from: fromMode, to: appMode)
        generateData()
        tableView.reloadData()
        delegate?.onSettingsChanged()
    }
}
