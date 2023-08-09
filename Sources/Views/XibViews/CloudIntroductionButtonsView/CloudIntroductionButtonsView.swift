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
            registerButton.titleLabel?.text = localizedString("cloud_create_account")
            registerButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        }
    }
    
    @IBOutlet private weak var logInButton: UIButton! {
        didSet {
            logInButton.titleLabel?.text = localizedString("register_opr_have_account")
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
