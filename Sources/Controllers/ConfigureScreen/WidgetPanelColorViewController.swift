//
//  WidgetPanelColorViewController.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 27.08.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

protocol WidgetPanelColorViewControllerDelegate: AnyObject {
    func widgetPanelColorViewControllerDidFinish()
}

final class WidgetPanelColorViewController: OABaseScrollableHudViewController {

    private enum Row: Int, CaseIterable {
        case theme
        case palette
        case allColors
    }

    private enum Constants {
        static let portraitMenuHeight: CGFloat = 404
        static let sheetCornerRadius: CGFloat = 38
        static let floatingButtonSize: CGFloat = 48
        static let floatingButtonInset: CGFloat = 16
        static let applyButtonHeight: CGFloat = 44
        static let paletteVerticalInset: CGFloat = 6
        static let navigationContentHeight: CGFloat = 70
        static let navigationBackgroundFirstAlpha: CGFloat = 0.7
        static let navigationBackgroundSecondAlpha: CGFloat = 0.55
    }

    var navControllerHistory: [UIViewController] = []

    weak var delegate: WidgetPanelColorViewControllerDelegate?

    private let panel: WidgetsPanel
    private let target: WidgetPanelColorTarget
    private let appearanceSettings: WidgetPanelAppearanceSettings
    private let appearanceCollection: OAGPXAppearanceCollection = OAGPXAppearanceCollection.sharedInstance()
    private let mapPanel: OAMapPanelViewController = OARootViewController.instance().mapPanel

    private let closeButton = UIButton(type: .system)
    private let navigationTitleLabel = UILabel()
    private let navigationBackgroundView = UIView()
    private let navigationBackgroundMaskLayer = CAGradientLayer()
    private let previewView = WidgetPanelPreviewView()
    private let titleLabel = UILabel()
    private let applyButton = UIButton(type: .system)

    private let initialDayColor: UIColor
    private let initialNightColor: UIColor
    private let initialTextMode: WidgetPanelTextColorMode?
    private let initialBackgroundMode: WidgetPanelBackgroundMode?

    private var sortedColorItems: [PaletteItemSolid] = []
    private var currentDayColorItem: PaletteItemSolid?
    private var currentNightColorItem: PaletteItemSolid?

    private var isNightColorMode: Bool
    private var isApplied = false
    private var didRestoreNavigation = false
    private var hiddenMapControlStates: [(view: UIView, wasHidden: Bool)] = []

    override var initialMenuHeight: CGFloat {
        if traitCollection.preferredContentSizeCategory.isAccessibilityCategory {
            return min(OAUtilities.calculateScreenHeight() * 0.75,
                       OAUtilities.calculateScreenHeight() - view.safeAreaInsets.top)
        }
        return Constants.portraitMenuHeight
    }

    override var supportsFullScreen: Bool {
        false
    }

    override var useGestureRecognizer: Bool {
        false
    }

    override func isLeftSidePresentation() -> Bool {
        false
    }

    private var isColorSelectionAvailable: Bool {
        target != .background || OAIAPHelper.isMapsPlusAvailable() || OAIAPHelper.isOsmAndProAvailable()
    }

    private var currentColorItem: PaletteItemSolid? {
        isNightColorMode ? currentNightColorItem : currentDayColorItem
    }

    init(appMode: OAApplicationMode,
         panel: WidgetsPanel,
         target: WidgetPanelColorTarget) {
        self.panel = panel
        self.target = target
        appearanceSettings = WidgetPanelAppearanceSettings(appMode: appMode)
        initialDayColor = appearanceSettings.color(for: target, panel: panel, nightMode: false)
        initialNightColor = appearanceSettings.color(for: target, panel: panel, nightMode: true)
        isNightColorMode = OAAppSettings.sharedManager().isAppMapNightMode

        switch target {
        case .primaryText:
            initialTextMode = appearanceSettings.primaryTextColorMode(for: panel)
            initialBackgroundMode = nil
        case .secondaryText:
            initialTextMode = appearanceSettings.secondaryTextColorMode(for: panel)
            initialBackgroundMode = nil
        case .background:
            initialTextMode = nil
            initialBackgroundMode = appearanceSettings.backgroundMode(for: panel)
        }

        super.init(nibName: "OABaseScrollableHudViewController", bundle: nil)
        prepareColors()
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()
        configureSheetHeader()
        configureNavigationBackground()
        configurePreview()
        configureFloatingButtons()
        configureApplyButton()
        applyDraftAndRefreshWidgets()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(onPurchaseStateChanged),
                                               name: Notification.Name(NSNotification.Name.OAIAPProductPurchased.rawValue),
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(onPurchaseStateChanged),
                                               name: Notification.Name(NSNotification.Name.OAIAPProductsRestored.rawValue),
                                               object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        hideMapControls()
        super.viewWillAppear(animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        applyMapTheme()
        DispatchQueue.main.async { [weak self] in
            self?.reloadPreview()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        previewView.releaseHostedWidgets()
        guard !didRestoreNavigation, isMovingFromParent || isBeingDismissed else { return }
        restoreMapControls()
        OADayNightHelper.instance().resetTempMode()
        restoreDraftIfNeeded()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard let previousTraitCollection,
              traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        updateFloatingButtonsBlur()
        tableView.reloadData()
    }

    override func getToolbarHeight() -> CGFloat {
        traitCollection.preferredContentSizeCategory.isAccessibilityCategory ? 76 : 60
    }

    override func doAdditionalLayout() {
        super.doAdditionalLayout()
        applySheetCornerRadius()
        layoutFloatingButtons()
        layoutNavigationBackground()
        layoutPreview()
    }

    override func hide() {
        closeScreen(keepingChanges: false)
    }

    private func prepareColors() {
        currentDayColorItem = colorItem(for: initialDayColor)
        currentNightColorItem = colorItem(for: initialNightColor)
        sortedColorItems = Array(appearanceCollection.getAvailableColorsSortingByLastUsed() ?? [])
    }

    private func colorItem(for color: UIColor) -> PaletteItemSolid? {
        appearanceCollection.getColorItem(withValue: Int32(truncatingIfNeeded: color.toARGBNumber()))
            ?? appearanceCollection.addNewSelectedColor(color)
            ?? appearanceCollection.defaultLineColorItem()
    }

    private func configureTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .viewBg
        tableView.separatorColor = SeparatorAppearance.color
        tableView.sectionHeaderHeight = 8
        tableView.sectionFooterHeight = 0
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 8, right: 0)
        tableView.register(UINib(nibName: SegmentTextTableViewCell.reuseIdentifier, bundle: nil),
                           forCellReuseIdentifier: SegmentTextTableViewCell.reuseIdentifier)
        tableView.register(UINib(nibName: OACollectionSingleLineTableViewCell.reuseIdentifier, bundle: nil),
                           forCellReuseIdentifier: OACollectionSingleLineTableViewCell.reuseIdentifier)
        tableView.register(UINib(nibName: OASimpleTableViewCell.reuseIdentifier, bundle: nil),
                           forCellReuseIdentifier: OASimpleTableViewCell.reuseIdentifier)
        tableView.register(WidgetPanelColorUnavailableCell.self,
                           forCellReuseIdentifier: WidgetPanelColorUnavailableCell.reuseIdentifier)
    }

    private func configureSheetHeader() {
        topHeaderContainerView.backgroundColor = .viewBg
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textColor = .textColorPrimary
        titleLabel.text = target.title
        titleLabel.numberOfLines = 1
        titleLabel.accessibilityTraits = .header
        topHeaderContainerView.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: topHeaderContainerView.leadingAnchor, constant: 32),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: topHeaderContainerView.trailingAnchor, constant: -32),
            titleLabel.centerYAnchor.constraint(equalTo: topHeaderContainerView.centerYAnchor)
        ])
    }

    private func configureNavigationBackground() {
        navigationBackgroundView.backgroundColor = .black
        navigationBackgroundView.isUserInteractionEnabled = false
        navigationBackgroundMaskLayer.startPoint = CGPoint(x: 0.5, y: 0)
        navigationBackgroundMaskLayer.endPoint = CGPoint(x: 0.5, y: 1)
        navigationBackgroundView.layer.mask = navigationBackgroundMaskLayer
        view.insertSubview(navigationBackgroundView, belowSubview: scrollableView)
    }

    private func configurePreview() {
        previewView.backgroundColor = .clear
        view.insertSubview(previewView, belowSubview: scrollableView)
    }

    private func configureFloatingButtons() {
        configureFloatingButton(closeButton,
                                image: .icNavbarClose,
                                accessibilityLabel: localizedString("shared_string_close"),
                                action: #selector(onCloseButtonPressed))
        view.addSubview(closeButton)
        navigationTitleLabel.font = .preferredFont(forTextStyle: .headline)
        navigationTitleLabel.adjustsFontForContentSizeCategory = true
        navigationTitleLabel.text = panel.title
        navigationTitleLabel.textColor = .white
        navigationTitleLabel.textAlignment = .center
        navigationTitleLabel.accessibilityTraits = .header
        view.addSubview(navigationTitleLabel)
        updateFloatingButtonsBlur()
    }

    private func configureFloatingButton(_ button: UIButton,
                                         image: UIImage?,
                                         accessibilityLabel: String,
                                         action: Selector) {
        button.frame.size = CGSize(width: Constants.floatingButtonSize, height: Constants.floatingButtonSize)
        button.setImage(image, for: .normal)
        button.tintColor = .iconColorBlack
        button.accessibilityLabel = accessibilityLabel
        button.accessibilityTraits = .button
        button.addTarget(self, action: action, for: .touchUpInside)
    }

    private func configureApplyButton() {
        applyButton.translatesAutoresizingMaskIntoConstraints = false
        applyButton.setTitle(localizedString("shared_string_apply"), for: .normal)
        applyButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        applyButton.titleLabel?.adjustsFontForContentSizeCategory = true
        applyButton.backgroundColor = .buttonBgColorPrimary
        applyButton.setTitleColor(.buttonTextColorPrimary, for: .normal)
        applyButton.setTitleColor(.textColorSecondary, for: .disabled)
        applyButton.layer.cornerRadius = 10
        applyButton.accessibilityTraits = .button
        applyButton.addTarget(self, action: #selector(onApplyButtonPressed), for: .touchUpInside)
        toolBarView.addSubview(applyButton)
        NSLayoutConstraint.activate([
            applyButton.leadingAnchor.constraint(equalTo: toolBarView.leadingAnchor, constant: 16),
            applyButton.trailingAnchor.constraint(equalTo: toolBarView.trailingAnchor, constant: -16),
            applyButton.topAnchor.constraint(equalTo: toolBarView.topAnchor),
            applyButton.heightAnchor.constraint(greaterThanOrEqualToConstant: Constants.applyButtonHeight)
        ])
        updateApplyButtonAvailability()
    }

    private func updateApplyButtonAvailability() {
        let isAvailable = isColorSelectionAvailable
        applyButton.isEnabled = isAvailable
        applyButton.backgroundColor = isAvailable ? .buttonBgColorPrimary : .buttonBgColorDisabled
        applyButton.alpha = 1
        toolBarView.isHidden = false
    }

    private func updateFloatingButtonsBlur() {
        let isLightTheme = ThemeManager.shared.isLightTheme()
        closeButton.addBlurEffect(isLightTheme, cornerRadius: Constants.floatingButtonSize / 2, padding: 0)
    }

    private func layoutFloatingButtons() {
        let top = view.safeAreaInsets.top + 8
        let left = view.safeAreaInsets.left + Constants.floatingButtonInset
        let reservedTrailingButtonOrigin = view.bounds.width - view.safeAreaInsets.right - Constants.floatingButtonInset
            - Constants.floatingButtonSize
        closeButton.frame = CGRect(x: left,
                                   y: top,
                                   width: Constants.floatingButtonSize,
                                   height: Constants.floatingButtonSize)
        navigationTitleLabel.frame = CGRect(x: closeButton.frame.maxX + 12,
                                            y: top,
                                            width: max(0, reservedTrailingButtonOrigin - closeButton.frame.maxX - 24),
                                            height: Constants.floatingButtonSize)
    }

    private func layoutNavigationBackground() {
        let isCompactLayout = traitCollection.verticalSizeClass == .compact
        navigationBackgroundView.isHidden = isCompactLayout
        guard !isCompactLayout else { return }
        navigationBackgroundView.frame = CGRect(x: 0,
                                                y: 0,
                                                width: view.bounds.width,
                                                height: view.safeAreaInsets.top + Constants.navigationContentHeight)
        navigationBackgroundMaskLayer.frame = navigationBackgroundView.bounds
        navigationBackgroundMaskLayer.colors = [
            UIColor.black.withAlphaComponent(Constants.navigationBackgroundFirstAlpha).cgColor,
            UIColor.black.withAlphaComponent(Constants.navigationBackgroundSecondAlpha).cgColor,
            UIColor.clear.cgColor
        ]
    }

    private func layoutPreview() {
        let top = view.safeAreaInsets.top + Constants.navigationContentHeight
        previewView.frame = CGRect(x: 0,
                                   y: top,
                                   width: view.bounds.width,
                                   height: max(0, scrollableView.frame.minY - top))
    }

    private func applySheetCornerRadius() {
        guard !isLeftSidePresentation() else {
            scrollableView.layer.mask = nil
            return
        }
        let cornerSize = CGSize(width: Constants.sheetCornerRadius, height: Constants.sheetCornerRadius)
        let path = UIBezierPath(roundedRect: scrollableView.bounds,
                                byRoundingCorners: [.topLeft, .topRight],
                                cornerRadii: cornerSize)
        let mask = CAShapeLayer()
        mask.frame = scrollableView.bounds
        mask.path = path.cgPath
        scrollableView.layer.mask = mask
    }

    private func applyMapTheme() {
        OADayNightHelper.instance().setTempMode(Int((isNightColorMode ? DayNightMode.night : .day).rawValue))
    }

    private func applyDraftAndRefreshWidgets() {
        previewView.releaseHostedWidgets()
        applyPreviewPanelVisibility()
        guard isColorSelectionAvailable,
              let dayColor = currentDayColorItem.map({ UIColor(argb: Int($0.colorInt)) }),
              let nightColor = currentNightColorItem.map({ UIColor(argb: Int($0.colorInt)) }) else {
            return
        }
        appearanceSettings.setColor(dayColor, for: target, panel: panel, nightMode: false)
        appearanceSettings.setColor(nightColor, for: target, panel: panel, nightMode: true)
        setCustomMode()
        mapPanel.recreateControls()
        applyPreviewPanelVisibility()
        reloadPreviewIfVisible()
    }

    private func reloadPreview() {
        applyPreviewPanelVisibility()
        previewView.configure(panel: panel, parentViewController: self)
    }

    private func reloadPreviewIfVisible() {
        guard viewIfLoaded?.window != nil else { return }
        reloadPreview()
    }

    private func applyPreviewPanelVisibility() {
        guard let mapInfoController = mapPanel.hudViewController?.mapInfoController else { return }
        mapInfoController.leftPanelController.view.isHidden = panel != .leftPanel
        mapInfoController.rightPanelController.view.isHidden = panel != .rightPanel
        mapInfoController.topPanelController.view.isHidden = panel != .topPanel
        mapInfoController.bottomPanelController.view.isHidden = panel != .bottomPanel
    }

    private func hideMapControls() {
        guard hiddenMapControlStates.isEmpty,
              let hudViewController = mapPanel.hudViewController else { return }
        let controls = mapButtons(in: hudViewController.view)
        hiddenMapControlStates = controls.map { view in
            (view: view, wasHidden: view.isHidden)
        }
        hiddenMapControlStates.forEach { $0.view.isHidden = true }
    }

    private func mapButtons(in rootView: UIView) -> [OAHudButton] {
        var result: [OAHudButton] = []
        func collect(from view: UIView) {
            if let button = view as? OAHudButton {
                result.append(button)
                return
            }
            view.subviews.forEach { collect(from: $0) }
        }
        collect(from: rootView)
        return result
    }

    private func restoreMapControls() {
        guard !hiddenMapControlStates.isEmpty else { return }
        hiddenMapControlStates.forEach { $0.view.isHidden = $0.wasHidden }
        hiddenMapControlStates.removeAll()
        mapPanel.hudViewController?.updateControlsLayout(false)
        mapPanel.hudViewController?.updateDependentButtonsVisibility()
    }

    private func setCustomMode() {
        switch target {
        case .primaryText:
            appearanceSettings.setTextColorMode(.custom, kind: .primary, for: panel)
        case .secondaryText:
            appearanceSettings.setTextColorMode(.custom, kind: .secondary, for: panel)
        case .background:
            appearanceSettings.setBackgroundMode(.custom, for: panel)
        }
    }

    private func restoreDraftIfNeeded() {
        guard !isApplied else { return }
        previewView.releaseHostedWidgets()
        appearanceSettings.setColor(initialDayColor, for: target, panel: panel, nightMode: false)
        appearanceSettings.setColor(initialNightColor, for: target, panel: panel, nightMode: true)
        if let initialTextMode {
            let kind: WidgetPanelTextColorKind = target == .primaryText ? .primary : .secondary
            appearanceSettings.setTextColorMode(initialTextMode, kind: kind, for: panel)
        }
        if let initialBackgroundMode {
            appearanceSettings.setBackgroundMode(initialBackgroundMode, for: panel)
        }
        mapPanel.recreateControls()
    }

    private func closeScreen(keepingChanges: Bool) {
        guard !didRestoreNavigation else { return }
        didRestoreNavigation = true
        isApplied = keepingChanges
        previewView.releaseHostedWidgets()
        OADayNightHelper.instance().resetTempMode()
        if !keepingChanges {
            restoreDraftIfNeeded()
        } else {
            mapPanel.recreateControls()
        }
        hide(true, duration: 0.2) { [weak self] in
            guard let self else { return }
            self.mapPanel.hideScrollableHudViewController()
            self.restoreMapControls()
            if let navigationController = OARootViewController.instance().navigationController,
               !self.navControllerHistory.isEmpty {
                navigationController.setViewControllers(self.navControllerHistory, animated: true)
            }
            self.delegate?.widgetPanelColorViewControllerDidFinish()
        }
    }

    private func refreshSelectedPalette() {
        guard let cell = tableView.cellForRow(at: IndexPath(row: Row.palette.rawValue, section: 0))
                as? OACollectionSingleLineTableViewCell,
              let handler = cell.getCollectionHandler() as? OAColorCollectionHandler,
              let currentColorItem else { return }
        let index = appearanceCollection.index(ofColorItem: currentColorItem, items: sortedColorItems)
        if index != NSNotFound {
            handler.setSelectedIndexPath(IndexPath(row: index, section: 0))
            cell.collectionView.reloadData()
        }
    }

    private func setSelectedColorItem(_ colorItem: PaletteItemSolid) {
        if isNightColorMode {
            currentNightColorItem = colorItem
        } else {
            currentDayColorItem = colorItem
        }
        applyDraftAndRefreshWidgets()
        refreshSelectedPalette()
    }

    @objc private func onCloseButtonPressed() {
        closeScreen(keepingChanges: false)
    }

    @objc private func onApplyButtonPressed() {
        guard isColorSelectionAvailable else { return }
        applyDraftAndRefreshWidgets()
        closeScreen(keepingChanges: true)
    }

    @objc private func onAddColorPressed(_ sender: UIButton) {
        guard let activeItem = currentColorItem else { return }
        let colorPicker = UIColorPickerViewController()
        colorPicker.delegate = self
        colorPicker.selectedColor = UIColor(argb: Int(activeItem.colorInt))
        colorPicker.supportsAlpha = target == .background
        colorPicker.popoverPresentationController?.sourceView = sender
        present(colorPicker, animated: true)
    }

    @objc private func onPurchaseStateChanged() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.updateApplyButtonAvailability()
            self.applyDraftAndRefreshWidgets()
            self.tableView.reloadData()
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension WidgetPanelColorViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in _: UITableView) -> Int {
        1
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        isColorSelectionAvailable ? Row.allCases.count : 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard isColorSelectionAvailable else {
            let cell = tableView.dequeueReusableCell(withIdentifier: WidgetPanelColorUnavailableCell.reuseIdentifier,
                                                     for: indexPath) as? WidgetPanelColorUnavailableCell
            cell?.configure(action: { [weak self] in
                guard let navigationController = OARootViewController.instance().navigationController else { return }
                OAChoosePlanHelper.showChoosePlanScreen(with: OAFeature.unlimited_MAP_DOWNLOADS(),
                                                        navController: navigationController)
                self?.view.accessibilityViewIsModal = false
            })
            return cell ?? UITableViewCell()
        }

        guard let row = Row(rawValue: indexPath.row) else { return UITableViewCell() }
        switch row {
        case .theme:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: SegmentTextTableViewCell.reuseIdentifier,
                                                           for: indexPath) as? SegmentTextTableViewCell else {
                return UITableViewCell()
            }
            cell.selectionStyle = .none
            cell.backgroundColor = .groupBg
            cell.configureSegmentedControl(titles: [localizedString("day"),
                                                     localizedString("daynight_mode_night")],
                                           selectedSegmentIndex: isNightColorMode ? 1 : 0)
            cell.setSegmentedControlBottomSpacing(8)
            cell.didSelectSegmentIndex = { [weak self] index in
                guard let self else { return }
                self.isNightColorMode = index == 1
                self.applyMapTheme()
                self.previewView.releaseHostedWidgets()
                self.mapPanel.recreateControls()
                self.reloadPreview()
                self.tableView.reloadRows(at: [IndexPath(row: Row.palette.rawValue, section: 0)], with: .none)
            }
            return cell
        case .palette:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: OACollectionSingleLineTableViewCell.reuseIdentifier,
                                                           for: indexPath) as? OACollectionSingleLineTableViewCell else {
                return UITableViewCell()
            }
            cell.backgroundColor = .groupBg
            // Keep the 48 pt selection ring inside the 60 pt row. The shared
            // cell uses a 9 pt bottom spacer by default, which leaves only
            // 45 pt for the collection view and clips the ring vertically.
            cell.configureTopOffset(Constants.paletteVerticalInset)
            cell.configureBottomOffset(Constants.paletteVerticalInset)
            cell.rightActionButtonVisibility(true)
            cell.rightActionButton.setImage(.icCustomAdd, for: .normal)
            cell.rightActionButton.tintColor = .iconColorActive
            cell.rightActionButton.accessibilityLabel = localizedString("shared_string_add_color")
            cell.rightActionButton.removeTarget(nil, action: nil, for: .allEvents)
            cell.rightActionButton.addTarget(self, action: #selector(onAddColorPressed(_:)), for: .touchUpInside)
            let handler = OAColorCollectionHandler(data: [sortedColorItems], collectionView: cell.collectionView)
            handler?.delegate = self
            handler?.hostVC = self
            if let currentColorItem {
                let index = appearanceCollection.index(ofColorItem: currentColorItem, items: sortedColorItems)
                if index != NSNotFound {
                    handler?.setSelectedIndexPath(IndexPath(row: index, section: 0))
                }
            }
            cell.setCollectionHandler(handler)
            configurePaletteInsets(for: cell.collectionView)
            return cell
        case .allColors:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: OASimpleTableViewCell.reuseIdentifier,
                                                           for: indexPath) as? OASimpleTableViewCell else {
                return UITableViewCell()
            }
            cell.leftIconVisibility(false)
            cell.descriptionVisibility(false)
            cell.titleVisibility(true)
            cell.titleLabel.text = localizedString("shared_string_all_colors")
            cell.titleLabel.textColor = .textColorActive
            cell.titleLabel.font = .preferredFont(forTextStyle: .body)
            cell.accessoryType = .disclosureIndicator
            cell.selectionStyle = .default
            cell.accessibilityLabel = cell.titleLabel.text
            cell.accessibilityTraits = .button
            return cell
        }
    }

    func tableView(_: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if traitCollection.preferredContentSizeCategory.isAccessibilityCategory {
            return UITableView.automaticDimension
        }
        guard isColorSelectionAvailable, let row = Row(rawValue: indexPath.row) else {
            return UITableView.automaticDimension
        }
        switch row {
        case .theme: return 52
        case .palette: return 60
        case .allColors: return 52
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard isColorSelectionAvailable,
              Row(rawValue: indexPath.row) == .allColors,
              let currentColorItem else { return }
        let controller = ItemsCollectionViewController(collectionType: .colorItems,
                                                       items: sortedColorItems,
                                                       selectedItem: currentColorItem)
        controller.delegate = self
        if let colorCell = tableView.cellForRow(at: IndexPath(row: Row.palette.rawValue, section: 0))
                as? OACollectionSingleLineTableViewCell,
           let colorHandler = colorCell.getCollectionHandler() as? OAColorCollectionHandler {
            controller.hostColorHandler = colorHandler
        }
        showMediumToLargeSheetViewController(controller)
    }

    private func configurePaletteInsets(for collectionView: UICollectionView) {
        DispatchQueue.main.async { [weak collectionView] in
            guard let collectionView,
                  let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }
            collectionView.contentInset = .zero
            layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
            layout.invalidateLayout()
        }
    }
}

extension WidgetPanelColorViewController: OACollectionCellDelegate {
    func onCollectionItemSelected(_ indexPath: IndexPath,
                                  selectedItem: Any?,
                                  collectionView _: UICollectionView?,
                                  shouldDismiss _: Bool) {
        guard sortedColorItems.indices.contains(indexPath.row) else { return }
        let colorItem = selectedItem as? PaletteItemSolid ?? sortedColorItems[indexPath.row]
        if selectedItem is PaletteItemSolid {
            sortedColorItems[indexPath.row] = colorItem
        }
        setSelectedColorItem(colorItem)
    }

    func reloadCollectionData() {
        sortedColorItems = Array(appearanceCollection.getAvailableColorsSortingByLastUsed() ?? [])
        tableView.reloadRows(at: [IndexPath(row: Row.palette.rawValue, section: 0)], with: .none)
    }
}

extension WidgetPanelColorViewController: ColorCollectionViewControllerDelegate {
    func selectColorItem(_ colorItem: PaletteItemSolid) {
        let index = appearanceCollection.index(ofColorItem: colorItem, items: sortedColorItems)
        if index == NSNotFound {
            sortedColorItems.insert(colorItem, at: 0)
        }
        setSelectedColorItem(colorItem)
    }

    @discardableResult func addAndGetNewColorItem(_ color: UIColor) -> PaletteItemSolid {
        guard let item = appearanceCollection.addNewSelectedColor(color) else {
            return appearanceCollection.defaultLineColorItem()
        }
        sortedColorItems.insert(item, at: 0)
        setSelectedColorItem(item)
        tableView.reloadRows(at: [IndexPath(row: Row.palette.rawValue, section: 0)], with: .none)
        return item
    }

    func changeColorItem(_ colorItem: PaletteItemSolid, withColor color: UIColor) {
        let index = appearanceCollection.index(ofColorItem: colorItem, items: sortedColorItems)
        guard index != NSNotFound, let changed = appearanceCollection.changeColor(colorItem, newColor: color) else { return }
        sortedColorItems[index] = changed
        if appearanceCollection.isSameColorItem(currentColorItem, secondItem: colorItem) {
            setSelectedColorItem(changed)
        }
    }

    func duplicateColorItem(_ colorItem: PaletteItemSolid) -> PaletteItemSolid {
        guard let duplicate = appearanceCollection.duplicateColor(colorItem) else { return colorItem }
        let index = appearanceCollection.index(ofColorItem: colorItem, items: sortedColorItems)
        sortedColorItems.insert(duplicate, at: index == NSNotFound ? 0 : index + 1)
        return duplicate
    }

    func deleteColorItem(_ colorItem: PaletteItemSolid) {
        let index = appearanceCollection.index(ofColorItem: colorItem, items: sortedColorItems)
        guard index != NSNotFound else { return }
        appearanceCollection.deleteColor(colorItem)
        sortedColorItems.remove(at: index)
        tableView.reloadRows(at: [IndexPath(row: Row.palette.rawValue, section: 0)], with: .none)
    }
}

extension WidgetPanelColorViewController: UIColorPickerViewControllerDelegate {
    func colorPickerViewController(_: UIColorPickerViewController, didSelect color: UIColor, continuously _: Bool) {
        guard OAUtilities.isiOSAppOnMac() else { return }
        _ = addAndGetNewColorItem(color)
    }

    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        _ = addAndGetNewColorItem(viewController.selectedColor)
    }
}

private extension WidgetPanelColorTarget {
    var title: String {
        switch self {
        case .primaryText: localizedString("text_color")
        case .secondaryText: localizedString("secondary_text_color")
        case .background: localizedString("background_color")
        }
    }
}

private final class WidgetPanelColorUnavailableCell: UITableViewCell {

    private let topSeparatorView = UIView()
    private let iconView = UIImageView(image: .icCustomWidgetColored)
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let actionSeparatorView = UIView()
    private let actionButton = UIButton(type: .system)
    private var action: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureViews()
    }

    required init?(coder: NSCoder) {
        nil
    }

    func configure(action: @escaping () -> Void) {
        self.action = action
    }

    private func configureViews() {
        selectionStyle = .none
        backgroundColor = .groupBg

        topSeparatorView.translatesAutoresizingMaskIntoConstraints = false
        topSeparatorView.backgroundColor = SeparatorAppearance.color

        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.contentMode = .scaleAspectFit
        iconView.isAccessibilityElement = false

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = localizedString("custom_widget_colors")
        titleLabel.textColor = .textColorPrimary
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .natural
        titleLabel.accessibilityTraits = .header

        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.text = localizedString("custom_widget_colors_description")
        descriptionLabel.textColor = .textColorSecondary
        descriptionLabel.font = .preferredFont(forTextStyle: .footnote)
        descriptionLabel.adjustsFontForContentSizeCategory = true
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textAlignment = .natural

        actionSeparatorView.translatesAutoresizingMaskIntoConstraints = false
        actionSeparatorView.backgroundColor = SeparatorAppearance.color

        actionButton.translatesAutoresizingMaskIntoConstraints = false
        actionButton.setTitle(localizedString("unlock_custom_colors"), for: .normal)
        actionButton.setTitleColor(.textColorActive, for: .normal)
        actionButton.contentHorizontalAlignment = .leading
        actionButton.titleLabel?.font = .preferredFont(forTextStyle: .body)
        actionButton.titleLabel?.adjustsFontForContentSizeCategory = true
        actionButton.addTarget(self, action: #selector(onActionPressed), for: .touchUpInside)

        contentView.addSubview(topSeparatorView)
        contentView.addSubview(iconView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(descriptionLabel)
        contentView.addSubview(actionSeparatorView)
        contentView.addSubview(actionButton)
        NSLayoutConstraint.activate([
            topSeparatorView.topAnchor.constraint(equalTo: contentView.topAnchor),
            topSeparatorView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            topSeparatorView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            topSeparatorView.heightAnchor.constraint(equalToConstant: 1),

            titleLabel.topAnchor.constraint(equalTo: topSeparatorView.bottomAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: iconView.leadingAnchor, constant: -16),

            iconView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            iconView.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24),

            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            descriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            actionSeparatorView.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 16),
            actionSeparatorView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            actionSeparatorView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            actionSeparatorView.heightAnchor.constraint(equalToConstant: 1),

            actionButton.topAnchor.constraint(equalTo: actionSeparatorView.bottomAnchor),
            actionButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            actionButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            actionButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            actionButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 52)
        ])

        isAccessibilityElement = false
        accessibilityElements = [titleLabel, descriptionLabel, actionButton]
    }

    @objc private func onActionPressed() {
        action?()
    }
}
