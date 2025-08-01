//
//  DistanceByTapViewController.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 01.08.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import Foundation

final class DistanceByTapViewController: OABaseNavbarViewController {
    private static let imgRowKey = "imgRowKey"
    
    weak var delegate: WidgetStateDelegate?
    
    override func getTitle() -> String {
        localizedString("map_widget_distance_by_tap")
    }
    
    override func hideFirstHeader() -> Bool {
        true
    }
    
    override func registerCells() {
        addCell(ImageHeaderCell.reuseIdentifier)
    }
    
    override func generateData() {
        tableData.clearAllData()
        
        let distanceByTapImgSection = tableData.createNewSection()
        distanceByTapImgSection.footerText = localizedString("distance_by_tap_use_description")
        
        let imgRow = distanceByTapImgSection.createNewRow()
        imgRow.cellType = ImageHeaderCell.reuseIdentifier
        imgRow.key = Self.imgRowKey
        imgRow.iconName = "img_distance_by_tap"
    }
    
    override func getRow(_ indexPath: IndexPath?) -> UITableViewCell? {
        guard let indexPath else { return nil }
        let item = tableData.item(for: indexPath)
        if item.cellType == ImageHeaderCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: ImageHeaderCell.reuseIdentifier) as! ImageHeaderCell
            cell.selectionStyle = .none
            cell.backgroundImageView.image = UIImage(named: item.iconName ?? "")
            cell.backgroundImageView.layer.cornerRadius = 6
            cell.configure(verticalSpace: 16, horizontalSpace: 16)
            return cell
        }
        return nil
    }
}
