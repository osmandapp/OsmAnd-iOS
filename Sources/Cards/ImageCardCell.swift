//
//  ImageCardCell.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 20.01.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import UIKit

final class ImageCardCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var usernameLabelShadow: UIView!
    @IBOutlet weak var logoView: UIImageView!
    @IBOutlet weak var loadingIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var urlTextView: UILabel!

    private let kTextMargin: CGFloat = 4.0
    private let urlTextMargin: CGFloat = 32.0

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let cellSize = self.bounds.size
        let indicatorSize = loadingIndicatorView.frame.size
        loadingIndicatorView.frame = CGRect(
            x: cellSize.width / 2 - indicatorSize.width / 2,
            y: cellSize.height / 2 - indicatorSize.height / 2,
            width: indicatorSize.width,
            height: indicatorSize.height
        )

        let urlTextViewSize = CGSize(
            width: cellSize.width - urlTextMargin,
            height: cellSize.height - urlTextMargin
        )
        urlTextView.frame = CGRect(
            x: 16.0,
            y: 16.0,
            width: urlTextViewSize.width,
            height: urlTextViewSize.height
        )
    }

    func applyBottomCornerRadius() {
        let maskPath = UIBezierPath(
            roundedRect: usernameLabel.bounds,
            byRoundingCorners: .bottomRight,
            cornerRadii: CGSize(width: 6, height: 6)
        )
        
        let maskLayer = CAShapeLayer()
        maskLayer.frame = self.bounds
        maskLayer.path = maskPath.cgPath
        
        usernameLabel.layer.mask = maskLayer
    }

    func setUserName(_ username: String?) {
        if let username, !username.isEmpty {
            let formattedUsername = "@\(username)"
            usernameLabel.isHidden = false
            usernameLabelShadow.isHidden = false
            
            let font = UIFont.preferredFont(forTextStyle: .footnote)
            let stringBox = formattedUsername.size(withAttributes: [NSAttributedString.Key.font: font])
            var usernameFrame = usernameLabel.frame
            usernameFrame.size.width = stringBox.width + kTextMargin * 2
            usernameFrame.size.height = stringBox.height + kTextMargin
            usernameFrame.origin.x = self.frame.size.width - usernameFrame.size.width
            usernameFrame.origin.y = self.frame.size.height - usernameFrame.size.height
            usernameLabel.frame = usernameFrame
            usernameLabel.text = formattedUsername
            
            applyBottomCornerRadius()
        } else {
            usernameLabel.isHidden = true
            usernameLabelShadow.isHidden = true
        }
    }
}
