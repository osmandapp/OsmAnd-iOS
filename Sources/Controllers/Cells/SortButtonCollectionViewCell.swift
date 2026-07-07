//
//  SortButtonCollectionViewCell.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 01.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

final class SortButtonCollectionViewCell: UICollectionViewListCell {
    lazy var sortButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.imagePadding = 7
        config.imagePlacement = .leading
        config.baseForegroundColor = .iconColorActive
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .preferredFont(forTextStyle: .subheadline)
            return outgoing
        }
        let button = UIButton(configuration: config, primaryAction: nil)
        button.showsMenuAsPrimaryAction = true
        button.changesSelectionAsPrimaryAction = true
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundConfiguration = .clear()
        
        addSubview(sortButton)
        sortButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            sortButton.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            sortButton.topAnchor.constraint(equalTo: topAnchor),
            sortButton.bottomAnchor.constraint(equalTo: bottomAnchor),
            sortButton.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),
            sortButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError()
    }
}
