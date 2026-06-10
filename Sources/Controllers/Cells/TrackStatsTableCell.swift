//
//  TrackStatsTableCell.swift
//  OsmAnd Maps
//
//  Created by Vitaliy Sova on 10.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit
import OsmAndShared

final class TrackStatsTableCell: UITableViewCell, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    private let collectionView: UICollectionView
    private var statisticsData: [OAGPXTableCellData] = []

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 12
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        selectionStyle = .none
        backgroundColor = .groupBg
        contentView.backgroundColor = .groupBg

        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(
            UINib(nibName: OAGpxStatBlockCollectionViewCell.getIdentifier(), bundle: nil),
            forCellWithReuseIdentifier: OAGpxStatBlockCollectionViewCell.getIdentifier()
        )

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            collectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            collectionView.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    func configure(gpxFile: GpxFile) {
        let analysis = gpxFile.getAnalysis(fileTimestamp: 0,
                                           fromDistance: nil,
                                           toDistance: nil,
                                           pointsAnalyzer: PlatformUtil.shared.getTrackPointsAnalyser())
        
        statisticsData = OATrackMenuHeaderView.generateGpxBlockStatistics(analysis, withoutGaps: false) as? [OAGPXTableCellData] ?? []
        collectionView.contentOffset.x = -collectionView.contentInset.left
        collectionView.reloadData()
    }
    
    func configure(statistics: [OAGPXTableCellData]) {
        statisticsData = statistics
        collectionView.contentOffset.x = -collectionView.contentInset.left
        collectionView.reloadData()
    }

    static func hasStatistics(for gpxFile: GpxFile) -> Bool {
        let analysis = gpxFile.getAnalysis(
            fileTimestamp: 0,
            fromDistance: nil,
            toDistance: nil,
            pointsAnalyzer: PlatformUtil.shared.getTrackPointsAnalyser()
        )
        let cells = OATrackMenuHeaderView.generateGpxBlockStatistics(analysis, withoutGaps: false) as? [OAGPXTableCellData] ?? []
        return !cells.isEmpty
    }

    // MARK: - UICollectionView

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        statisticsData.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: OAGpxStatBlockCollectionViewCell.getIdentifier(),
                                                      for: indexPath) as! OAGpxStatBlockCollectionViewCell
        let cellData = statisticsData[indexPath.row]

        cell.valueView.text = cellData.values["string_value"] as? String
        cell.iconView.image = .templateImageNamed(cellData.rightIconName)
        cell.iconView.tintColor = .iconColorDefault
        cell.titleView.text = cellData.title
        cell.separatorView.isHidden = cell.isDirectionRTL() ? indexPath.row == 0 : indexPath.row == statisticsData.count - 1
        if cell.needsUpdateConstraints() {
            cell.updateConstraints()
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellData = statisticsData[indexPath.row]
        let isLast = indexPath.row == statisticsData.count - 1
        let text = cellData.values["string_value"] as? String
        return OATrackMenuHeaderView.getSizeForItem(cellData.title, value: text, isLast: isLast)
    }
}
