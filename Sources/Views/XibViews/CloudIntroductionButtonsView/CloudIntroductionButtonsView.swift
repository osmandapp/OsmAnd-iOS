//
//  OACloudIntroductionButtonsView.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 07.08.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import UIKit

@objcMembers
final class CloudIntroductionButtonsView: UIView {
    
    @IBOutlet private weak var registerButton: UIButton! {
        didSet {
            registerButton.setTitle(localizedString("cloud_create_account"), for: .normal)
            registerButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        }
    }
    
    @IBOutlet private weak var logInButton: UIButton! {
        didSet {
            logInButton.setTitle(localizedString("register_opr_have_account"), for: .normal)
            logInButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        }
    }

    var didRegisterButtonAction: (() -> Void)? = nil
    var didLogInButtonAction: (() -> Void)? = nil
    
    // MARK: - @IBActions
    @IBAction private func onRegisterButtonPressed(_ sender: UIButton) {
        didRegisterButtonAction?()
    }
    
    @IBAction private func onLogInButtonPressed(_ sender: UIButton) {
        didLogInButtonAction?()
    }
}
