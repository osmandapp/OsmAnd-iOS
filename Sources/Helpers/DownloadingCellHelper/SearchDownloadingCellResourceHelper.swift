//
//  SearchDownloadingCellResourceHelper.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 24.04.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
final class SearchDownloadingCellResourceHelper: DownloadingCellResourceHelper {
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
                                                       withResourceType: true)
            }
            let isDownloading = isDownloading(resourceId)
            
            // get cell with default settings
            let cell = super.setupCell(resourceId: resourceId, title: title, isTitleBold: false, desc: subtitle, leftIconName: getLeftIconName(resourceId), rightIconName: getRightIconName(resourceId), isDownloading: isDownloading)
            
            if isDisabled(resourceId) {
                cell?.titleLabel.textColor = .textColorSecondary
                cell?.rightIconVisibility(false)
            }
            return cell
        }
        return nil
    }
}
