//
//  DefaultMapButtonViewController.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 08.12.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

final class DefaultMapButtonViewController: OABaseNavbarViewController {
    private static let descriptionFontSize: CGFloat = 15
    
    weak var mapButtonState: MapButtonState?
    
    override func getTitle() -> String {
        mapButtonState?.getName() ?? ""
    }
    
    override func hideFirstHeader() -> Bool {
        true
    }
    
    override func registerCells() {
        addCell(OASimpleTableViewCell.reuseIdentifier)
        addCell(PreviewImageViewTableViewCell.reuseIdentifier)
    }
    
    override func generateData() {
        tableData.clearAllData()
        let visibilitySection = tableData.createNewSection()
        let imageHeaderRow = visibilitySection.createNewRow()
        imageHeaderRow.cellType = PreviewImageViewTableViewCell.reuseIdentifier
        
        let descriptionRow = visibilitySection.createNewRow()
        descriptionRow.title = mapButtonState?.buttonDescription()
        descriptionRow.cellType = OASimpleTableViewCell.reuseIdentifier
    }
    
    override func getRow(_ indexPath: IndexPath) -> UITableViewCell? {
        guard let mapButtonState else { return nil }
        let item = tableData.item(for: indexPath)
        if item.cellType == PreviewImageViewTableViewCell.reuseIdentifier {
            guard let previewIcon = mapButtonState.getPreviewIcon() else { return nil }
            let cell = tableView.dequeueReusableCell(withIdentifier: PreviewImageViewTableViewCell.reuseIdentifier) as! PreviewImageViewTableViewCell
            cell.configure(image: previewIcon)
            return cell
        } else if item.cellType == OASimpleTableViewCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: OASimpleTableViewCell.reuseIdentifier) as! OASimpleTableViewCell
            cell.descriptionVisibility(false)
            cell.leftIconVisibility(false)
            cell.selectionStyle = .none
            cell.titleLabel.text = item.title
            cell.titleLabel.textColor = .textColorSecondary
            cell.titleLabel.font = .systemFont(ofSize: Self.descriptionFontSize)
            return cell
        }
        return nil
    }
}
