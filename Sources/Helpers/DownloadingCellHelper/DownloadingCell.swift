//
//  DownloadingCell.swift
//  OsmAnd Maps
//
//  Created by Max Kojin on 01/06/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

final class DownloadingCell: OARightIconTableViewCell {
    @objc var onDownloadFinishedAction: ((String) -> Void)?
}
