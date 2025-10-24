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
    // MARK: - Wiring

       private weak var hudLayout: MapHudLayout?
       func attach(hudLayout: MapHudLayout) { self.hudLayout = hudLayout }

       // MARK: - In-memory flags (session only)

       private struct Flags {
           var logical: Bool = false
           var effective: Bool = false
           var slots: Bool = false
           var frames: Bool = false
       }
       private var flags = Flags()

       // MARK: - Lifecycle

       override func viewWillAppear(_ animated: Bool) {
           super.viewWillAppear(animated)
           // забираем актуальные флаги из живого overlay (если есть)
           if let live = hudLayout?.currentDebugFlags() {
               flags.logical   = live.logical
               flags.effective = live.effective
               flags.slots     = live.slots
               flags.frames    = live.frames
           }
           generateData()
           reloadDataWith(animated: false, completion: nil)
       }

       // MARK: - OABaseNavbarViewController

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
               row.key = key            // используем как идентификатор свича
               row.setObj(isOn, forKey: "isOn")
           }

//           addSwitchRow("logical_grid",   key: "logical",   isOn: flags.logical)
           addSwitchRow("efficient_grid", key: "effective", isOn: flags.effective)
           addSwitchRow("slots",          key: "slots",     isOn: flags.slots)
           addSwitchRow("button_frames",  key: "frames",    isOn: flags.frames)
       }

       override func getRow(_ indexPath: IndexPath!) -> UITableViewCell! {
           let item = tableData.item(for: indexPath)
           guard item.cellType == OASwitchTableViewCell.reuseIdentifier else { return nil }

           let cell = tableView.dequeueReusableCell(withIdentifier: OASwitchTableViewCell.reuseIdentifier) as! OASwitchTableViewCell
           cell.descriptionVisibility(false)
           cell.leftIconVisibility(false)
           cell.titleLabel.text = item.title

           cell.switchView.removeTarget(nil, action: nil, for: .allEvents)
           cell.switchView.isOn = item.bool(forKey: "isOn")
           cell.switchView.accessibilityIdentifier = item.key   // "logical"/"effective"/"slots"/"frames"
           cell.switchView.addTarget(self, action: #selector(onSwitchChanged(_:)), for: .valueChanged)
           return cell
       }

       // MARK: - Actions

       @objc private func onSwitchChanged(_ sender: UISwitch) {
           let key = sender.accessibilityIdentifier ?? ""
           switch key {
           case "logical":   flags.logical   = sender.isOn
           case "effective": flags.effective = sender.isOn
           case "slots":     flags.slots     = sender.isOn
           case "frames":    flags.frames    = sender.isOn
           default: return
           }

           hudLayout?.setDebugOverlay(
               logical:   flags.logical,
               effective: flags.effective,
               slots:     flags.slots,
               frames:    flags.frames
           )
       }
}
