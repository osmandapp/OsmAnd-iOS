//
//  WidgetsAppearanceViewController.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 14.08.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

final class WidgetsAppearanceViewController: OABaseNavbarSubviewViewController {

    private enum RowKey: String {
        case size
        case icon
        case primaryTextColor
        case secondaryTextColor
        case backgroundColor
        case reset
    }

    private enum Constants {
        static let previewHeight: CGFloat = 250
        static let previewVerticalPadding: CGFloat = 16
        static let rowHeight: CGFloat = 52
        static let panelIconNames = [
            "ic_custom20_screen_side_left",
            "ic_custom20_screen_side_right",
            "ic_custom20_screen_side_top",
            "ic_custom20_screen_side_bottom"
        ]
    }

    private let appMode: OAApplicationMode
    private let panels = WidgetsPanel.values
    private let appearanceSettings: WidgetPanelAppearanceSettings
    private let previewView = WidgetsAppearancePreviewView()

    private lazy var previewHeaderView = UIView()
    private var selectedPanel: WidgetsPanel

    init(appMode: OAApplicationMode, initialPanel: WidgetsPanel = .leftPanel) {
        self.appMode = appMode
        selectedPanel = initialPanel
        appearanceSettings = WidgetPanelAppearanceSettings(appMode: appMode)
        super.init()
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configurePreviewHeader()
        tableView.backgroundColor = .viewBg
        tableView.separatorColor = SeparatorAppearance.color
        tableView.sectionHeaderTopPadding = 8
        tableView.estimatedRowHeight = Constants.rowHeight
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        reloadPreview()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let size = CGSize(width: tableView.bounds.width,
                          height: Constants.previewHeight + Constants.previewVerticalPadding * 2)
        if previewHeaderView.frame.size != size || tableView.tableHeaderView !== previewHeaderView {
            previewHeaderView.frame.size = size
            tableView.tableHeaderView = previewHeaderView
        }
    }

    override func getTitle() -> String {
        selectedPanel.title
    }

    override func getRightNavbarButtons() -> [UIBarButtonItem] {
        let button = UIBarButtonItem(
            image: UIImage(resource: .icCustomOverflowMenuStroke),
            style: .plain,
            target: self,
            action: #selector(showCopyFrom)
        )

        button.tintColor = navbarButtonsTintColor()
        button.accessibilityLabel = localizedString("shared_string_options")

        return [button]
    }

    override func createSubview() -> UIView? {
        let icons = zip(Constants.panelIconNames, panels).compactMap { iconName, panel -> UIImage? in
            guard let image = UIImage(named: iconName) else { return nil }
            image.accessibilityLabel = panel.title
            return image
        }
        let segmentedControl = UISegmentedControl(items: icons)
        segmentedControl.selectedSegmentIndex = panels.firstIndex(of: selectedPanel) ?? 0
        segmentedControl.addTarget(self, action: #selector(onPanelChanged(_:)), for: .valueChanged)
        return segmentedControl
    }

    override func isNavbarSeparatorVisible() -> Bool {
        false
    }

    override func tableStyle() -> UITableView.Style {
        .insetGrouped
    }

    override func useCustomTableViewHeader() -> Bool {
        true
    }

    override func hideFirstHeader() -> Bool {
        true
    }

    override func registerCells() {
        tableView.register(WidgetsAppearanceOptionCell.self,
                           forCellReuseIdentifier: WidgetsAppearanceOptionCell.reuseIdentifier)
    }

    override func generateData() {
        tableData.clearAllData()

        let parametersSection = tableData.createNewSection()
        parametersSection.footerText = String(format: localizedString("panel_appearance_original_description"),
                                              localizedString("shared_string_original"))
        addRow(to: parametersSection,
               key: .size,
               title: localizedString(selectedPanel.isPanelVertical ? "row_height" : "widget_height"))
        addRow(to: parametersSection,
               key: .icon,
               title: localizedString("shared_string_icon"))

        let appearanceSection = tableData.createNewSection()
        appearanceSection.headerText = localizedString("shared_string_appearance")
        addRow(to: appearanceSection,
               key: .primaryTextColor,
               title: localizedString("text_color"))
        addRow(to: appearanceSection,
               key: .secondaryTextColor,
               title: localizedString("secondary_text_color"))
        addRow(to: appearanceSection,
               key: .backgroundColor,
               title: localizedString("background_color"))

        let resetSection = tableData.createNewSection()
        addRow(to: resetSection,
               key: .reset,
               title: localizedString("reset_to_default"))
    }

    override func getRow(_ indexPath: IndexPath) -> UITableViewCell? {
        let item = tableData.item(for: indexPath)
        guard let keyValue = item.key,
              let key = RowKey(rawValue: keyValue),
              let cell = tableView.dequeueReusableCell(withIdentifier: WidgetsAppearanceOptionCell.reuseIdentifier,
                                                       for: indexPath) as? WidgetsAppearanceOptionCell else {
            return nil
        }
        let title = item.title ?? ""
        let nightMode = OAAppSettings.sharedManager().nightMode
        let resolvedAppearance = WidgetPanelAppearanceResolver.resolve(panel: selectedPanel,
                                                                       appMode: appMode,
                                                                       nightMode: nightMode)

        switch key {
        case .size:
            let mode = appearanceSettings.sizeMode(for: selectedPanel)
            cell.configure(title: title,
                           preview: .image(mode.icon, .iconColorActive),
                           value: mode.title,
                           menu: createSizeMenu())
        case .icon:
            let mode = appearanceSettings.iconMode(for: selectedPanel)
            cell.configure(title: title,
                           preview: .image(.icCustomInfoFilled, .iconColorActive),
                           value: mode.title,
                           menu: createIconMenu())
        case .primaryTextColor:
            let mode = appearanceSettings.primaryTextColorMode(for: selectedPanel)
            cell.configure(title: title,
                           preview: .text(resolvedAppearance.primaryTextColor,
                                          resolvedAppearance.backgroundColor),
                           value: mode.title,
                           menu: createTextColorMenu(kind: .primary))
        case .secondaryTextColor:
            let mode = appearanceSettings.secondaryTextColorMode(for: selectedPanel)
            cell.configure(title: title,
                           preview: .text(resolvedAppearance.secondaryTextColor,
                                          resolvedAppearance.backgroundColor),
                           value: mode.title,
                           menu: createTextColorMenu(kind: .secondary))
        case .backgroundColor:
            let mode = appearanceSettings.backgroundMode(for: selectedPanel)
            cell.configure(title: title,
                           preview: .color(resolvedAppearance.backgroundColor),
                           value: mode.title,
                           menu: createBackgroundMenu())
        case .reset:
            cell.configureReset(title: title)
        }
        return cell
    }

    override func onRowSelected(_ indexPath: IndexPath) {
        let item = tableData.item(for: indexPath)
        guard item.key == RowKey.reset.rawValue else { return }
        tableView.deselectRow(at: indexPath, animated: true)
        appearanceSettings.reset(panel: selectedPanel)
        recreateWidgetsAndReload()
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        traitCollection.preferredContentSizeCategory.isAccessibilityCategory
            ? UITableView.automaticDimension
            : Constants.rowHeight
    }

    private func addRow(to section: OATableSectionData, key: RowKey, title: String) {
        let row = section.createNewRow()
        row.cellType = WidgetsAppearanceOptionCell.reuseIdentifier
        row.key = key.rawValue
        row.title = title
        row.accessibilityLabel = title
    }

    private func configurePreviewHeader() {
        previewHeaderView.frame = CGRect(x: 0,
                                         y: 0,
                                         width: tableView.bounds.width,
                                         height: Constants.previewHeight + Constants.previewVerticalPadding * 2)
        previewHeaderView.backgroundColor = .clear
        previewHeaderView.accessibilityElementsHidden = true
        previewView.translatesAutoresizingMaskIntoConstraints = false
        previewHeaderView.addSubview(previewView)
        NSLayoutConstraint.activate([
            previewView.leadingAnchor.constraint(equalTo: previewHeaderView.leadingAnchor),
            previewView.trailingAnchor.constraint(equalTo: previewHeaderView.trailingAnchor),
            previewView.topAnchor.constraint(equalTo: previewHeaderView.topAnchor,
                                             constant: Constants.previewVerticalPadding),
            previewView.heightAnchor.constraint(equalToConstant: Constants.previewHeight)
        ])
        tableView.tableHeaderView = previewHeaderView
        reloadPreview()
    }

    private func createSizeMenu() -> UIMenu {
        let selectedMode = appearanceSettings.sizeMode(for: selectedPanel)
        let actions = WidgetPanelSizeMode.allCases.map { mode in
            UIAction(title: mode.title,
                     image: mode.icon,
                     state: mode == selectedMode ? .on : .off) { [weak self] _ in
                guard let self else { return }
                appearanceSettings.setSizeMode(mode, for: selectedPanel)
                applySizeMode(mode)
                recreateWidgetsAndRefresh(row: .size)
            }
        }
        return UIMenu(options: .singleSelection, children: actions)
    }

    private func createIconMenu() -> UIMenu {
        let selectedMode = appearanceSettings.iconMode(for: selectedPanel)
        let actions = WidgetPanelIconMode.allCases.map { mode in
            UIAction(title: mode.title,
                     state: mode == selectedMode ? .on : .off) { [weak self] _ in
                guard let self else { return }
                appearanceSettings.setIconMode(mode, for: selectedPanel)
                applyIconMode(mode)
                recreateWidgetsAndRefresh(row: .icon)
            }
        }
        return UIMenu(options: .singleSelection, children: actions)
    }

    private func createTextColorMenu(kind: WidgetPanelTextColorKind) -> UIMenu {
        let selectedMode = kind == .primary
            ? appearanceSettings.primaryTextColorMode(for: selectedPanel)
            : appearanceSettings.secondaryTextColorMode(for: selectedPanel)
        let actions = WidgetPanelTextColorMode.allCases.map { mode in
            UIAction(title: mode.title,
                     state: mode == selectedMode ? .on : .off) { [weak self] _ in
                guard let self else { return }
                if mode == .custom {
                    showColorScreen(target: kind == .primary ? .primaryText : .secondaryText)
                } else {
                    appearanceSettings.setTextColorMode(mode, kind: kind, for: selectedPanel)
                    recreateWidgetsAndRefresh(row: kind == .primary ? .primaryTextColor : .secondaryTextColor)
                }
            }
        }
        return UIMenu(options: .singleSelection, children: actions)
    }

    private func createBackgroundMenu() -> UIMenu {
        let selectedMode = appearanceSettings.backgroundMode(for: selectedPanel)
        let actions = WidgetPanelBackgroundMode.allCases.map { mode in
            UIAction(title: mode.title,
                     state: mode == selectedMode ? .on : .off) { [weak self] _ in
                guard let self else { return }
                if mode == .custom {
                    showColorScreen(target: .background)
                } else {
                    appearanceSettings.setBackgroundMode(mode, for: selectedPanel)
                    recreateWidgetsAndRefresh(row: .backgroundColor)
                }
            }
        }
        return UIMenu(options: .singleSelection, children: actions)
    }

    private func showColorScreen(target: WidgetPanelColorTarget) {
        guard let navigationController = OARootViewController.instance().navigationController else { return }
        let controller = WidgetPanelColorViewController(appMode: appMode,
                                                        panel: selectedPanel,
                                                        target: target)
        controller.delegate = self
        controller.navControllerHistory = navigationController.saveCurrentStateForScrollableHud()
        OARootViewController.instance().mapPanel.showScrollableHudViewController(controller)
        // FIXME: 
      //  navigationController.popToViewController(OARootViewController.instance(), animated: false)
    }

    private func applySizeMode(_ mode: WidgetPanelSizeMode) {
        guard let sizeStyle = mode.widgetSizeStyle else { return }
        WidgetsSettingsHelper(appMode: appMode).applyWidgetsSize(sizeStyle, panel: selectedPanel)
    }

    private func applyIconMode(_ mode: WidgetPanelIconMode) {
        guard mode != .original else { return }
        WidgetsSettingsHelper(appMode: appMode)
            .applyWidgetsIconVisibility(mode == .on, panel: selectedPanel)
    }

    private func recreateWidgetsAndReload() {
        OARootViewController.instance().mapPanel.recreateControls()
        reloadScreenData()
        DispatchQueue.main.async { [weak self] in
            self?.reloadPreview()
        }
    }

    private func recreateWidgetsAndRefresh(row: RowKey) {
        OARootViewController.instance().mapPanel.recreateControls()
        let rows: [RowKey] = row == .backgroundColor
            ? [.primaryTextColor, .secondaryTextColor, .backgroundColor]
            : [row]
        refreshRows(rows)
        DispatchQueue.main.async { [weak self] in
            self?.reloadPreview()
        }
    }

    private func reloadScreenData() {
        generateData()
        UIView.performWithoutAnimation {
            tableView.reloadData()
            tableView.layoutIfNeeded()
        }
        reloadPreview()
    }

    private func refreshRows(_ keys: [RowKey]) {
        let visibleRows = tableView.indexPathsForVisibleRows ?? []
        let indexPaths = keys.compactMap(indexPath(for:)).filter(visibleRows.contains)
        guard !indexPaths.isEmpty else { return }
        UIView.performWithoutAnimation {
            tableView.reloadRows(at: indexPaths, with: .none)
            tableView.layoutIfNeeded()
        }
    }

    private func indexPath(for key: RowKey) -> IndexPath? {
        for sectionIndex in 0..<tableData.sectionCount() {
            let section = tableData.sectionData(for: sectionIndex)
            for rowIndex in 0..<section.rowCount() where section.getRow(rowIndex).key == key.rawValue {
                return IndexPath(row: Int(rowIndex), section: Int(sectionIndex))
            }
        }
        return nil
    }

    private func reloadPreview() {
        previewView.configure(panel: selectedPanel)
    }

    private func applyCopiedParameters() {
        applySizeMode(appearanceSettings.sizeMode(for: selectedPanel))
        applyIconMode(appearanceSettings.iconMode(for: selectedPanel))
        recreateWidgetsAndReload()
    }

    private func showCopyFromProfile() {
        guard let bottomSheet = OACopyProfileBottomSheetViewControler(mode: appMode) else { return }
        bottomSheet.delegate = self
        bottomSheet.present(in: self)
    }

    @objc private func onPanelChanged(_ segmentedControl: UISegmentedControl) {
        guard panels.indices.contains(segmentedControl.selectedSegmentIndex) else { return }
        selectedPanel = panels[segmentedControl.selectedSegmentIndex]
        navigationItem.title = getTitle()
        navigationItem.rightBarButtonItems = getRightNavbarButtons()
        reloadScreenData()
    }

    @objc private func showCopyFrom() {
        let controller = WidgetsAppearanceCopyFromBottomSheetViewController(panels: panels,
                                                                            selectedPanel: selectedPanel)
        controller.onSelectProfile = { [weak self] in
            self?.showCopyFromProfile()
        }
        controller.onSelectPanel = { [weak self] sourcePanel in
            guard let self else { return }
            appearanceSettings.copy(from: sourcePanel, to: selectedPanel)
            applyCopiedParameters()
        }
        showMediumSheetViewController(viewController: controller, isLargeAvailable: false)
    }
}

private final class WidgetsAppearanceCopyFromBottomSheetViewController: OABaseNavbarSubviewViewController {
    private enum RowKey: String {
        case profile
        case panel
    }

    var onSelectProfile: (() -> Void)?
    var onSelectPanel: ((WidgetsPanel) -> Void)?

    private let panels: [WidgetsPanel]
    private let selectedPanel: WidgetsPanel

    init(panels: [WidgetsPanel], selectedPanel: WidgetsPanel) {
        self.panels = panels
        self.selectedPanel = selectedPanel
        super.init()
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func getTitle() -> String {
        localizedString("shared_string_copy_from")
    }

    override func systemLeftBarButtonItem() -> UIBarButtonItem? {
        let button = UIBarButtonItem(barButtonSystemItem: .close,
                                     target: self,
                                     action: #selector(onClosePressed))
        button.accessibilityLabel = localizedString("shared_string_close")
        return button
    }

    override func hideFirstHeader() -> Bool {
        true
    }

    override func tableStyle() -> UITableView.Style {
        .insetGrouped
    }

    override func registerCells() {
        addCell(OASimpleTableViewCell.reuseIdentifier)
    }

    override func generateData() {
        tableData.clearAllData()

        let profileSection = tableData.createNewSection()
        let profileRow = profileSection.createNewRow()
        profileRow.key = RowKey.profile.rawValue
        profileRow.title = localizedString("copy_from_other_profile")
        profileRow.icon = .icCustomCopy
        profileRow.accessibilityLabel = profileRow.title

        let panelsSection = tableData.createNewSection()
        for panel in panels where panel != selectedPanel {
            let row = panelsSection.createNewRow()
            row.key = RowKey.panel.rawValue
            row.title = panel.title
            row.iconName = panel.iconName
            row.setObj(panel, forKey: RowKey.panel.rawValue)
            row.accessibilityLabel = row.title
        }
    }

    override func getRow(_ indexPath: IndexPath) -> UITableViewCell? {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: OASimpleTableViewCell.reuseIdentifier,
                                                       for: indexPath) as? OASimpleTableViewCell else {
            return nil
        }
        let item = tableData.item(for: indexPath)
        cell.descriptionVisibility(false)
        cell.titleLabel.text = item.title
        cell.leftIconView.image = item.icon ?? UIImage.templateImageNamed(item.iconName)
        cell.leftIconView.tintColor = .iconColorActive
        cell.accessibilityLabel = item.accessibilityLabel
        cell.accessibilityTraits = .button
        return cell
    }

    override func onRowSelected(_ indexPath: IndexPath) {
        let item = tableData.item(for: indexPath)
        let action: (() -> Void)?
        if item.key == RowKey.profile.rawValue {
            action = onSelectProfile
        } else if let panel = item.obj(forKey: RowKey.panel.rawValue) as? WidgetsPanel,
                  let onSelectPanel {
            action = { onSelectPanel(panel) }
        } else {
            action = nil
        }
        dismiss(animated: true, completion: action)
    }

    @objc private func onClosePressed() {
        dismiss(animated: true)
    }
}

extension WidgetsAppearanceViewController: OACopyProfileBottomSheetDelegate {
    func onCopyProfileCompleted() {
    }

    func onCopyProfile(_ fromAppMode: OAApplicationMode) {
        appearanceSettings.copy(from: fromAppMode, panel: selectedPanel)
        applyCopiedParameters()
    }
}

extension WidgetsAppearanceViewController: WidgetPanelColorViewControllerDelegate {
    func widgetPanelColorViewControllerDidFinish() {
        reloadScreenData()
    }
}

private final class WidgetsAppearancePreviewView: UIView {
    private let scrollView = UIScrollView()
    private let imageView = UIImageView()
    private var panel: WidgetsPanel = .leftPanel

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .mapStyleWater
        clipsToBounds = true

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = false
        addSubview(scrollView)

        imageView.contentMode = .topLeft
        scrollView.addSubview(imageView)
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layoutSnapshot()
    }

    func configure(panel: WidgetsPanel) {
        self.panel = panel
        imageView.image = makePanelSnapshot(panel)
        setNeedsLayout()
    }

    private func makePanelSnapshot(_ panel: WidgetsPanel) -> UIImage? {
        guard let mapInfoController = OARootViewController.instance().mapPanel.hudViewController?.mapInfoController else {
            return nil
        }
        let controller: WidgetPanelViewController
        if panel == .leftPanel {
            controller = mapInfoController.leftPanelController
        } else if panel == .rightPanel {
            controller = mapInfoController.rightPanelController
        } else if panel == .topPanel {
            controller = mapInfoController.topPanelController
        } else {
            controller = mapInfoController.bottomPanelController
        }
        controller.loadViewIfNeeded()
        let isSidePanel = panel == .leftPanel || panel == .rightPanel
        let excludedWidgets = controller.widgetPages
            .flatMap { $0 }
            .filter { $0 is CoordinatesBaseWidget }
        let originalVisibility = excludedWidgets.map(\.isHidden)
        excludedWidgets.forEach { $0.isHidden = true }
        defer {
            for (widget, wasHidden) in zip(excludedWidgets, originalVisibility) {
                widget.isHidden = wasHidden
            }
            controller.view.layoutIfNeeded()
        }
        controller.view.layoutIfNeeded()
        var contentSize = controller.calculateContentSize()
        guard contentSize.height > 0 else { return nil }
        let sourceView: UIView
        var renderOrigin = CGPoint.zero
        if isSidePanel {
            guard contentSize.width > 0 else { return nil }
            let borderInsets = controller.view.layer.borderWidth * 2
            contentSize.width += borderInsets
            contentSize.height += controller.pageControlHeightConstraint.constant + borderInsets
            sourceView = controller.view
        } else {
            let availableWidth = bounds.width > 0 ? bounds.width : UIScreen.main.bounds.width
            let panelWidth = controller.view.bounds.width > 0 ? controller.view.bounds.width : availableWidth
            contentSize.width = min(panelWidth, availableWidth)
            sourceView = controller.currentActiveController?.view ?? controller.pageContainerView
        }
        sourceView.layoutIfNeeded()
        if !isSidePanel {
            guard let widgetsFrame = visibleWidgetsFrame(controller: controller, in: sourceView) else {
                return nil
            }
            contentSize = widgetsFrame.size
            renderOrigin = widgetsFrame.origin
        }

        let format = UIGraphicsImageRendererFormat(for: sourceView.traitCollection)
        format.opaque = false
        return UIGraphicsImageRenderer(size: contentSize, format: format).image { context in
            context.cgContext.translateBy(x: -renderOrigin.x, y: -renderOrigin.y)
            sourceView.layer.render(in: context.cgContext)
        }
    }

    private func visibleWidgetsFrame(controller: WidgetPanelViewController, in sourceView: UIView) -> CGRect? {
        var result: CGRect?
        for widget in controller.widgetPages.flatMap({ $0 }) where !widget.isHidden {
            let frame = widget.convert(widget.bounds, to: sourceView)
            guard frame.width > 0, frame.height > 0 else { continue }
            result = result?.union(frame) ?? frame
        }
        return result
    }

    private func layoutSnapshot() {
        guard let image = imageView.image else {
            imageView.frame = .zero
            scrollView.contentSize = bounds.size
            return
        }
        let scale = min(1, bounds.width / image.size.width)
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let x: CGFloat
        if panel == .rightPanel {
            x = bounds.width - size.width
        } else if panel == .topPanel || panel == .bottomPanel {
            x = max(0, (bounds.width - size.width) / 2)
        } else {
            x = 0
        }
        let y = panel == .bottomPanel ? max(0, bounds.height - size.height) : 0
        imageView.frame = CGRect(origin: CGPoint(x: x, y: y), size: size)
        scrollView.contentSize = CGSize(width: bounds.width, height: max(bounds.height, size.height))
        scrollView.isScrollEnabled = size.height > bounds.height
    }
}

private final class WidgetsAppearanceOptionCell: UITableViewCell {
    enum Preview {
        case image(UIImage?, UIColor)
        case text(UIColor, UIColor)
        case color(UIColor)
    }

    private let previewContainer = UIView()
    private let previewCheckerboardImageView = UIImageView()
    private let previewColorView = UIView()
    private let previewImageView = UIImageView()
    private let previewLabel = UILabel()
    private let titleLabel = UILabel()
    private let valueButton = UIButton(type: .system)
    private var usesAccessibilityLayout = false
    private var isLayoutConfigured = false
    private lazy var titleLeadingToPreviewConstraint = titleLabel.leadingAnchor.constraint(
        equalTo: previewContainer.trailingAnchor,
        constant: 13
    )
    private lazy var titleLeadingToContentConstraint = titleLabel.leadingAnchor.constraint(
        equalTo: contentView.leadingAnchor,
        constant: 16
    )
    private lazy var regularLayoutConstraints = [
        previewContainer.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: valueButton.leadingAnchor, constant: -8),
        valueButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
        valueButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
    ]
    private lazy var accessibilityLayoutConstraints = [
        previewContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
        titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
        titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
        valueButton.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
        valueButton.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
        valueButton.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -16),
        valueButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
    ]

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        isAccessibilityElement = false
        previewContainer.isHidden = false
        valueButton.isHidden = false
        titleLabel.textColor = .textColorPrimary
        selectionStyle = .none
        accessibilityLabel = nil
        accessibilityValue = nil
        accessibilityTraits = []
        valueButton.accessibilityLabel = nil
        valueButton.accessibilityValue = nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if !valueButton.isHidden {
            valueButton.accessibilityFrame = UIAccessibility.convertToScreenCoordinates(bounds, in: self)
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateLayoutForContentSizeCategory()
    }

    func configure(title: String, preview: Preview, value: String, menu: UIMenu) {
        selectionStyle = .none
        titleLabel.text = title
        titleLabel.textColor = .textColorPrimary
        titleLeadingToContentConstraint.isActive = false
        titleLeadingToPreviewConstraint.isActive = true
        configurePreview(preview)

        var configuration = UIButton.Configuration.plain()
        configuration.title = value
        configuration.image = UIImage(systemName: "chevron.up.chevron.down",
                                      withConfiguration: UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold))
        configuration.imagePlacement = .trailing
        configuration.imagePadding = 5
        configuration.contentInsets = .zero
        configuration.baseForegroundColor = .textColorActive
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var attributes = attributes
            attributes.font = .preferredFont(forTextStyle: .body)
            return attributes
        }
        valueButton.configuration = configuration
        valueButton.menu = menu
        valueButton.showsMenuAsPrimaryAction = true
        valueButton.changesSelectionAsPrimaryAction = false
        isAccessibilityElement = false
        valueButton.accessibilityLabel = title
        valueButton.accessibilityValue = value
        valueButton.accessibilityTraits = .button
    }

    func configureReset(title: String) {
        previewContainer.isHidden = true
        valueButton.isHidden = true
        valueButton.configuration = nil
        valueButton.menu = nil
        valueButton.accessibilityLabel = nil
        valueButton.accessibilityValue = nil
        titleLeadingToPreviewConstraint.isActive = false
        titleLeadingToContentConstraint.isActive = true
        titleLabel.text = title
        titleLabel.textColor = .textColorActive
        selectionStyle = .default
        isAccessibilityElement = true
        accessibilityLabel = title
        accessibilityValue = nil
        accessibilityTraits = .button
    }

    private func setupViews() {
        backgroundColor = .groupBg
        preservesSuperviewLayoutMargins = false
        separatorInset = .init(top: 0, left: 62, bottom: 0, right: 16)

        previewContainer.translatesAutoresizingMaskIntoConstraints = false
        previewCheckerboardImageView.translatesAutoresizingMaskIntoConstraints = false
        previewCheckerboardImageView.contentMode = .scaleAspectFit
        previewCheckerboardImageView.image = UIImage(named: "bg_color_chessboard_pattern")
        previewColorView.translatesAutoresizingMaskIntoConstraints = false
        previewImageView.translatesAutoresizingMaskIntoConstraints = false
        previewImageView.contentMode = .scaleAspectFit
        previewLabel.translatesAutoresizingMaskIntoConstraints = false
        previewLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        previewLabel.textAlignment = .center
        previewLabel.text = "A"
        previewContainer.accessibilityElementsHidden = true

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .preferredFont(forTextStyle: .body)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.numberOfLines = 0
        titleLabel.textColor = .textColorPrimary
        titleLabel.isAccessibilityElement = false

        valueButton.translatesAutoresizingMaskIntoConstraints = false
        valueButton.titleLabel?.font = .preferredFont(forTextStyle: .body)
        valueButton.titleLabel?.adjustsFontForContentSizeCategory = true
        valueButton.setContentHuggingPriority(.required, for: .horizontal)
        valueButton.setContentCompressionResistancePriority(.required, for: .horizontal)

        contentView.addSubview(previewContainer)
        previewContainer.addSubview(previewCheckerboardImageView)
        previewContainer.addSubview(previewColorView)
        previewContainer.addSubview(previewImageView)
        previewContainer.addSubview(previewLabel)
        contentView.addSubview(titleLabel)
        contentView.addSubview(valueButton)

        titleLeadingToPreviewConstraint.isActive = true
        updateLayoutForContentSizeCategory()

        NSLayoutConstraint.activate([
            previewContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 13),
            previewContainer.widthAnchor.constraint(equalToConstant: 36),
            previewContainer.heightAnchor.constraint(equalToConstant: 36),

            previewCheckerboardImageView.leadingAnchor.constraint(equalTo: previewContainer.leadingAnchor),
            previewCheckerboardImageView.trailingAnchor.constraint(equalTo: previewContainer.trailingAnchor),
            previewCheckerboardImageView.topAnchor.constraint(equalTo: previewContainer.topAnchor),
            previewCheckerboardImageView.bottomAnchor.constraint(equalTo: previewContainer.bottomAnchor),

            previewColorView.leadingAnchor.constraint(equalTo: previewContainer.leadingAnchor),
            previewColorView.trailingAnchor.constraint(equalTo: previewContainer.trailingAnchor),
            previewColorView.topAnchor.constraint(equalTo: previewContainer.topAnchor),
            previewColorView.bottomAnchor.constraint(equalTo: previewContainer.bottomAnchor),

            previewImageView.centerXAnchor.constraint(equalTo: previewContainer.centerXAnchor),
            previewImageView.centerYAnchor.constraint(equalTo: previewContainer.centerYAnchor),
            previewImageView.widthAnchor.constraint(equalToConstant: 30),
            previewImageView.heightAnchor.constraint(equalToConstant: 30),

            previewLabel.leadingAnchor.constraint(equalTo: previewContainer.leadingAnchor),
            previewLabel.trailingAnchor.constraint(equalTo: previewContainer.trailingAnchor),
            previewLabel.topAnchor.constraint(equalTo: previewContainer.topAnchor),
            previewLabel.bottomAnchor.constraint(equalTo: previewContainer.bottomAnchor)
        ])
    }

    private func updateLayoutForContentSizeCategory() {
        let useAccessibilityLayout = traitCollection.preferredContentSizeCategory.isAccessibilityCategory
        guard !isLayoutConfigured || usesAccessibilityLayout != useAccessibilityLayout else { return }
        isLayoutConfigured = true
        usesAccessibilityLayout = useAccessibilityLayout
        if useAccessibilityLayout {
            NSLayoutConstraint.deactivate(regularLayoutConstraints)
            NSLayoutConstraint.activate(accessibilityLayoutConstraints)
            valueButton.contentHorizontalAlignment = .leading
        } else {
            NSLayoutConstraint.deactivate(accessibilityLayoutConstraints)
            NSLayoutConstraint.activate(regularLayoutConstraints)
            valueButton.contentHorizontalAlignment = .trailing
        }
    }

    private func configurePreview(_ preview: Preview) {
        previewCheckerboardImageView.isHidden = true
        previewColorView.isHidden = true
        previewImageView.isHidden = true
        previewLabel.isHidden = true
        previewContainer.layer.cornerRadius = 18
        previewContainer.clipsToBounds = true
        previewContainer.layer.borderWidth = 0
        switch preview {
        case let .image(image, tintColor):
            previewContainer.backgroundColor = .clear
            previewImageView.isHidden = false
            previewImageView.image = image
            previewImageView.tintColor = tintColor
        case let .text(textColor, backgroundColor):
            configureColorPreview(backgroundColor)
            previewContainer.layer.borderWidth = 1
            previewContainer.layer.borderColor = UIColor.iconColorDefault.cgColor
            previewImageView.isHidden = false
            previewImageView.image = .icCustomTextPreview
            previewImageView.tintColor = textColor
        case let .color(color):
            configureColorPreview(color)
            previewContainer.layer.borderWidth = 1
            previewContainer.layer.borderColor = UIColor.iconColorDefault.cgColor
        }
    }

    private func configureColorPreview(_ color: UIColor) {
        previewContainer.backgroundColor = .clear
        previewCheckerboardImageView.isHidden = color.cgColor.alpha >= 0.999
        previewColorView.isHidden = false
        previewColorView.backgroundColor = color
    }
}
