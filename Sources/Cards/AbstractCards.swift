//
//  AbstractCard.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 20.01.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import UIKit

@objc
public protocol AbstractCardDelegate: AnyObject {
    @objc func requestCardReload(_ card: AbstractCard)
}

@objcMembers
public class AbstractCard: NSObject {
    
    weak var delegate: AbstractCardDelegate?

    class func getCellNibId() -> String {
        ""
    }

    func build(in cell: UICollectionViewCell) {
        cell.clipsToBounds = false
        cell.backgroundColor = .white
        cell.layer.backgroundColor = UIColor.white.cgColor
        cell.layer.cornerRadius = 6.0
        cell.layer.shadowOffset = CGSize(width: 0, height: 1)
        cell.layer.shadowOpacity = 0.3
        cell.layer.shadowRadius = 2.0
        update()
    }

    func update() {
        // Implement in subclasses
    }

    func onCardPressed(_ mapPanel: OAMapPanelViewController) {
        // Implement in subclasses
    }
}
