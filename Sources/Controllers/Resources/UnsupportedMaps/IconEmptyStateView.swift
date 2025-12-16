//
//  IconEmptyStateView.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 01.12.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

final class IconEmptyStateView: UIView {
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var iconView: UIImageView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    func configure(image: UIImage, tintColor: UIColor, description: String) {
        iconView.image = image
        iconView.tintColor = tintColor
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.12
        descriptionLabel.attributedText = NSAttributedString(string: description,
                                                             attributes: [NSAttributedString.Key.paragraphStyle: paragraphStyle])
    }
    
    private func commonInit() {
        let nib = UINib(nibName: String(describing: Self.self), bundle: .main)
        guard let view = nib.instantiate(withOwner: self, options: nil).first as? UIView else {
            return
        }
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: leadingAnchor),
            view.trailingAnchor.constraint(equalTo: trailingAnchor),
            view.topAnchor.constraint(equalTo: topAnchor),
            view.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}
