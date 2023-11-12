//
//  SectionHeaderFooterButton.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 09.11.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import UIKit

final class SectionHeaderFooterButton: UITableViewHeaderFooterView {
    @IBOutlet private weak var button: UIButton!
    
    static var nib: UINib {
        UINib(nibName: String(describing: self), bundle: nil)
    }
    
    var onBottonAction: (() -> Void)?
    
    func configireButton(title: String) {
        
    }
    
    @IBAction private func onButtonPressed(_ sender: Any) {
        onBottonAction?()
    }
}
