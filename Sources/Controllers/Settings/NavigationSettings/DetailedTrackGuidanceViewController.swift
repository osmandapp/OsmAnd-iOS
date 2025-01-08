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
    
    override func registerCells() {
        addCell(OAImageHeaderCell.reuseIdentifier)
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
        }
        
        return nil
    }
}
