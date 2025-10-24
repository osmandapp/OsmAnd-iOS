//
//  ButtonGridVisualizationSettingsViewController.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 23.10.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import UIKit

@objcMembers
final class ButtonGridVisualizationSettingsViewController: OABaseNavbarViewController {
    private static let effective = "effective"
    private static let slots = "slots"
    private static let frames = "frames"
    
    private var showEffective = false
    private var showSlots = false
    private var showFrames = false
    
    private weak var hudLayout: MapHudLayout?
    
    init(hudLayout: MapHudLayout) {
        self.hudLayout = hudLayout
        super.init(nibName: "OABaseNavbarViewController", bundle: nil)
        initTableData()
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func commonInit() {
        if let live = hudLayout?.currentDebugFlags() {
            showEffective = live.effective
            showSlots = live.slots
            showFrames = live.frames
        } else {
            showEffective = false
            showSlots = false
            showFrames = false
        }
    }
    
    override func registerCells() {
        addCell(OASwitchTableViewCell.reuseIdentifier)
    }
    
    override func getTitle() -> String {
        localizedString("visualizing_button_grid")
    }
    
    override func getNavbarColorScheme() -> EOABaseNavbarColorScheme {
        .orange
    }
    
    override func generateData() {
        tableData.clearAllData()
        let section = tableData.createNewSection()
        func addSwitchRow(_ titleKey: String, key: String, isOn: Bool) {
            let row = section.createNewRow()
            row.cellType = OASwitchTableViewCell.reuseIdentifier
            row.title = localizedString(titleKey)
            row.key = key
            row.setObj(isOn, forKey: "isOn")
        }
        
        addSwitchRow("efficient_grid", key: Self.effective, isOn: showEffective)
        addSwitchRow("slots", key: Self.slots, isOn: showSlots)
        addSwitchRow("button_frames", key: Self.frames, isOn: showFrames)
    }
    
    override func getRow(_ indexPath: IndexPath) -> UITableViewCell? {
        let item = tableData.item(for: indexPath)
        guard item.cellType == OASwitchTableViewCell.reuseIdentifier else { return nil }
        let cell = tableView.dequeueReusableCell(withIdentifier: OASwitchTableViewCell.reuseIdentifier) as! OASwitchTableViewCell
        cell.descriptionVisibility(false)
        cell.leftIconVisibility(false)
        cell.titleLabel.text = item.title
        cell.switchView.removeTarget(nil, action: nil, for: .allEvents)
        cell.switchView.isOn = item.bool(forKey: "isOn")
        cell.switchView.tag = indexPath.section << 10 | indexPath.row
        cell.switchView.addTarget(self, action: #selector(onSwitchChanged(_:)), for: .valueChanged)
        return cell
    }
    
    @objc private func onSwitchChanged(_ sender: UISwitch) {
        guard let tableData else { return }
        let indexPath = IndexPath(row: sender.tag & 0x3FF, section: sender.tag >> 10)
        let item = tableData.item(for: indexPath)
        switch item.key {
        case Self.effective:
            showEffective = sender.isOn
        case Self.slots:
            showSlots = sender.isOn
        case Self.frames:
            showFrames = sender.isOn
        default:
            return
        }
        
        hudLayout?.setDebugOverlay(effective: showEffective, slots: showSlots, frames: showFrames)
    }
}
