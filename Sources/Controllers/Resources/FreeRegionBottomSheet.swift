//
//  FreeRegionBottomSheet.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 09.11.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

@objcMembers
final class FreeRegionBottomSheet: OABaseButtonsViewController {
    private enum Step {
        case replace, email, buy
    }
    
    private static let combineFormat = "%@  •  %@"
    
    private let spinner = UIActivityIndicatorView(style: .medium)
    private let freeRegion: OAWorldRegion
    private let region: OAWorldRegion
    private let mapsToDelete: [(region: OAWorldRegion, items: [OAResourceSwiftItem])]
    private let mapPaths: [String: String]
    private let onReplaced: () -> Void
    
    private var step = Step.replace
    private var email = ""
    private var isLoading = false
    private var isEmailErrorShown = false
    
    private var isEmailValid: Bool {
        (email as NSString).isValidEmail()
    }
    
    private var emailFooterText: String {
        guard !isEmailErrorShown else { return localizedString("osm_live_enter_email") }
        let helper = localizedString("free_region_email_helper")
        guard !mapsToDelete.isEmpty else { return helper }
        let names = mapsToDelete.map { $0.region.name ?? "" }.joined(separator: ", ")
        return helper + " " + String(format: localizedString("free_region_email_maps_deleted"), names, mapsToDeleteSize)
    }
    
    private var mapsToDeleteSize: String {
        OAResourcesUISwiftHelper.formatSize(mapsToDelete.flatMap(\.items).reduce(0) { $0 + $1.size() }, addZero: false)
    }
    
    init(freeRegion: OAWorldRegion, region: OAWorldRegion, onReplaced: @escaping () -> Void) {
        self.freeRegion = freeRegion
        self.region = region
        self.onReplaced = onReplaced
        mapsToDelete = FreeVersionMapDownloads.shared.collectMapsToDelete(region)
        mapPaths = OAObfFileList.pathsByResourceId(for: mapsToDelete.flatMap(\.items).map { $0.resourceId() })
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let titleLabel = bottomButton.titleLabel else { return }
        spinner.color = .textColorSecondary
        spinner.translatesAutoresizingMaskIntoConstraints = false
        bottomButton.addSubview(spinner)
        NSLayoutConstraint.activate([spinner.centerYAnchor.constraint(equalTo: bottomButton.centerYAnchor), spinner.trailingAnchor.constraint(equalTo: titleLabel.leadingAnchor, constant: -8)])
    }
    
    override func systemLeftBarButtonItem() -> UIBarButtonItem? {
        UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(onLeftNavbarButtonPressed))
    }
    
    override func getTitle() -> String {
        step == .replace ? String(format: localizedString("free_region_other_title"), region.name) : localizedString("free_region_replace_used_title")
    }
    
    override func getTableHeaderDescription() -> String {
        switch step {
        case .replace:
            String(format: localizedString("free_region_other_descr"), region.name)
        case .email:
            localizedString("free_region_not_eligible_email_descr")
        case .buy:
            String(format: localizedString("free_region_not_eligible_buy_descr"), freeRegion.name, region.name)
        }
    }
    
    override func getBottomColorScheme() -> EOABaseBottomColorScheme {
        .blank
    }
    
    override func isBottomSeparatorVisible() -> Bool {
        false
    }
    
    override func getTopButtonTitle() -> String {
        localizedString("get_unlimited_downloads")
    }
    
    override func getTopButtonColorScheme() -> EOABaseButtonColorScheme {
        isLoading ? .inactive : .purple
    }
    
    override func getBottomButtonTitle() -> String {
        switch step {
        case .replace:
            localizedString("free_region_delete_and_download")
        case .email:
            localizedString("free_region_send_and_replace")
        case .buy:
            ""
        }
    }
    
    override func getBottomButtonColorScheme() -> EOABaseButtonColorScheme {
        isLoading ? .inactive : .graySimple
    }
    
    override func registerCells() {
        addCell(OASimpleTableViewCell.reuseIdentifier)
        addCell(OAInputTableViewCell.reuseIdentifier)
    }
    
    override func generateData() {
        tableData.clearAllData()
        if step == .replace && !mapsToDelete.isEmpty {
            let section = tableData.createNewSection()
            section.headerText = String(format: Self.combineFormat, localizedString("free_region_will_be_deleted"), mapsToDeleteSize)
            section.footerText = localizedString("free_region_maps_stay")
            for map in mapsToDelete {
                for item in map.items {
                    let row = section.createNewRow()
                    row.cellType = OASimpleTableViewCell.reuseIdentifier
                    row.title = map.region.name
                    row.descr = String(format: Self.combineFormat, item.type(), item.formatedSize())
                }
            }
        } else if step == .email {
            let section = tableData.createNewSection()
            section.headerText = localizedString("shared_string_email_address")
            section.footerText = emailFooterText
            section.createNewRow().cellType = OAInputTableViewCell.reuseIdentifier
        }
    }
    
    override func getRow(_ indexPath: IndexPath) -> UITableViewCell? {
        let item = tableData.item(for: indexPath)
        if item.cellType == OAInputTableViewCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: OAInputTableViewCell.reuseIdentifier, for: indexPath) as! OAInputTableViewCell
            cell.selectionStyle = .none
            cell.leftIconVisibility(false)
            cell.titleVisibility(false)
            cell.clearButtonVisibility(false)
            cell.inputField.text = email
            cell.inputField.textAlignment = .natural
            cell.inputField.keyboardType = .emailAddress
            cell.inputField.textContentType = .emailAddress
            cell.inputField.autocapitalizationType = .none
            cell.inputField.autocorrectionType = .no
            cell.inputField.returnKeyType = .done
            cell.inputField.clearButtonMode = .whileEditing
            cell.inputField.accessibilityLabel = localizedString("shared_string_email_address")
            cell.inputField.delegate = self
            cell.inputField.addTarget(self, action: #selector(onEmailChanged(_:)), for: .editingChanged)
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: OASimpleTableViewCell.reuseIdentifier, for: indexPath) as! OASimpleTableViewCell
        cell.selectionStyle = .none
        cell.titleLabel.text = item.title
        cell.descriptionLabel.text = item.descr
        cell.leftIconView.image = .icCustomMapOutline
        cell.leftIconView.tintColor = .iconColorDefault
        return cell
    }
    
    override func onTopButtonPressed() {
        guard let presenter = presentingViewController as? UINavigationController ?? OARootViewController.instance().navigationController else { return }
        dismiss(animated: true) {
            OAChoosePlanHelper.showChoosePlanScreen(with: OAFeature.unlimited_MAP_DOWNLOADS(), navController: presenter)
        }
    }
    
    override func onBottomButtonPressed() {
        guard AFNetworkReachabilityManagerWrapper.isReachable() else {
            OAUtilities.showToast(localizedString("no_inet_connection"), details: nil, duration: 4, in: view)
            return
        }
        
        if step == .email {
            sendEmail()
        } else {
            requestReplace()
        }
    }
    
    private func setStep(_ step: Step) {
        self.step = step
        updateUI()
        UIAccessibility.post(notification: .screenChanged, argument: nil)
    }
    
    private func setLoading(_ loading: Bool) {
        isLoading = loading
        navigationController?.isModalInPresentation = loading
        navigationItem.leftBarButtonItem?.isEnabled = !loading
        tableView.isUserInteractionEnabled = !loading
        updateBottomButtons()
        if loading {
            spinner.startAnimating()
        } else {
            spinner.stopAnimating()
        }
    }
    
    private func setEmailError(_ isShown: Bool) {
        isEmailErrorShown = isShown
        tableData.sectionData(for: 0).footerText = emailFooterText
        tableView.beginUpdates()
        let footer = tableView.footerView(forSection: 0)
        footer?.textLabel?.text = emailFooterText
        footer?.textLabel?.textColor = isShown ? .textColorDisruptive : .textColorSecondary
        footer?.sizeToFit()
        tableView.endUpdates()
        
        if isShown {
            UIAccessibility.post(notification: .announcement, argument: emailFooterText)
        }
    }
    
    private func requestReplace() {
        setLoading(true)
        FreeVersionMapDownloads.shared.requestReplace(from: freeRegion, to: region) { [weak self] answer in
            guard let self else { return }
            self.setLoading(answer == .ok)
            switch answer {
            case .ok:
                self.applyReplace()
            case .requestEmail:
                self.setStep(OAAppSettings.sharedManager().emailSubscribed.get() ? .buy : .email)
            case .no:
                self.setStep(.buy)
            case nil:
                OAUtilities.showToast(localizedString("no_inet_connection"), details: nil, duration: 4, in: self.view)
            }
        }
    }
    
    private func sendEmail() {
        guard isEmailValid else {
            setEmailError(true)
            return
        }
        
        view.endEditing(true)
        setLoading(true)
        FreeVersionMapDownloads.shared.registerEmail(email) { [weak self] registered in
            guard let self else { return }
            if registered {
                self.requestReplace()
            } else {
                self.setLoading(false)
                OAUtilities.showToast(localizedString("shared_string_unexpected_error"), details: nil, duration: 4, in: self.view)
            }
        }
    }
    
    private func applyReplace() {
        let items = mapsToDelete.flatMap(\.items)
        FreeVersionMapDownloads.shared.cancelDownloads(otherThan: region)
        OAResourcesUISwiftHelper.deleteResources(of: items, progressHUD: nil) {
            guard self.mapPaths.count == items.count, self.mapPaths.values.allSatisfy({ access($0, F_OK) == -1 && errno == ENOENT }) else {
                self.setLoading(false)
                OAUtilities.showToast(localizedString("shared_string_unexpected_error"), details: nil, duration: 4, in: self.view)
                return
            }

            FreeVersionMapDownloads.shared.replaceFreeRegion(self.region)
            self.dismiss(animated: true, completion: self.onReplaced)
        }
    }
    
    @objc private func onEmailChanged(_ textField: UITextField) {
        email = (textField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if isEmailErrorShown && isEmailValid {
            setEmailError(false)
        }
    }
}

extension FreeRegionBottomSheet: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        if !email.isEmpty && !isEmailValid {
            setEmailError(true)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
