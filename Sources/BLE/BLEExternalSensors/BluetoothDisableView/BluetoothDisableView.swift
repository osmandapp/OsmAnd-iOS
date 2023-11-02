//
//  BluetoothDisableView.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 31.10.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import UIKit

final class BluetoothDisableView: UIView {

    @IBOutlet weak var titleLabel: UILabel! {
        didSet {
            titleLabel.text = localizedString("ant_plus_bluetooth_off")
        }
    }
    @IBOutlet weak var descriptionLabel: UILabel! {
        didSet {
            descriptionLabel.text = localizedString("ant_plus_bluetooth_off_description")
        }
    }
    
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var settingsButton: UIButton! {
        didSet {
            settingsButton.titleLabel?.text = localizedString("ant_plus_open_settings")
        }
    }
    
    @IBOutlet private weak var separatorViewHeightConstraint: NSLayoutConstraint! {
        didSet {
            separatorViewHeightConstraint.constant = 1.0 / UIScreen.main.scale
        }
    }
    
    // MARK: - @IBActions
    @IBAction private func onSettingsButtonAction(_ sender: UIButton) {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(settingsURL) else {
            return
        }
        
        UIApplication.shared.open(settingsURL)
    }
}

