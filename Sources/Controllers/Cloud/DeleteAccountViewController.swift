//
//  DeleteAccountViewController.swift
//  OsmAnd Maps
//
//  Created by Skalii on 19.02.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

@objc(OADeleteAccountViewController)
@objcMembers
final class DeleteAccountViewController: OABaseButtonsViewController {
    private let token: String

    init(token: String) {
        self.token = token
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Base UI

    override func getTitle() -> String! {
        localizedString("delete_account")
    }

    override func getLeftNavbarButtonTitle() -> String! {
        localizedString("shared_string_cancel")
    }

    override func getNavbarStyle() -> EOABaseNavbarStyle {
        .largeTitle
    }

    override func getTableHeaderDescription() -> String! {
        localizedString("osmand_cloud_delete_account_descr")
    }

    override func getTopButtonTitle() -> String! {
        localizedString("action_cant_be_undone")
    }

    override func getBottomButtonTitle() -> String! {
        localizedString("delete_account")
    }

    override func getTopButtonColorScheme() -> EOABaseButtonColorScheme {
        .blank
    }

    override func getBottomButtonColorScheme() -> EOABaseButtonColorScheme {
        .red
    }

    override func isBottomSeparatorVisible() -> Bool {
        false
    }

    // MARK: - Table data

    override func generateData() {
    }

    // MARK: - Selectors

    override func onBottomButtonPressed() {
        let alert = UIAlertController(title: localizedString("osmand_cloud_delete_account_confirmation"),
                                      message: "\(localizedString("osmand_cloud_delete_account_descr"))\n\n\(localizedString("action_cant_be_undone"))",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: localizedString("shared_string_delete"), style: .destructive) { [weak self] _ in
            
        })
        alert.addAction(UIAlertAction(title: localizedString("shared_string_cancel"), style: .cancel))

        present(alert, animated: true)
    }

    // MARK: - Additions

}
