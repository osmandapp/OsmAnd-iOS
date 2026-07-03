//
//  AstroConfigureViewBottomSheet.swift
//  OsmAnd Maps
//
//  Created by Codex on 20.05.2026.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

import UIKit

final class AstroConfigureViewBottomSheet: UIViewController, UISheetPresentationControllerDelegate {
    private enum Layout {
        static let contentPadding: CGFloat = 16
        static let contentPaddingSmall: CGFloat = 15
        static let contentPaddingMedium: CGFloat = 9
        static let contentPaddingMinimal: CGFloat = 2
        static let headerTitleRowHeight: CGFloat = 56
        static let headerTitlePadding: CGFloat = 32
        static let sectionCornerRadius: CGFloat = 26
        static let closeButtonSize: CGFloat = 48
        static let closeCircleSize: CGFloat = 44
        static let closeIconSize: CGFloat = 24
    }
    
    var config = AstronomyPluginSettings.StarMapConfig()
    var commonConfig = AstronomyPluginSettings.CommonConfig()
    var onConfigChanged: ((AstronomyPluginSettings.StarMapConfig) -> Void)?
    var onCommonConfigChanged: ((AstronomyPluginSettings.CommonConfig) -> Void)?
    var onRedFilterChanged: ((Bool) -> Void)?
    var onClose: (() -> Void)?
    var onDismissed: (() -> Void)?

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let topCard = UIView()
    private let topCardStack = UIStackView()
    private let topButtonsRow = UIStackView()
    private let visibleObjectsGridContent = UIStackView()
    private let personalContent = UIStackView()
    private let renderingContent = UIStackView()

    private var themeRenderActions: [() -> Void] = []
    private weak var redFilterCard: AstroActionCard?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupScrollView()
        setupContent()
        bindMapActions()
        bindVisibleObjects()
        bindSwitchRows()
        applyTheme()
        configureNavigationBar()
        applyRedFilter(enabled: config.showRedFilter)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNavigationBar()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.sheetPresentationController?.delegate = self
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard previousTraitCollection?.hasDifferentColorAppearance(comparedTo: traitCollection) == true else {
            return
        }
        applyTheme()
        themeRenderActions.forEach { $0() }
        applyRedFilter(enabled: config.showRedFilter)
    }

    func applyRedFilter(enabled: Bool) {
        config.showRedFilter = enabled
        if let redFilterCard {
            renderToggleCard(card: redFilterCard,
                             checked: enabled,
                             drawableEnabled: redFilterIcon(selected: true),
                             drawableDisabled: redFilterIcon(selected: false),
                             titleResEnabled: "red_filter")
        }
        if isViewLoaded {
            AstroRedFilter.apply(enabled, to: navigationController?.view)
        }
    }

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        onDismissed?()
    }

    private func configureNavigationBar() {
        let imageClose = OAUtilities.resize(UIImage.templateImageNamed("ic_navbar_close"),
                                            newSize: CGSize(width: 24, height: 24))?.withRenderingMode(.alwaysTemplate)
        let closeButton = UIBarButtonItem(image: imageClose, style: .plain, target: self, action: #selector(closeAction))
        closeButton.tintColor = .label
        closeButton.accessibilityLabel = localizedString("shared_string_close")
        
        title = localizedString("astro_configure_view")
        navigationItem.title = localizedString("astro_configure_view")
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.leftBarButtonItem = closeButton
        navigationItem.rightBarButtonItem = nil
    }

    private func setupScrollView() {
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = true
        scrollView.addSubview(contentStack)

        contentStack.axis = .vertical
        contentStack.spacing = Layout.contentPadding
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -Layout.contentPadding),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])
    }

    private func setupContent() {
        setupTopCard()
        contentStack.addArrangedSubview(topCard)
        contentStack.addArrangedSubview(setupSection(stackView: personalContent, with: localizedString("personal_category_name")))
        contentStack.addArrangedSubview(setupSection(stackView: renderingContent, with: localizedString("astro_rendering")))
    }

    private func setupTopCard() {
        topCard.translatesAutoresizingMaskIntoConstraints = false
        topCard.addSubview(topCardStack)

        topCardStack.axis = .vertical
        topCardStack.spacing = 0
        topCardStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            topCardStack.leadingAnchor.constraint(equalTo: topCard.leadingAnchor),
            topCardStack.trailingAnchor.constraint(equalTo: topCard.trailingAnchor),
            topCardStack.topAnchor.constraint(equalTo: topCard.topAnchor),
            topCardStack.bottomAnchor.constraint(equalTo: topCard.bottomAnchor)
        ])

        setupTopButtonsRow()
        topCardStack.addArrangedSubview(topButtonsRow)
        topCardStack.addArrangedSubview(createHeaderView(text: localizedString("astro_visible_objects")))
        setupVisibleObjectsGrid()
        topCardStack.addArrangedSubview(visibleObjectsGridContent)
    }

    private func setupTopButtonsRow() {
        topButtonsRow.axis = .horizontal
        topButtonsRow.distribution = .fillEqually
        topButtonsRow.spacing = Layout.contentPaddingSmall
        topButtonsRow.layoutMargins = UIEdgeInsets(top: Layout.contentPaddingMedium,
                                                   left: Layout.contentPadding,
                                                   bottom: Layout.contentPadding,
                                                   right: Layout.contentPadding)
        topButtonsRow.isLayoutMarginsRelativeArrangement = true
    }

    private func setupVisibleObjectsGrid() {
        visibleObjectsGridContent.axis = .vertical
        visibleObjectsGridContent.spacing = Layout.contentPaddingSmall
        visibleObjectsGridContent.layoutMargins = UIEdgeInsets(top: 0,
                                                               left: Layout.contentPadding,
                                                               bottom: 0,
                                                               right: Layout.contentPadding)
        visibleObjectsGridContent.isLayoutMarginsRelativeArrangement = true
    }
    
    private func setupSection(stackView: UIStackView, with title: String) -> UIView {
        let header = createHeaderView(text: title)
        
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        stackView.layer.cornerRadius = Layout.sectionCornerRadius
        stackView.layer.masksToBounds = true
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(header)
        container.addSubview(stackView)

        NSLayoutConstraint.activate([
            header.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            header.topAnchor.constraint(equalTo: container.topAnchor, constant: Layout.contentPadding),
            
            stackView.leadingAnchor.constraint(equalTo: container.safeAreaLayoutGuide.leadingAnchor, constant: Layout.contentPadding),
            stackView.trailingAnchor.constraint(equalTo: container.safeAreaLayoutGuide.trailingAnchor, constant: -Layout.contentPadding),
            stackView.topAnchor.constraint(equalTo: header.bottomAnchor),
            stackView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        return container
    }
    
    private func createHeaderView(text: String) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let title = UILabel()
        title.text = text
        title.textColor = .textColorSecondary
        title.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        title.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(title)

        NSLayoutConstraint.activate([
            title.leadingAnchor.constraint(equalTo: container.safeAreaLayoutGuide.leadingAnchor, constant: Layout.headerTitlePadding),
            title.trailingAnchor.constraint(equalTo: container.safeAreaLayoutGuide.trailingAnchor, constant: -Layout.headerTitlePadding),
            title.topAnchor.constraint(equalTo: container.topAnchor, constant: Layout.contentPaddingSmall),
            title.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -Layout.contentPaddingSmall)
        ])

        return container
    }

    private func bindMapActions() {
        bindToggleMapActionCard(
            card: addActionCard(to: topButtonsRow),
            drawableEnabled: .icCustomGlobeView,
            drawableDisabled: .icCustomCelestialPath,
            titleResEnabled: "map_3d",
            titleResDisabled: "map_2d",
            isChecked: { [weak self] in
                guard let self else {
                    return false
                }
                return !config.is2DMode
            },
            toggle: { [weak self] enabled3d in
                guard let self else {
                    return
                }
                config.is2DMode = !enabled3d
                onConfigChanged?(config)
            }
        )

        bindToggleMapActionCard(
            card: addActionCard(to: topButtonsRow),
            drawableEnabled: AstroIcon.template("ic_custom_map"),
            drawableDisabled: .icCustomMapOutline,
            titleResEnabled: "shared_string_map",
            isChecked: { [weak self] in
                self?.commonConfig.showRegularMap ?? false
            },
            toggle: { [weak self] regularMap in
                guard let self else {
                    return
                }
                commonConfig.showRegularMap = regularMap
                onCommonConfigChanged?(commonConfig)
            }
        )

        let redCard = addActionCard(to: topButtonsRow)
        redFilterCard = redCard
        bindToggleMapActionCard(
            card: redCard,
            drawableEnabled: redFilterIcon(selected: true),
            drawableDisabled: redFilterIcon(selected: false),
            titleResEnabled: "red_filter",
            isChecked: { [weak self] in
                self?.config.showRedFilter ?? false
            },
            toggle: { [weak self] checked in
                guard let self else {
                    return
                }
                config.showRedFilter = checked
                if let onRedFilterChanged {
                    onRedFilterChanged(checked)
                } else {
                    onConfigChanged?(config)
                }
            }
        )
    }

    private func bindVisibleObjects() {
        visibleObjectsGridContent.addArrangedSubview(gridRow([
            bindToggleAstroCard(
                card: AstroActionCard(),
                iconName: "ic_custom_planet_outlined",
                titleRes: "astro_solar_system",
                isChecked: { c in c.showSun && c.showMoon && c.showPlanets },
                toggle: { c in
                    let allOn = c.showSun && c.showMoon && c.showPlanets
                    let newValue = !allOn
                    var updated = c
                    updated.showSun = newValue
                    updated.showMoon = newValue
                    updated.showPlanets = newValue
                    return updated
                }
            ),
            bindToggleAstroCard(
                card: AstroActionCard(),
                iconName: "ic_custom_constellations",
                titleRes: "astro_constellations",
                isChecked: { $0.showConstellations },
                toggle: { c in
                    var updated = c
                    updated.showConstellations.toggle()
                    return updated
                }
            ),
            bindToggleAstroCard(
                card: AstroActionCard(),
                iconName: "ic_custom_star_shine",
                titleRes: "astro_stars",
                isChecked: { $0.showStars },
                toggle: { c in
                    var updated = c
                    updated.showStars.toggle()
                    return updated
                }
            )
        ]))

        visibleObjectsGridContent.addArrangedSubview(gridRow([
            bindToggleAstroCard(
                card: AstroActionCard(),
                iconName: "ic_custom_nebulas",
                titleRes: "astro_nebulas",
                isChecked: { $0.showNebulae },
                toggle: { c in
                    var updated = c
                    updated.showNebulae.toggle()
                    return updated
                }
            ),
            bindToggleAstroCard(
                card: AstroActionCard(),
                iconName: "ic_custom_star_clusters",
                titleRes: "astro_star_clusters",
                isChecked: { c in c.showOpenClusters && c.showGlobularClusters },
                toggle: { c in
                    let allOn = c.showOpenClusters && c.showGlobularClusters
                    let newValue = !allOn
                    var updated = c
                    updated.showOpenClusters = newValue
                    updated.showGlobularClusters = newValue
                    return updated
                }
            ),
            bindToggleAstroCard(
                card: AstroActionCard(),
                iconName: "ic_custom_galaxy",
                titleRes: "astro_deep_sky",
                isChecked: { c in c.showGalaxies && c.showBlackHoles && c.showGalaxyClusters },
                toggle: { c in
                    let allOn = c.showGalaxies && c.showBlackHoles && c.showGalaxyClusters
                    let newValue = !allOn
                    var updated = c
                    updated.showGalaxies = newValue
                    updated.showBlackHoles = newValue
                    updated.showGalaxyClusters = newValue
                    return updated
                }
            )
        ]))
    }

    private func bindSwitchRows() {
        let current = config
        
        addSwitchRow(
            parent: personalContent,
            iconNameEnabled: "ic_custom_target_direction_on",
            iconNameDisabled: "ic_custom_target_direction_off",
            titleRes: "astro_directions",
            checked: current.showDirections
        ) { [weak self] checked in
            guard let self else {
                return
            }
            var updated = config
            updated.showDirections = checked
            applyConfigChange(updated)
        }
        
        addSwitchRow(
            parent: personalContent,
            iconNameEnabled: "ic_custom_bookmark",
            iconNameDisabled: "ic_custom_bookmark_outlined",
            titleRes: "favorites_item",
            checked: current.showFavorites
        ) { [weak self] checked in
            guard let self else {
                return
            }
            var updated = config
            updated.showFavorites = checked
            applyConfigChange(updated)
        }

        addSwitchRow(
            parent: personalContent,
            iconNameEnabled: "ic_custom_target_path_on",
            iconNameDisabled: "ic_custom_target_path_off",
            titleRes: "astro_daily_path",
            checked: current.showCelestialPaths,
            showDivider: false
        ) { [weak self] checked in
            guard let self else {
                return
            }
            var updated = config
            updated.showCelestialPaths = checked
            applyConfigChange(updated)
        }

        addSwitchRow(
            parent: renderingContent,
            iconNameEnabled: "ic_custom_azimuthal_grid",
            iconNameDisabled: "ic_custom_azimuthal_grid",
            titleRes: "azimuthal_grid",
            checked: current.showAzimuthalGrid
        ) { [weak self] checked in
            guard let self else {
                return
            }
            var updated = config
            updated.showAzimuthalGrid = checked
            applyConfigChange(updated)
        }

        addSwitchRow(
            parent: renderingContent,
            iconNameEnabled: "ic_custom_meridian_line",
            iconNameDisabled: "ic_custom_meridian_line",
            titleRes: "meridian_line",
            checked: current.showMeridianLine
        ) { [weak self] checked in
            guard let self else {
                return
            }
            var updated = config
            updated.showMeridianLine = checked
            applyConfigChange(updated)
        }

        addSwitchRow(
            parent: renderingContent,
            iconNameEnabled: "ic_custom_equatorial_grid",
            iconNameDisabled: "ic_custom_equatorial_grid",
            titleRes: "equatorial_grid",
            checked: current.showEquatorialGrid
        ) { [weak self] checked in
            guard let self else {
                return
            }
            var updated = config
            updated.showEquatorialGrid = checked
            applyConfigChange(updated)
        }

        addSwitchRow(
            parent: renderingContent,
            iconNameEnabled: "ic_custom_eliptical_line",
            iconNameDisabled: "ic_custom_eliptical_line",
            titleRes: "ecliptic_line",
            checked: current.showEclipticLine
        ) { [weak self] checked in
            guard let self else {
                return
            }
            var updated = config
            updated.showEclipticLine = checked
            applyConfigChange(updated)
        }

        addSwitchRow(
            parent: renderingContent,
            iconNameEnabled: "ic_custom_galaxy_equator",
            iconNameDisabled: "ic_custom_galaxy_equator",
            titleRes: "equator_line",
            checked: current.showEquatorLine,
            showDivider: true
        ) { [weak self] checked in
            guard let self else {
                return
            }
            var updated = config
            updated.showEquatorLine = checked
            applyConfigChange(updated)
        }

        addSwitchRow(
            parent: renderingContent,
            iconNameEnabled: "ic_custom_galaxy_line",
            iconNameDisabled: "ic_custom_galaxy_line",
            titleRes: "galactic_line",
            checked: current.showGalacticLine,
            showDivider: false
        ) { [weak self] checked in
            guard let self else {
                return
            }
            var updated = config
            updated.showGalacticLine = checked
            applyConfigChange(updated)
        }
    }

    private func renderToggleCard(
        card: AstroActionCard,
        checked: Bool,
        drawableEnabled: UIImage?,
        drawableDisabled: UIImage? = nil,
        titleResEnabled: String,
        titleResDisabled: String? = nil
    ) {
        let icon = checked ? drawableEnabled : (drawableDisabled ?? drawableEnabled)
        let titleRes = checked ? titleResEnabled : (titleResDisabled ?? titleResEnabled)
        card.render(checked: checked, icon: icon, title: localizedString(titleRes))
    }

    private func bindToggleMapActionCard(
        card: AstroActionCard,
        drawableEnabled: UIImage?,
        drawableDisabled: UIImage? = nil,
        titleResEnabled: String,
        titleResDisabled: String? = nil,
        isChecked: @escaping () -> Bool,
        toggle: @escaping (Bool) -> Void
    ) {
        let render: () -> Void = { [weak self, weak card] in
            guard let self, let card else {
                return
            }
            renderToggleCard(card: card,
                             checked: isChecked(),
                             drawableEnabled: drawableEnabled,
                             drawableDisabled: drawableDisabled,
                             titleResEnabled: titleResEnabled,
                             titleResDisabled: titleResDisabled)
        }

        render()
        themeRenderActions.append(render)

        card.addAction(UIAction { _ in
            let newValue = !isChecked()
            toggle(newValue)
            render()
        }, for: .touchUpInside)
    }

    private func bindToggleAstroCard(
        card: AstroActionCard,
        iconName: String,
        titleRes: String,
        isChecked: @escaping (AstronomyPluginSettings.StarMapConfig) -> Bool,
        toggle: @escaping (AstronomyPluginSettings.StarMapConfig) -> AstronomyPluginSettings.StarMapConfig
    ) -> AstroActionCard {
        let render: () -> Void = { [weak self, weak card] in
            guard let self, let card else {
                return
            }
            renderToggleCard(card: card,
                             checked: isChecked(config),
                             drawableEnabled: AstroIcon.template(iconName),
                             titleResEnabled: titleRes)
        }

        render()
        themeRenderActions.append(render)

        card.addAction(UIAction { [weak self, weak card] _ in
            guard let self else {
                return
            }
            let newConfig = toggle(config)
            applyConfigChange(newConfig)
            if let card {
                renderToggleCard(card: card,
                                 checked: isChecked(newConfig),
                                 drawableEnabled: AstroIcon.template(iconName),
                                 titleResEnabled: titleRes)
            }
        }, for: .touchUpInside)

        return card
    }

    private func addSwitchRow(
        parent: UIStackView,
        iconNameEnabled: String,
        iconNameDisabled: String,
        titleRes: String,
        checked: Bool,
        showDivider: Bool = true,
        onToggle: @escaping (Bool) -> Void
    ) {
        let row = AstroSwitchRow(iconNameEnabled: iconNameEnabled,
                                 iconNameDisabled: iconNameDisabled,
                                 title: localizedString(titleRes),
                                 checked: checked,
                                 showDivider: showDivider,
                                 onToggle: onToggle)
        parent.addArrangedSubview(row)
    }

    private func setupSwitchItemIcon(_ imageView: UIImageView, iconName: String, isChecked: Bool) {
        imageView.image = AstroIcon.template(iconName)
        imageView.tintColor = isChecked ? .iconColorActive : .iconColorDefault
    }

    private func addActionCard(to row: UIStackView) -> AstroActionCard {
        let card = AstroActionCard()
        row.addArrangedSubview(card)
        return card
    }

    private func gridRow(_ cards: [UIView]) -> UIStackView {
        let row = UIStackView(arrangedSubviews: cards)
        row.axis = .horizontal
        row.distribution = .fillEqually
        row.spacing = Layout.contentPaddingSmall
        return row
    }

    private func redFilterIcon(selected: Bool) -> UIImage? {
        guard selected else {
            return .icCustomRedFilterOff
        }
        return AstroIcon.layeredTemplate(baseName: "ic_custom_red_filter_base_on",
                                         baseColor: .iconColorActive,
                                         overlayName: "ic_custom_red_filter_overlay_on",
                                         overlayColor: .iconColorDisruptive)
    }

    private func applyConfigChange(_ newConfig: AstronomyPluginSettings.StarMapConfig) {
        config = newConfig
        onConfigChanged?(newConfig)
    }

    private func applyTheme() {
        view.backgroundColor = .viewBg
    }
    
    @objc private func closeAction() {
        onClose?()
    }
}

private final class AstroActionCard: UIControl {
    
    override var isHighlighted: Bool {
        didSet {
            alpha = isHighlighted ? 0.65 : 1
        }
    }
    
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private var checked = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        applyStyle()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.hasDifferentColorAppearance(comparedTo: traitCollection) == true {
            applyStyle()
        }
    }

    func render(checked: Bool, icon: UIImage?, title: String) {
        self.checked = checked
        iconView.image = icon
        titleLabel.text = title
        applyStyle()
        updateAccessibility(title: title)
    }

    private func setupView() {
        translatesAutoresizingMaskIntoConstraints = false
        layer.cornerRadius = 10
        layer.masksToBounds = true

        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.isUserInteractionEnabled = false

        titleLabel.font = .preferredFont(forTextStyle: .subheadline)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 2
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.8
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.isUserInteractionEnabled = false

        addSubview(iconView)
        addSubview(titleLabel)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(greaterThanOrEqualToConstant: 75),
            iconView.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            iconView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 30),
            iconView.heightAnchor.constraint(equalToConstant: 30),
            
            titleLabel.topAnchor.constraint(greaterThanOrEqualTo: iconView.bottomAnchor),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 4),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -4),
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10)
        ])
    }

    private func applyStyle() {
        backgroundColor = checked ? .buttonBgColorTertiary : .groupBg
        layer.borderWidth = checked ? 2 : 0
        layer.borderColor = UIColor.buttonBgColorPrimary.cgColor
        iconView.tintColor = .iconColorActive
        titleLabel.textColor = .buttonTextColorSecondary
    }
    
    private func updateAccessibility(title: String) {
        isAccessibilityElement = true
        iconView.isAccessibilityElement = false
        titleLabel.isAccessibilityElement = false
        
        accessibilityLabel = title
        accessibilityTraits = checked ? [.button, .selected] : [.button]
    }
}

private final class AstroSwitchRow: UIControl {
    
    override var isHighlighted: Bool {
        didSet {
            alpha = isHighlighted ? 0.65 : 1
        }
    }
    
    private let iconNameEnabled: String
    private let iconNameDisabled: String
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let switcher = UISwitch()
    private let dividerView = UIView()
    private let onToggle: (Bool) -> Void
    private var checked: Bool

    init(iconNameEnabled: String,
         iconNameDisabled: String,
         title: String,
         checked: Bool,
         showDivider: Bool,
         onToggle: @escaping (Bool) -> Void) {
        self.iconNameEnabled = iconNameEnabled
        self.iconNameDisabled = iconNameDisabled
        self.checked = checked
        self.onToggle = onToggle
        super.init(frame: .zero)
        setupView(title: title, checked: checked, showDivider: showDivider)
        applyStyle()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.hasDifferentColorAppearance(comparedTo: traitCollection) == true {
            applyStyle()
        }
    }

    private func setupView(title: String, checked: Bool, showDivider: Bool) {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .clear
        addAction(UIAction { [weak self] _ in
            self?.toggleFromRow()
        }, for: .touchUpInside)

        let contentView = UIView()
        contentView.backgroundColor = .groupBg
        contentView.isUserInteractionEnabled = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)

        iconView.image = AstroIcon.template(checked ? iconNameEnabled : iconNameDisabled)
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.text = title
        titleLabel.textColor = .textColorPrimary
        titleLabel.font = .preferredFont(forTextStyle: .body)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.8
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        switcher.isOn = checked
        switcher.translatesAutoresizingMaskIntoConstraints = false
        switcher.addAction(UIAction { [weak self] _ in
            self?.switchChanged()
        }, for: .valueChanged)

        dividerView.backgroundColor = .customSeparator
        dividerView.isHidden = !showDivider
        dividerView.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(iconView)
        contentView.addSubview(titleLabel)
        addSubview(switcher)
        addSubview(dividerView)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(greaterThanOrEqualToConstant: 52),
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor),
            dividerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 62),
            dividerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            dividerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            dividerView.heightAnchor.constraint(equalToConstant: 1),
            iconView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 30),
            iconView.heightAnchor.constraint(equalToConstant: 30),
            switcher.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            switcher.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: switcher.leadingAnchor, constant: -16),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
        
        updateAccessibility()
    }

    private func toggleFromRow() {
        setChecked(!checked, sendAction: true)
    }

    private func switchChanged() {
        setChecked(switcher.isOn, sendAction: true)
    }

    private func setChecked(_ checked: Bool, sendAction: Bool) {
        self.checked = checked
        switcher.setOn(checked, animated: true)
        applyStyle()
        updateAccessibility()
        if sendAction {
            onToggle(checked)
        }
    }

    private func applyStyle() {
        iconView.image = AstroIcon.template(checked ? iconNameEnabled : iconNameDisabled)
        iconView.tintColor = checked ? .iconColorActive : .iconColorDefault
        titleLabel.textColor = .textColorPrimary
        dividerView.backgroundColor = .customSeparator
    }
    
    private func updateAccessibility() {
        iconView.isAccessibilityElement = false
        titleLabel.isAccessibilityElement = false
        dividerView.isAccessibilityElement = false
        isAccessibilityElement = false
        
        accessibilityElements = [switcher]
        switcher.isAccessibilityElement = true
        switcher.accessibilityLabel = titleLabel.text
        switcher.accessibilityValue = checked ? localizedString("shared_string_on") : localizedString("shared_string_off")
    }
}
