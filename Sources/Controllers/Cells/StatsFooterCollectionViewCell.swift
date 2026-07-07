//
//  StatsFooterCollectionViewCell.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 17.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

final class StatsFooterCollectionViewCell: UICollectionViewCell {
    private static let statsFooterInsets = NSDirectionalEdgeInsets(top: 12.0, leading: 20.0, bottom: 12.0, trailing: 20.0)
    
    lazy var label: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .footnote)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .textColorSecondary
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLabel()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func setupLabel() {
        contentView.addSubview(label)
        
        NSLayoutConstraint.activate([label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Self.statsFooterInsets.top), label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Self.statsFooterInsets.leading), label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Self.statsFooterInsets.trailing), label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Self.statsFooterInsets.bottom)])
    }
}
