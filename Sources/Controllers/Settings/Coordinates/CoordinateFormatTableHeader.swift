//
//  CoordinateFormatTableHeader.swift
//  OsmAnd Maps
//
//  Created by Vitaliy Sova on 27.08.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

enum CoordinateFormatTableHeader {
    static func makeDescriptionHeader(width: CGFloat) -> UIView {
        let horizontalInset: CGFloat = 36 + OAUtilities.getLeftMargin()
        let top: CGFloat = 12
        let bottom: CGFloat = 8

        let header = UIView(frame: CGRect(x: 0, y: 0, width: width, height: 1))

        let text = localizedString("coordinate_format_description")
        let attr = NSAttributedString(
            string: text,
            attributes: [
                .font: UIFont.preferredFont(forTextStyle: .footnote),
                .foregroundColor: UIColor.textColorSecondary
            ]
        )
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.attributedText = attr
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.textAlignment = .natural
        label.adjustsFontForContentSizeCategory = true
        header.addSubview(label)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: horizontalInset),
            label.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -horizontalInset),
            label.topAnchor.constraint(equalTo: header.topAnchor, constant: top),
            label.bottomAnchor.constraint(equalTo: header.bottomAnchor, constant: -bottom)
        ])

        relayoutTableHeaderViewIfNeeded(header, width: width)
        return header
    }

    @discardableResult static func relayoutTableHeaderViewIfNeeded(_ header: UIView, width: CGFloat) -> Bool {
        let target = CGSize(width: width, height: UIView.layoutFittingCompressedSize.height)
        let height = header.systemLayoutSizeFitting(
            target,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height
        guard abs(header.frame.height - height) > 0.5 || abs(header.frame.width - width) > 0.5 else {
            return false
        }
        header.frame.size = CGSize(width: width, height: height)
        return true
    }
}
