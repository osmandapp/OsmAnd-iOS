//
//  PreviewImageViewTableViewCell.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 09.12.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

final class PreviewImageViewTableViewCell: UITableViewCell {
    private let previewImageView: PreviewImageView = {
        let previewImageView: PreviewImageView = .fromNib()
        previewImageView.translatesAutoresizingMaskIntoConstraints = false
        return previewImageView
    }()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupPreviewImageView()
    }
    
    func configure(appearanceParams: ButtonAppearanceParams?, buttonState: MapButtonState) {
        previewImageView.configure(appearanceParams: appearanceParams, buttonState: buttonState)
    }
    
    private func setupPreviewImageView() {
        contentView.addSubview(previewImageView)
        let bottomConstraint = previewImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        bottomConstraint.priority = UILayoutPriority(999)
        NSLayoutConstraint.activate([
            previewImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            bottomConstraint,
            previewImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor)
        ])
    }
}
