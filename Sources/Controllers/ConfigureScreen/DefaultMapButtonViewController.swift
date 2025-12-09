//
//  DefaultMapButtonViewController.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 08.12.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

final class DefaultMapButtonViewController: OABaseNavbarViewController {
    weak var mapButtonState: MapButtonState?
    
    override func getTitle() -> String {
        mapButtonState?.getName() ?? ""
    }
    
    override func hideFirstHeader() -> Bool {
        true
    }
    
    override func registerCells() {
        addCell(PreviewImageViewTableViewCell.reuseIdentifier)
    }
    
    override func generateData() {
        tableData.clearAllData()
        let visibilitySection = tableData.createNewSection()
        let imageHeaderRow = visibilitySection.createNewRow()
        imageHeaderRow.cellType = PreviewImageViewTableViewCell.reuseIdentifier
    }
    
    override func getRow(_ indexPath: IndexPath) -> UITableViewCell? {
        guard let mapButtonState else { return nil }
        let item = tableData.item(for: indexPath)
        if item.cellType == PreviewImageViewTableViewCell.reuseIdentifier {
            guard let previewIcon = mapButtonState.getPreviewIcon() else { return nil }
            let cell = tableView.dequeueReusableCell(withIdentifier: PreviewImageViewTableViewCell.reuseIdentifier) as! PreviewImageViewTableViewCell
            cell.configure(image: previewIcon)
            return cell
        }
        return nil
    }
}
