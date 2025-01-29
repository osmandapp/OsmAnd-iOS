//
//  NoInternetCardCell.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 28.01.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objc
public protocol CellHeightDelegate: AnyObject {
    @objc func height() -> Float
}

final class NoInternetCardCell: UICollectionViewCell {
    @IBOutlet private weak var titleLabel: UILabel! {
        didSet {
            titleLabel.text = localizedString("no_inet_connection")
        }
    }
    @IBOutlet private weak var descriptionLabel: UILabel! {
        didSet {
            descriptionLabel.text = localizedString("no_internet_descr")
        }
    }
    @IBOutlet private weak var contentStackView: UIStackView!
    
    private var item: NoInternetCard!
    
    func configure(item: NoInternetCard) {
        self.item = item
    }
    
    @IBAction private func onButtonPressed(_ sender: Any) {
        self.item.onTryAgainAction?()
    }
}

extension NoInternetCardCell: CellHeightDelegate {
    func height() -> Float {
        Float(contentStackView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height + 60 + 44)
    }
}
