//
//  DetailedTrackGuidanceViewController.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 07.01.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import UIKit

@objc(DetailedTrackGuidanceViewController)
@objcMembers
final class DetailedTrackGuidanceViewController: OABaseSettingsViewController {
    private static let imgRowKey = "imgRowKey"
    private static let askRowKey = "askRowKey"
    private static let alwaysRowKey = "alwaysRowKey"
    private static let thresholdSliderRowKey = "thresholdSliderRowKey"
    
    private var changedTrackGuidance: EOATrackApproximationType?
    private var distanceThreshold: Int = 50
    
    override func registerCells() {
        addCell(OAImageHeaderCell.reuseIdentifier)
        addCell(OASimpleTableViewCell.reuseIdentifier)
        addCell(OATitleSliderRoundCell.reuseIdentifier)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        changedTrackGuidance = EOATrackApproximationType(rawValue: Int(OAAppSettings.sharedManager().detailedTrackGuidance.get(appMode)))
        distanceThreshold = Int(OAAppSettings.sharedManager().gpxApproximationDistance.get(self.appMode))
        generateData()
        tableView.reloadData()
    }
    
    override func getTitle() -> String? {
        localizedString("detailed_track_guidance")
    }
    
    override func getSubtitle() -> String? {
        ""
    }
    
    override func getLeftNavbarButtonTitle() -> String? {
        localizedString("shared_string_cancel")
    }
    
    override func getRightNavbarButtons() -> [UIBarButtonItem] {
        guard let applyBarButton = createRightNavbarButton(localizedString("shared_string_apply"), iconName: nil, action: #selector(onRightNavbarButtonPressed), menu: nil) else { return [] }
        return [applyBarButton]
    }
    
    override func hideFirstHeader() -> Bool {
        true
    }
    
    override func generateData() {
        tableData.clearAllData()
        let detailedTrackImgSection = tableData.createNewSection()
        detailedTrackImgSection.footerText = localizedString("detailed_track_guidance_description")
        let imgRow = detailedTrackImgSection.createNewRow()
        imgRow.cellType = OAImageHeaderCell.reuseIdentifier
        imgRow.key = Self.imgRowKey
        imgRow.iconName = "img_detailed_track_guidance"
        let detailedTrackSettingsSection = tableData.createNewSection()
        let askRow = detailedTrackSettingsSection.createNewRow()
        askRow.cellType = OASimpleTableViewCell.reuseIdentifier
        askRow.key = Self.askRowKey
        askRow.title = localizedString("ask_every_time")
        askRow.iconName = "ic_checkmark_default"
        askRow.setObj(changedTrackGuidance == .manual, forKey: "selected")
        let alwaysRow = detailedTrackSettingsSection.createNewRow()
        alwaysRow.cellType = OASimpleTableViewCell.reuseIdentifier
        alwaysRow.key = Self.alwaysRowKey
        alwaysRow.title = localizedString("shared_string_always")
        alwaysRow.iconName = "ic_checkmark_default"
        alwaysRow.setObj(changedTrackGuidance == .automatic, forKey: "selected")
        if changedTrackGuidance == .automatic {
            let thresholdSection = tableData.createNewSection()
            let thresholdSliderRow = thresholdSection.createNewRow()
            thresholdSliderRow.cellType = OATitleSliderRoundCell.reuseIdentifier
            thresholdSliderRow.key = Self.thresholdSliderRowKey
            thresholdSliderRow.title = localizedString("threshold_distance")
        }
    }
    
    override func getRow(_ indexPath: IndexPath?) -> UITableViewCell? {
        guard let indexPath else { return nil }
        let item = tableData.item(for: indexPath)
        if item.cellType == OAImageHeaderCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: OAImageHeaderCell.reuseIdentifier) as! OAImageHeaderCell
            cell.selectionStyle = .none
            cell.backgroundImageView.image = UIImage(named: item.iconName ?? "")
            cell.backgroundImageView.layer.cornerRadius = 4
            return cell
        } else if item.cellType == OASimpleTableViewCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: OASimpleTableViewCell.reuseIdentifier) as! OASimpleTableViewCell
            cell.descriptionVisibility(false)
            cell.titleLabel.text = item.title
            cell.leftIconView.image = item.obj(forKey: "selected") as? Bool ?? false ? UIImage.templateImageNamed(item.iconName) : nil
            cell.leftIconView.tintColor = .iconColorActive
            return cell
        } else if item.cellType == OATitleSliderRoundCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: OATitleSliderRoundCell.reuseIdentifier) as! OATitleSliderRoundCell
            cell.selectionStyle = .none
            cell.titleLabel.text = item.title
            cell.sliderView.minimumValue = 0
            cell.sliderView.maximumValue = 100
            cell.sliderView.value = Float(distanceThreshold)
            cell.valueLabel.text = OAOsmAndFormatter.getFormattedDistance(Float(distanceThreshold))
            cell.sliderView.tag = indexPath.section << 10 | indexPath.row
            cell.sliderView.removeTarget(self, action: nil, for: .allEvents)
            cell.sliderView.addTarget(self, action: #selector(sliderValueChanged(sender:)), for: .allEvents)
            return cell
        }
        
        return nil
    }
    
    override func onRowSelected(_ indexPath: IndexPath) {
        guard let tableData else { return }
        let item = tableData.item(for: indexPath)
        changedTrackGuidance = item.key == Self.askRowKey ? .manual : .automatic
        generateData()
        tableView.reloadData()
    }
    
    override func onRightNavbarButtonPressed() {
        if let trackGuidance = changedTrackGuidance {
            OAAppSettings.sharedManager().detailedTrackGuidance.set(Int32(trackGuidance.rawValue), mode: appMode)
        }
        
        OAAppSettings.sharedManager().gpxApproximationDistance.set(Int32(distanceThreshold), mode: self.appMode)
        delegate.onSettingsChanged()
        super.onLeftNavbarButtonPressed()
    }
    
    @objc private func sliderValueChanged(sender: UISlider) {
        let indexPath = IndexPath(row: sender.tag & 0x3FF, section: sender.tag >> 10)
        if let cell = tableView.cellForRow(at: indexPath) as? OATitleSliderRoundCell {
            cell.sliderView = sender
            distanceThreshold = Int(cell.sliderView.value)
            cell.valueLabel.text = OAOsmAndFormatter.getFormattedDistance(Float(distanceThreshold))
        }
    }
}
