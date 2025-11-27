//
//  BaseSettingsParametersViewController.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 29.10.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

class BaseSettingsParametersViewController: OABaseScrollableHudViewController {
    
    @IBOutlet weak var cancelButtonContainerView: UIView!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var cancelButtonLeadingConstraint: NSLayoutConstraint!

    @IBOutlet weak var resetButtonContainerView: UIView!
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var resetButtonTrailingConstraint: NSLayoutConstraint!

    let mapPanel: OAMapPanelViewController = OARootViewController.instance().mapPanel
    let hideDuration: TimeInterval = 0.2
    let settings: OAAppSettings = OAAppSettings.sharedManager()
    
    var applyButton = UIButton(type: .system)
    var tableData = OATableDataModel()
    
    override var initialMenuHeight: CGFloat {
        OAUtilities.calculateScreenHeight() / 2 + OAUtilities.getBottomMargin()
    }

    override var supportsFullScreen: Bool {
        false
    }

    override var useGestureRecognizer: Bool {
        false
    }

    private let applyButtonFontSize: CGFloat = 15.0
    private let applyButtonCornerRadius: CGFloat = 10
    private let applyButtonHorizontalMargin: CGFloat = 20
    private let applyButtonHeight: CGFloat = 44
    private let additionalOffset: CGFloat = 10
    private let buttonDefaultPadding = 13.0
    private let buttonCornerRadius: CGFloat = 12
    private let buttonPadding: CGFloat = 0
    
    init() {
        super.init(nibName: "BaseSettingsParametersViewController", bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        applyLocalization()
        registerCells()
        generateData()

        resetButton.setImage(.icCustomReset, for: .normal)
        let isLightTheme = ThemeManager.shared.isLightTheme()
        resetButton.addBlurEffect(isLightTheme, cornerRadius: buttonCornerRadius, padding: buttonPadding)
        cancelButton.addBlurEffect(isLightTheme, cornerRadius: buttonCornerRadius, padding: buttonPadding)

        tableView.delegate = self
        tableView.dataSource = self

        setupBottomButton()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        let statusBarStyle = settings.nightMode ? UIStatusBarStyle.lightContent : UIStatusBarStyle.default
        mapPanel.targetUpdateControlsLayout(true, customStatusBarStyle: statusBarStyle)
    }

    override func hide(_ animated: Bool, duration: TimeInterval, onComplete: (() -> Void)!) {
        super.hide(animated, duration: duration) { [weak self] in
            guard let self else { return }

            mapPanel.hideScrollableHudViewController()
            onComplete()
        }
    }
    
    override func doAdditionalLayout() {
        let isRTL = cancelButtonContainerView.isDirectionRTL()
        let landscapeWidthAdjusted = getLandscapeViewWidth() - OAUtilities.getLeftMargin() + additionalOffset
        let commonMargin = OAUtilities.getLeftMargin() + additionalOffset
        
        cancelButtonLeadingConstraint.constant = isLandscape() ? (isRTL ? buttonDefaultPadding : landscapeWidthAdjusted) : commonMargin
        resetButtonTrailingConstraint.constant = isLandscape() ? (isRTL ? landscapeWidthAdjusted : buttonDefaultPadding) : commonMargin
    }

    override func getToolbarHeight() -> CGFloat {
        50
    }
    
    func updateModeUI() {
        // Overrides in child class
    }
    
    func updateModeUI(isValueChanged: Bool, animated: Bool) {
        applyButton.backgroundColor = isValueChanged ? .buttonBgColorPrimary : .buttonBgColorSecondary
        applyButton.setTitleColor(isValueChanged ? .buttonTextColorPrimary : .lightGray, for: .normal)
        applyButton.isUserInteractionEnabled = isValueChanged
        resetButton.isEnabled = isValueChanged

        tableView.reloadSections(IndexSet(integer: 0), with: animated ? .automatic : .none)
    }

    func registerCells() {
        // Overrides in child class
    }
    
    func generateData() {
        tableData.clearAllData()
    }
    
    func createSectionWithName() -> OATableSectionData {
        let section = tableData.createNewSection()
        section.headerText = headerName()
        return section
    }
    
    func headerName() -> String {
        ""
    }
    
    private func applyLocalization() {
        cancelButton.setTitle(localizedString("shared_string_cancel"), for: .normal)
    }
    
    private func setupBottomButton() {
        applyButton.setTitle(localizedString("shared_string_apply"), for: .normal)
        applyButton.titleLabel?.font = .systemFont(ofSize: applyButtonFontSize, weight: .semibold)
        applyButton.layer.cornerRadius = applyButtonCornerRadius
        applyButton.translatesAutoresizingMaskIntoConstraints = false
        applyButton.addTarget(self, action: #selector(onApplyButtonPressed), for: .touchUpInside)
        updateModeUI()
        toolBarView.addSubview(applyButton)

        NSLayoutConstraint.activate([
            applyButton.centerXAnchor.constraint(equalTo: toolBarView.centerXAnchor),
            applyButton.topAnchor.constraint(equalTo: toolBarView.topAnchor),
            applyButton.leadingAnchor.constraint(equalTo: toolBarView.leadingAnchor, constant: applyButtonHorizontalMargin),
            applyButton.trailingAnchor.constraint(equalTo: toolBarView.trailingAnchor, constant: -applyButtonHorizontalMargin),
            applyButton.heightAnchor.constraint(equalToConstant: applyButtonHeight)
        ])
    }
    
    @objc func onApplyButtonPressed() {
        hide()
    }
    
    @IBAction func cancelButtonPressed() {
        hide()
    }

    @IBAction func resetButtonPressed() {
        generateData()
        tableView.reloadData()
    }
}

extension BaseSettingsParametersViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        Int(tableData.rowCount(UInt(section)))
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        Int(tableData.sectionCount())
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        tableData.sectionData(for: UInt(section)).headerText
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        UITableViewCell()
    }
}
