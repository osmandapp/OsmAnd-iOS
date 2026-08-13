//
//  PanelsLayoutViewController.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 12.08.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

final class PanelsLayoutViewController: OABaseNavbarSubviewViewController {
    weak var delegate: OASettingsDataDelegate?

    private let previewKey = "preview"
    private let modeKey = "mode"
    private let tableTopInset: CGFloat = 16
    private let previewHeight: CGFloat = 240
    private let previewVerticalInset: CGFloat = 16
    private let previewCornerRadius: CGFloat = 26
    private let selectedIconSize: CGFloat = 30
    private let separatorLeftOffset: CGFloat = 8
    private let separatorRightInset: CGFloat = 16
    private let screenLayoutMode: ScreenLayoutMode
    private let appMode: OAApplicationMode
    private let preference: OACommonPanelsLayoutMode
    private let initialMode: PanelsLayoutMode
    
    private var selectedMode: PanelsLayoutMode

    init(screenLayoutMode: ScreenLayoutMode,
         screenElementsMode: ScreenElementsMode,
         appMode: OAApplicationMode) {
        let settings = OAAppSettings.sharedManager()
        let preference = settings.getPanelsLayoutMode(screenLayoutMode.rawValue, screenElementsMode: screenElementsMode.rawValue)
        let mode = PanelsLayoutMode(rawValue: preference.get(appMode)) ?? .defaultMode
        self.screenLayoutMode = screenLayoutMode
        self.appMode = appMode
        self.preference = preference
        initialMode = mode
        selectedMode = mode
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        var contentInset = tableView.contentInset
        contentInset.top = tableTopInset
        tableView.contentInset = contentInset
    }

    override func getTitle() -> String {
        localizedString("panels_layout")
    }

    override func systemLeftBarButtonItem() -> UIBarButtonItem? {
        UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(onClosePressed))
    }

    override func systemRightBarButtonItems() -> [UIBarButtonItem]? {
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(onDonePressed))
        doneButton.isEnabled = selectedMode != initialMode
        return [doneButton]
    }

    override func hideFirstHeader() -> Bool {
        true
    }

    override func registerCells() {
        addCell(ImageHeaderCell.reuseIdentifier)
        addCell(OASimpleTableViewCell.reuseIdentifier)
    }

    override func generateData() {
        tableData.clearAllData()
        let previewSection = tableData.createNewSection()
        previewSection.footerText = selectedMode.description
        let previewRow = previewSection.createNewRow()
        previewRow.key = previewKey
        previewRow.cellType = ImageHeaderCell.reuseIdentifier
        previewRow.iconName = selectedMode.imageName(for: screenLayoutMode)

        let modesSection = tableData.createNewSection()
        for mode in PanelsLayoutMode.allCases {
            let row = modesSection.createNewRow()
            row.cellType = OASimpleTableViewCell.reuseIdentifier
            row.title = mode.title
            row.setObj(mode, forKey: modeKey)
        }
    }

    override func getRow(_ indexPath: IndexPath) -> UITableViewCell {
        let item = tableData.item(for: indexPath)
        if item.cellType == ImageHeaderCell.reuseIdentifier {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: ImageHeaderCell.reuseIdentifier, for: indexPath) as? ImageHeaderCell else {
                return UITableViewCell()
            }
            cell.backgroundImageView.image = UIImage(named: item.iconName ?? "")
            cell.backgroundImageView.backgroundColor = .groupBg
            cell.backgroundImageView.contentMode = .center
            cell.backgroundImageView.layer.cornerRadius = previewCornerRadius
            cell.backgroundImageView.clipsToBounds = true
            cell.configure(verticalSpace: previewVerticalInset, horizontalSpace: .zero)
            return cell
        }
        
        guard let mode = item.obj(forKey: modeKey) as? PanelsLayoutMode,
              let cell = tableView.dequeueReusableCell(withIdentifier: OASimpleTableViewCell.reuseIdentifier, for: indexPath) as? OASimpleTableViewCell else {
            return UITableViewCell()
        }
        let isSelected = mode == selectedMode
        cell.selectionStyle = .default
        cell.descriptionVisibility(false)
        cell.leftIconVisibility(true)
        cell.leftIconView.image = isSelected ? .icCheckmarkDefault : nil
        cell.leftIconView.tintColor = .iconColorActive
        cell.setLeftIconSize(selectedIconSize)
        cell.titleLabel.text = item.title
        cell.accessoryType = .none
        cell.setCustomLeftSeparatorInset(true)
        cell.updateSeparatorInset()
        cell.separatorInset = UIEdgeInsets(top: .zero,
                                           left: cell.separatorInset.left - separatorLeftOffset,
                                           bottom: .zero,
                                           right: separatorRightInset)
        cell.configureAccessibility(withTitle: item.title, selected: isSelected)
        return cell
    }

    override func onRowSelected(_ indexPath: IndexPath) {
        let item = tableData.item(for: indexPath)
        guard let mode = item.obj(forKey: modeKey) as? PanelsLayoutMode,
              mode != selectedMode else {
            return
        }
        selectedMode = mode
        updateDoneButtonState()
        generateData()
        tableView.reloadData()
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let item = tableData.item(for: indexPath)
        return item.key == previewKey ? previewHeight : UITableView.automaticDimension
    }
    
    private func updateDoneButtonState() {
        navigationItem.rightBarButtonItem?.isEnabled = selectedMode != initialMode
    }

    @objc private func onClosePressed() {
        dismiss(animated: true)
    }

    @objc private func onDonePressed() {
        preference.set(selectedMode.rawValue, mode: appMode)
        delegate?.onSettingsChanged()
        dismiss(animated: true)
    }
}
