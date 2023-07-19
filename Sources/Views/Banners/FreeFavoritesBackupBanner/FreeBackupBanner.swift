//
//  FreeFavoritesBackupBanner.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 18.07.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import UIKit

final class FreeBackupBanner: UIView {
    enum BannerType {
        case favorite, settings
        
    }
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel! {
        didSet {
            descriptionLabel.text = localizedString("banner_payment_free_backup_description")
        }
    }
    @IBOutlet private weak var separatorView: UIView!
    @IBOutlet private weak var osmAndCloudFavoriteButton: UIButton! {
        didSet {
            osmAndCloudFavoriteButton.titleLabel?.text = localizedString("banner_payment_free_backup_cloud_button_title")
            osmAndCloudFavoriteButton.layer.cornerRadius = 10
            osmAndCloudFavoriteButton.isHidden = true
        }
    }
    
    @IBOutlet private weak var osmAndCloudSettingsButton: UIButton! {
        didSet {
            osmAndCloudSettingsButton.titleLabel?.text = localizedString("banner_payment_free_backup_cloud_button_title")
            osmAndCloudSettingsButton.isHidden = true
        }
    }
    
    var didCloseButtonAction: (() -> Void)? = nil
    
    /*
     banner_payment_free_backup_description = "Register in OsmAnd Cloud to get free backup for favorites and settings";
     banner_payment_free_backup_favorite_title = "Free Favorites Backup"
     banner_payment_free_backup_settings_title = "Free Settings Backup"
     banner_payment_free_backup_cloud_button_title = "Get OsmAnd Cloud";
     
     */
    // Free Settings Backup
    
    func configure(bannerType: BannerType) {
        switch bannerType {
        case .favorite:
            titleLabel.text = localizedString("banner_payment_free_backup_favorite_title")
            imageView.image = UIImage(named: "ic_custom_folder_cloud_colored")
            separatorView.isHidden = false
            osmAndCloudFavoriteButton.isHidden = false
            
        case .settings:
            titleLabel.text = localizedString("banner_payment_free_backup_settings_title")
            imageView.image = UIImage(named: "ic_custom_settings_cloud_colored")
            separatorView.isHidden = true
            osmAndCloudSettingsButton.isHidden = false
        }
    }
    
    // MARK: - @IBActions
    @IBAction func onOsmAndCloudButtonAction(_ sender: UIButton) {
        print(#function)
    }
    
    @IBAction func onCloseButtonAction(_ sender: UIButton) {
        didCloseButtonAction?()
    }
}
