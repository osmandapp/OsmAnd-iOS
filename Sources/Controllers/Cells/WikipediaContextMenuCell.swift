//
//  WikipediaContextMenuCell.swift
//  OsmAnd Maps
//
//  Created by Vitaliy Sova on 22.05.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

@objcMembers
final class WikipediaContextMenuCell: UITableViewCell {
    
    // MARK: - Properties

    let menuView = WikipediaContextMenuView()
    
    var onExpandStateChange: ((Bool, WikipediaContextMenuCell) -> Void)?

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configure
    
    func configure(text: String,
                   buttonText: String,
                   icon: UIImage?,
                   onButtonAction: @escaping () -> Void) {
        menuView.configure(text: text, buttonText: buttonText, icon: icon, onButtonAction: onButtonAction)
        menuView.onExpandStateChange = { [weak self] expanded in
            guard let self else { return }
            self.onExpandStateChange?(expanded, self)
        }
    }

    /// Used in legacy UITableView setups with manual row height calculation.
    /// Returns the height of the cell calculated using Auto Layout for the given width.
    func calculateHeight(in width: CGFloat) -> CGFloat {
        let targetSize = CGSize(width: width, height: UIView.layoutFittingCompressedSize.height)

        let size = contentView.systemLayoutSizeFitting(targetSize,
                                                       withHorizontalFittingPriority: .required,
                                                       verticalFittingPriority: .fittingSizeLevel)

        return ceil(size.height)
    }
    
    // MARK: - Setup

    private func setupUI() {
        separatorInset = .zero
        selectionStyle = .none
        
        menuView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(menuView)
        
        NSLayoutConstraint.activate([
            menuView.topAnchor.constraint(equalTo: contentView.topAnchor),
            menuView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            menuView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            menuView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
}
