//
//  ScreenElementsViewController.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 13.07.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

final class ScreenElementsViewController: OABaseNavbarViewController {
    weak var delegate: OASettingsDataDelegate?

    private let previewKey = "previewKey"
    private let modeKey = "modeKey"
    private let tableTopInset: CGFloat = 16
    private let previewHeight: CGFloat = 180
    private let previewCornerRadius: CGFloat = 26
    private let selectedIconSize: CGFloat = 30
    private let separatorLeftOffset: CGFloat = 8
    private let separatorRightInset: CGFloat = 16
    private let settings: OAAppSettings
    private let appMode: OAApplicationMode
    private let initialMode: ScreenElementsMode

    private var selectedMode: ScreenElementsMode

    init(appMode: OAApplicationMode) {
        let settings = OAAppSettings.sharedManager()
        let mode = ScreenElementsMode(usesSeparateLayouts: settings.useSeparateLayouts.get(appMode))
        self.settings = settings
        self.appMode = appMode
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
        localizedString("screen_elements")
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
        addCell(DoubleImageHeaderCell.reuseIdentifier)
        addCell(OASimpleTableViewCell.reuseIdentifier)
    }

    override func generateData() {
        tableData.clearAllData()

        let previewSection = tableData.createNewSection()
        previewSection.footerText = localizedString("screen_elements_mode_descr")
        let previewRow = previewSection.createNewRow()
        previewRow.key = previewKey
        previewRow.cellType = DoubleImageHeaderCell.reuseIdentifier

        let modesSection = tableData.createNewSection()
        for mode in ScreenElementsMode.allCases {
            let row = modesSection.createNewRow()
            row.cellType = OASimpleTableViewCell.reuseIdentifier
            row.title = mode.title
            row.setObj(mode, forKey: modeKey)
        }
    }

    override func getRow(_ indexPath: IndexPath) -> UITableViewCell {
        let item = tableData.item(for: indexPath)
        if item.cellType == DoubleImageHeaderCell.reuseIdentifier {
            let isShared = selectedMode == .shared
            guard let cell = tableView.dequeueReusableCell(withIdentifier: DoubleImageHeaderCell.reuseIdentifier, for: indexPath) as? DoubleImageHeaderCell else {
                return UITableViewCell()
            }
            cell.backgroundConfiguration = .clear()
            cell.leftBackgroundImageView.image = .imgPanelsLayoutPortraitWide
            cell.rightBackgroundImageView.image = .imgPanelsLayoutLandscapeWide
            cell.secondBackgroundImageView.image = .imgPanelsLayoutLandscapeCompact2
            cell.configure(isSingleView: isShared, cornerRadius: previewCornerRadius)
            return cell
        }

        guard let mode = item.obj(forKey: modeKey) as? ScreenElementsMode,
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
        guard let mode = item.obj(forKey: modeKey) as? ScreenElementsMode,
              mode != selectedMode else {
            return
        }
        selectedMode = mode
        updateDoneButtonState()
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
        if selectedMode != initialMode {
            settings.useSeparateLayouts.set(selectedMode.usesSeparateLayouts, mode: appMode)
            OARootViewController.instance().mapPanel.recreateAllControls()
            delegate?.onSettingsChanged()
        }
        dismiss(animated: true)
    }
}
