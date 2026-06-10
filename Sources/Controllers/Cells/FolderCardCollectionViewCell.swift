//
//  FolderCardCollectionViewCell.swift
//  OsmAnd Maps
//
//  Created by Vitaliy Sova on 09.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

final class FolderCardCollectionViewCell: UICollectionViewCell {

    let imageView = UIImageView()
    let titleLabel = UILabel()
    let descLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        layer.cornerRadius = 12
        clipsToBounds = true

        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.scaledSystemFont(ofSize: 15, weight: .semibold)
        titleLabel.lineBreakMode = .byTruncatingTail

        descLabel.translatesAutoresizingMaskIntoConstraints = false
        descLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        descLabel.textColor = UIColor(white: 0.67, alpha: 1)
        descLabel.lineBreakMode = .byTruncatingTail

        contentView.addSubview(imageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(descLabel)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            imageView.widthAnchor.constraint(equalToConstant: 30),
            imageView.heightAnchor.constraint(equalToConstant: 30),

            descLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 14),
            descLabel.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 8),
            descLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),

            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 2),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            titleLabel.heightAnchor.constraint(equalToConstant: 21)
        ])
    }
}
