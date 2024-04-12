//
//  LeftIconRightStackView.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 01.04.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

@objcMembers
final class LeftIconRightStackTitleDescriptionButtonView: UIView {
    @IBOutlet weak var stackView: UIStackView!
    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var bottomButton: UIButton!
    @IBOutlet private weak var leftImageView: UIImageView!
    
    var didBottomButtonTapAction: (() -> Void)?
    
    static var view: LeftIconRightStackTitleDescriptionButtonView? {
        UINib(nibName: String(describing: self), bundle: nil)
            .instantiate(withOwner: nil, options: nil)[0] as? LeftIconRightStackTitleDescriptionButtonView
    }
    
    // MARK: - Configure
    
    func configure(title: String,
                   description: String,
                   buttonTitle: String,
                   leftImage: UIImage,
                   leftImageTintColor: UIColor = UIColor.iconColorDefault) {
        titleLabel.text = title
        descriptionLabel.text = description
        bottomButton.setTitle(buttonTitle, for: .normal)
        leftImageView.image = leftImage
        leftImageView.tintColor = leftImageTintColor
        
        bottomButton.addTarget(self, action: #selector(onBottomButtonTap), for: .touchUpInside)
    }
    
    // MARK: - Actions
    
    @objc private func onBottomButtonTap() {
        didBottomButtonTapAction?()
    }
}
