//
//  NameTagsDetailsViewController.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 20.06.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import UIKit

@objc(OANameTagsDetailsViewController)
@objcMembers
final class NameTagsDetailsViewController: OABaseNavbarViewController {
    private var tags: [NSDictionary]
    private let keysToSections: [String: String] = ["reg_name": "route_name_regional", "loc_name": "route_name_local", "name": "shared_string_name", "nat_name": "route_name_national", "int_name": "route_name_international", "short_name": "route_name_short", "official_name": "route_name_official", "old_name": "route_name_old", "alt_name": "route_name_alt"]
    
    init(tags: [NSDictionary]) {
        self.tags = tags
        super.init(nibName: "OABaseNavbarViewController", bundle: nil)
        initTableData()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func registerCells() {
        addCell(OASimpleTableViewCell.reuseIdentifier)
    }
    
    override func getTitle() -> String? {
        localizedString("shared_string_name")
    }
    
    override func getLeftNavbarButtonTitle() -> String? {
        localizedString("shared_string_cancel")
    }
    
    override func generateData() {
        tableData.clearAllData()
        for (key, header) in keysToSections {
            let filteredTags = tags.filter { tag in
                guard let tagKey = tag["key"] as? String else { return false }
                return tagKey.hasPrefix(key)
            }
            
            if !filteredTags.isEmpty {
                let section = tableData.createNewSection()
                section.headerText = localizedString(header)
                for tagDict in filteredTags {
                    let row = section.createNewRow()
                    row.cellType = OASimpleTableViewCell.getIdentifier()
                    row.key = key
                    row.title = tagDict["value"] as? String ?? ""
                    row.descr = tagDict["localizedTitle"] as? String ?? ""
                }
            }
        }
    }
    
    override func getRow(_ indexPath: IndexPath?) -> UITableViewCell? {
        guard let indexPath else { return nil }
        let item = tableData.item(for: indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: OASimpleTableViewCell.getIdentifier(), for: indexPath) as! OASimpleTableViewCell
        cell.selectionStyle = .none
        cell.leftIconVisibility(false)
        cell.descriptionVisibility(!(item.descr?.isEmpty ?? true))
        cell.titleLabel.text = item.title
        cell.descriptionLabel.text = item.descr
        return cell
    }
}
