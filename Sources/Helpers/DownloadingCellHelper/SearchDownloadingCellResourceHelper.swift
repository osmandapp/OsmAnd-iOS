//
//  SearchDownloadingCellResourceHelper.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 24.04.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
final class SearchDownloadingCellResourceHelper: DownloadingCellResourceHelper {
    private static let iconPlateSize: CGFloat = 42
    private static let iconPlateCornerRadius: CGFloat = 10

    var showsIconOnPlate = false

    override func setupCell(_ resourceId: String) -> DownloadingCell? {
        if let resourceItem = getResource(resourceId) {
            resourceItem.refreshDownloadTask()
            var subtitle = ""
            if resourceItem.sizePkg() > 0 {
                subtitle = String(format: "%@  •  %@", resourceItem.formatedSizePkg(), resourceItem.type())
                if let dateString = resourceItem.getDate() {
                    subtitle += "  •  \(dateString)"
                }
            }
            
            var title = resourceItem.title() ?? ""
            
            if title.isEmpty {
                title = OAResourcesUISwiftHelper.title(ofResourceType: resourceItem.resourceType(),
                                                       in: resourceItem.worldRegion(),
                                                       withRegionName: true,
                                                       withResourceType: false)
            }
            let isDownloading = isDownloading(resourceId)
            
            // get cell with default settings
            let cell = super.setupCell(resourceId: resourceId, title: title, isTitleBold: false, desc: subtitle, leftIconName: getLeftIconName(resourceId), rightIconName: getRightIconName(resourceId), isDownloading: isDownloading)
            
            if isDisabled(resourceId) {
                cell?.titleLabel.textColor = .textColorSecondary
                cell?.rightIconVisibility(false)
            }
            cell?.selectionStyle = .none
            return cell
        }
        return nil
    }

    override func getLeftIconName(_ resourceId: String) -> String? {
        showsIconOnPlate ? nil : super.getLeftIconName(resourceId)
    }

    override func setupRightIconForIdleCell(cell: DownloadingCell, rightIconName: String?, resourceId: String) {
        super.setupRightIconForIdleCell(cell: cell, rightIconName: rightIconName, resourceId: resourceId)
        guard showsIconOnPlate else { return }
        cell.rightIconView.constraints
            .filter { $0.firstItem === cell.rightIconView && ($0.firstAttribute == .width || $0.firstAttribute == .height) }
            .forEach { $0.constant = Self.iconPlateSize }
        cell.rightIconView.backgroundColor = .imagePlaceholderBg
        cell.rightIconView.layer.cornerRadius = Self.iconPlateCornerRadius
        cell.rightIconView.layer.cornerCurve = .continuous
    }
}
