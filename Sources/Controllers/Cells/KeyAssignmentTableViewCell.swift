//
//  KeyAssignmentTableViewCell.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 27.08.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

final class KeyAssignmentTableViewCell: OASimpleTableViewCell {
    @IBOutlet private weak var keysStackView: UIStackView!
    
    func configure(inputs: [String]) {
        keysStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for input in inputs {
            let keyView: KeyView = .fromNib()
            keyView.configureWith(input: input, horizontalSpace: 12, fontSize: 12)
            keysStackView.addArrangedSubview(keyView)
        }
    }
}
