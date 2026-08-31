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
    
    override func refreshOnAppear() -> Bool {
        true
    }
    
    // MARK: - NavBar

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
    
    // MARK: - Table
    
    override func registerCells() {
        addCell(OASimpleTableViewCell.reuseIdentifier)
    }
    
    override func setupTableHeaderView() {
        tableView.tableHeaderView = CoordinateFormatTableHeader.makeDescriptionHeader(width: view.bounds.width)
    }
    
    override func hideFirstHeader() -> Bool {
        true
    }

    override func generateData() {
        tableData.clearAllData()

        let section = tableData.createNewSection()

        let formats = CoordinateFormatHelper.resolve(formatStorage.preferredIds(appMode))
        for (index, format) in formats.enumerated() {
            let row = section.createNewRow()
            row.cellType = OASimpleTableViewCell.reuseIdentifier
            row.title = format.title
            row.descr = CoordinateFormatHelper.summary(format, primary: index == 0)
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
        guard CoordinateFormatTableHeader.relayoutTableHeaderViewIfNeeded(header, width: width) else { return }
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

    // MARK: - Actions
    
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
        let ids = formatStorage.preferredIds(appMode)
        let vc = CoordinatesFormatAddViewController(appMode: appMode, excludedIds: ids)
        vc.onFormatAdded = { [weak self] id in
            guard let self else { return }
            self.formatStorage.addPreferredId(self.appMode, id: id)
            self.generateData()
            self.tableView.reloadData()
            self.delegate?.onSettingsChanged()
        }
        let navVC = UINavigationController(rootViewController: vc)
        navVC.modalPresentationStyle = .fullScreen
        present(navVC, animated: true)
    }
    
    @objc private func onEditAction() {
        guard let vc = CoordinatesFormatEditViewController(appMode: appMode) else {
            return
        }
        let navVC = UINavigationController(rootViewController: vc)
        navVC.modalPresentationStyle = .fullScreen
        present(navVC, animated: true)
    }
}

// MARK: - OACopyProfileBottomSheetDelegate

extension CoordinatesFormatViewController: OACopyProfileBottomSheetDelegate {
    func onCopyProfileCompleted() { }
    
    func onCopyProfile(_ fromMode: OAApplicationMode?) {
        guard let fromMode else { return }
        formatStorage.copyPreferredIds(from: fromMode, to: appMode)
        generateData()
        tableView.reloadData()
        delegate?.onSettingsChanged()
    }
}
