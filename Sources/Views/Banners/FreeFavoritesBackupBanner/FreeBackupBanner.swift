//
//  FreeFavoritesBackupBanner.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 18.07.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import UIKit

@objcMembers
final class FreeBackupBanner: UIView {
    @objc enum BannerType: Int {
        case favorite
        case settings
        case mapSettingsTopography
    }
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel! {
        didSet {
            descriptionLabel.text = localizedString("free_favorites_backup_description")
        }
    }
    
    @IBOutlet weak var leadingSubviewConstraint: NSLayoutConstraint!
    @IBOutlet weak var trailingSubviewConstraint: NSLayoutConstraint!
    
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var closeButton: UIButton!
    @IBOutlet private weak var osmAndCloudButton: UIButton! {
        didSet {
            osmAndCloudButton.titleLabel?.text = localizedString("banner_payment_free_backup_cloud_button_title")
        }
    }
    
    @IBOutlet private weak var separatorViewHeightConstraint: NSLayoutConstraint! {
        didSet {
            separatorViewHeightConstraint.constant = 1.0 / UIScreen.main.scale
        }
    }
    
    var didCloseButtonAction: (() -> Void)? = nil
    var didOsmAndCloudButtonAction: (() -> Void)? = nil
    
    var defaultFrameHeight = 100
    var leadingTrailingOffset = 137
    
    func configure(bannerType: BannerType) {
        switch bannerType {
        case .favorite:
            titleLabel.text = localizedString("free_favorites_backup")
            imageView.image = UIImage(named: "ic_custom_folder_cloud_colored")
        case .settings:
            titleLabel.text = localizedString("banner_payment_free_backup_settings_title")
            imageView.image = UIImage(named: "ic_custom_settings_cloud_colored")
        case .mapSettingsTopography:
            titleLabel.text = localizedString("srtm_plugin_name")
            descriptionLabel.text = localizedString("purchases_feature_desc_terrain")
            imageView.image = UIImage.templateImageNamed("ic_custom_terrain")
            imageView.tintColor = UIColor.iconColorActive
            closeButton.isHidden = true
            osmAndCloudButton.setTitle(localizedString("shared_string_get"), for: .normal)
        }
    }
    
    // MARK: - @IBActions
    @IBAction private func onOsmAndCloudButtonAction(_ sender: UIButton) {
        didOsmAndCloudButtonAction?()
    }
    
    @IBAction private func onCloseButtonAction(_ sender: UIButton) {
        didCloseButtonAction?()
    }
}
