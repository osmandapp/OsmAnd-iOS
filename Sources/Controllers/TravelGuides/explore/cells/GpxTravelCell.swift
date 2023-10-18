//
//  GpxTravelCell.swift
//  OsmAnd Maps
//
//  Created by nnngrach on 18.08.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import UIKit

class GpxTravelCell: UITableViewCell, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    @IBOutlet weak var arcticleTitle: UILabel!
    
    @IBOutlet weak var usernameView: UIView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var usernameIcon: UIImageView!
    
    @IBOutlet weak var collectionView: UICollectionView!

    var travelGpx: TravelGpx?
    var statisticsCells : [OAGPXTableCellData]?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
        collectionView.register(UINib(nibName: OAGpxStatBlockCollectionViewCell.getIdentifier(), bundle: nil), forCellWithReuseIdentifier: OAGpxStatBlockCollectionViewCell.getIdentifier())
    }
    
 
    //MARK: UICollectionViewDataSource
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return statisticsCells?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cellData = statisticsCells![indexPath.row]
        var cell = collectionView.dequeueReusableCell(withReuseIdentifier: OAGpxStatBlockCollectionViewCell.getIdentifier(), for: indexPath) as? OAGpxStatBlockCollectionViewCell
        
        if cell == nil {
            let nib = Bundle.main.loadNibNamed(OAGpxStatBlockCollectionViewCell.getIdentifier(), owner: self, options: nil)
            cell = nib?.first as? OAGpxStatBlockCollectionViewCell
            cell?.backgroundColor = .clear
        }
        cell!.valueView.text = cellData.values["string_value"] as? String
        cell!.iconView.image = UIImage.templateImageNamed(cellData.rightIconName)
        cell!.iconView.tintColor = UIColor.iconColorDefault
        cell!.titleView.text = cellData.title
        
        cell!.separatorView.isHidden = cell!.isDirectionRTL() ? (indexPath.row == 0) : (indexPath.row == statisticsCells!.count - 1)
        if cell!.needsUpdateConstraints() {
            cell!.updateConstraints()
        }
        return cell!
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellData = statisticsCells![indexPath.row]
        let isLast = indexPath.row == statisticsCells!.count - 1
        let text = cellData.values["string_value"] as? String
        return OATrackMenuHeaderView.getSizeForItem(cellData.title, value: text, isLast: isLast)
    }
}
