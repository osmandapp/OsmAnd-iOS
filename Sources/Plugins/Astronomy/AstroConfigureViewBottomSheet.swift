//
//  AstroConfigureViewBottomSheet.swift
//  OsmAnd Maps
//
//  Created by Codex on 20.05.2026.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

import UIKit

final class AstroConfigureViewBottomSheet: UIViewController, UISheetPresentationControllerDelegate {
    var config = AstronomyPluginSettings.StarMapConfig()
    var commonConfig = AstronomyPluginSettings.CommonConfig()
    var onConfigChanged: ((AstronomyPluginSettings.StarMapConfig) -> Void)?
    var onCommonConfigChanged: ((AstronomyPluginSettings.CommonConfig) -> Void)?
    var onRedFilterChanged: ((Bool) -> Void)?
    var onClose: (() -> Void)?
    var onDismissed: (() -> Void)?

    private enum Layout {
        static let contentPadding: CGFloat = 16
        static let contentPaddingSmall: CGFloat = 12
        static let contentPaddingMedium: CGFloat = 9
        static let contentPaddingMinimal: CGFloat = 2
        static let headerTitleRowHeight: CGFloat = 56
        static let sectionCornerRadius: CGFloat = 12
        static let closeButtonSize: CGFloat = 48
        static let closeCircleSize: CGFloat = 32
        static let closeIconSize: CGFloat = 24
    }

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let topCard = UIView()
    private let topCardStack = UIStackView()
    private let topButtonsRow = UIStackView()
    private let visibleObjectsGridContent = UIStackView()
    private let personalContent = UIStackView()
    private let renderingContent = UIStackView()

    private weak var redFilterCard: AstroActionCard?
    private var themeRenderActions: [() -> Void] = []

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
            AstroRedFilter.apply(enabled, to: view)
        }
    }

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        onDismissed?()
    }

    private func configureNavigationBar() {
        title = nil
        navigationItem.title = nil
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.leftBarButtonItem = nil
        navigationItem.rightBarButtonItem = nil
        navigationController?.setNavigationBarHidden(true, animated: false)
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
        contentStack.addArrangedSubview(sectionCard(title: localizedString("personal_category_name"),
                                                    contentStack: personalContent))
        contentStack.addArrangedSubview(sectionCard(title: localizedString("astro_rendering"),
                                                    contentStack: renderingContent))
    }

    private func setupTopCard() {
        topCard.translatesAutoresizingMaskIntoConstraints = false
        topCard.layer.cornerRadius = Layout.sectionCornerRadius
        topCard.layer.masksToBounds = true
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

        addHeader()
        setupTopButtonsRow()
        topCardStack.addArrangedSubview(topButtonsRow)
        topCardStack.addArrangedSubview(divider())
        addVisibleObjectsTitle()
        setupVisibleObjectsGrid()
        topCardStack.addArrangedSubview(visibleObjectsGridContent)
    }

    private func addHeader() {
        let header = UIStackView()
        header.axis = .vertical
        header.spacing = Layout.contentPaddingMinimal

        let titleRow = UIView()
        let title = UILabel()
        title.text = localizedString("astro_configure_view")
        title.textColor = .textColorPrimary
        title.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        title.adjustsFontForContentSizeCategory = false
        title.translatesAutoresizingMaskIntoConstraints = false

        let closeButton = makeCloseButton()
        titleRow.addSubview(title)
        titleRow.addSubview(closeButton)

        NSLayoutConstraint.activate([
            titleRow.heightAnchor.constraint(greaterThanOrEqualToConstant: Layout.headerTitleRowHeight),
            title.leadingAnchor.constraint(equalTo: titleRow.leadingAnchor, constant: Layout.contentPadding),
            title.trailingAnchor.constraint(lessThanOrEqualTo: closeButton.leadingAnchor, constant: -Layout.contentPaddingSmall),
            title.centerYAnchor.constraint(equalTo: titleRow.centerYAnchor),
            closeButton.trailingAnchor.constraint(equalTo: titleRow.trailingAnchor, constant: -4),
            closeButton.centerYAnchor.constraint(equalTo: titleRow.centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: Layout.closeButtonSize),
            closeButton.heightAnchor.constraint(equalToConstant: Layout.closeButtonSize)
        ])

        header.addArrangedSubview(titleRow)
        topCardStack.addArrangedSubview(header)
    }

    private func makeCloseButton() -> UIControl {
        let control = UIControl()
        control.translatesAutoresizingMaskIntoConstraints = false
        control.addAction(UIAction { [weak self] _ in
            self?.onClose?()
        }, for: .touchUpInside)

        let circle = UIView()
        circle.backgroundColor = .viewBg
        circle.layer.cornerRadius = Layout.closeCircleSize / 2
        circle.isUserInteractionEnabled = false
        circle.translatesAutoresizingMaskIntoConstraints = false

        let imageView = UIImageView(image: AstroIcon.template("ic_action_close_rounded"))
        imageView.tintColor = .iconColorDefault
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = false
        imageView.translatesAutoresizingMaskIntoConstraints = false

        control.addSubview(circle)
        control.addSubview(imageView)

        NSLayoutConstraint.activate([
            circle.centerXAnchor.constraint(equalTo: control.centerXAnchor),
            circle.centerYAnchor.constraint(equalTo: control.centerYAnchor),
            circle.widthAnchor.constraint(equalToConstant: Layout.closeCircleSize),
            circle.heightAnchor.constraint(equalToConstant: Layout.closeCircleSize),
            imageView.centerXAnchor.constraint(equalTo: control.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: control.centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: Layout.closeIconSize),
            imageView.heightAnchor.constraint(equalToConstant: Layout.closeIconSize)
        ])

        return control
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

    private func addVisibleObjectsTitle() {
        let container = UIView()
        let title = UILabel()
        title.text = localizedString("astro_visible_objects")
        title.textColor = .textColorPrimary
        title.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        title.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(title)

        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(greaterThanOrEqualToConstant: 48),
            title.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: Layout.contentPadding),
            title.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -Layout.contentPadding),
            title.topAnchor.constraint(equalTo: container.topAnchor, constant: Layout.contentPaddingSmall),
            title.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -Layout.contentPaddingSmall)
        ])

        topCardStack.addArrangedSubview(container)
    }

    private func setupVisibleObjectsGrid() {
        visibleObjectsGridContent.axis = .vertical
        visibleObjectsGridContent.spacing = Layout.contentPaddingSmall
        visibleObjectsGridContent.layoutMargins = UIEdgeInsets(top: 0,
                                                               left: Layout.contentPadding,
                                                               bottom: Layout.contentPadding,
                                                               right: Layout.contentPadding)
        visibleObjectsGridContent.isLayoutMarginsRelativeArrangement = true
    }

    private func bindMapActions() {
        bindToggleMapActionCard(
            card: addActionCard(to: topButtonsRow),
            drawableEnabled: AstroIcon.template("ic_action_globe_view"),
            drawableDisabled: AstroIcon.template("ic_action_celestial_path"),
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
            drawableEnabled: AstroIcon.template("ic_map"),
            drawableDisabled: AstroIcon.template("ic_action_map_outlined"),
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
                iconName: "ic_action_planet_outlined",
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
                iconName: "ic_action_constellations",
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
                iconName: "ic_action_stars",
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
                iconName: "ic_action_nebulas",
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
                iconName: "ic_action_star_clusters",
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
                iconName: "ic_action_galaxy",
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
            iconName: "ic_action_target_direction_on",
            titleRes: "astro_directions",
            checked: current.showDirections,
            smallItem: false
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
            iconName: "ic_action_bookmark_filled",
            titleRes: "favorites_item",
            checked: current.showFavorites,
            smallItem: false
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
            iconName: "ic_action_target_path_on",
            titleRes: "astro_daily_path",
            checked: current.showCelestialPaths,
            showDivider: false,
            smallItem: false
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
            iconName: "ic_action_azimuthal_grid",
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
            iconName: "ic_action_meridian_line",
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
            iconName: "ic_action_equatorial_grid",
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
            iconName: "ic_action_eliptical_line",
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
            iconName: "ic_action_galaxy_equator",
            titleRes: "equator_line",
            checked: current.showEquatorLine,
            showDivider: false
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
            iconName: "ic_action_galaxy_line",
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
        iconName: String,
        titleRes: String,
        checked: Bool,
        showDivider: Bool = true,
        smallItem: Bool = true,
        onToggle: @escaping (Bool) -> Void
    ) {
        let row = AstroSwitchRow(iconName: iconName,
                                 title: localizedString(titleRes),
                                 checked: checked,
                                 showDivider: showDivider,
                                 smallItem: smallItem,
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

    private func sectionCard(title: String, contentStack sectionContentStack: UIStackView) -> UIStackView {
        let wrapper = UIStackView()
        wrapper.axis = .vertical
        wrapper.spacing = 0
        wrapper.backgroundColor = .groupBg
        wrapper.layer.cornerRadius = Layout.sectionCornerRadius
        wrapper.layer.masksToBounds = true

        let titleContainer = UIView()
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.textColor = .textColorPrimary
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleContainer.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            titleContainer.heightAnchor.constraint(greaterThanOrEqualToConstant: 48),
            titleLabel.leadingAnchor.constraint(equalTo: titleContainer.leadingAnchor, constant: Layout.contentPadding),
            titleLabel.trailingAnchor.constraint(equalTo: titleContainer.trailingAnchor, constant: -Layout.contentPadding),
            titleLabel.topAnchor.constraint(equalTo: titleContainer.topAnchor, constant: Layout.contentPaddingSmall),
            titleLabel.bottomAnchor.constraint(equalTo: titleContainer.bottomAnchor, constant: -Layout.contentPaddingSmall)
        ])

        sectionContentStack.axis = .vertical
        sectionContentStack.spacing = 0

        wrapper.addArrangedSubview(titleContainer)
        wrapper.addArrangedSubview(sectionContentStack)
        return wrapper
    }

    private func divider() -> UIView {
        let divider = UIView()
        divider.backgroundColor = .customSeparator
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.heightAnchor.constraint(equalToConstant: AstroConfigureTheme.separatorHeight).isActive = true
        return divider
    }

    private func redFilterIcon(selected: Bool) -> UIImage? {
        guard selected else {
            return AstroIcon.template("ic_action_red_filter_off")
        }
        return AstroIcon.layeredTemplate(baseName: "ic_action_red_filter_base_on",
                                         baseColor: .iconColorActive,
                                         overlayName: "ic_action_red_filter_overlay_on",
                                         overlayColor: .systemRed)
    }

    private func applyConfigChange(_ newConfig: AstronomyPluginSettings.StarMapConfig) {
        config = newConfig
        onConfigChanged?(newConfig)
    }

    private func applyTheme() {
        view.backgroundColor = .viewBg
        scrollView.backgroundColor = .viewBg
        topCard.backgroundColor = .groupBg
    }
}

private enum AstroConfigureTheme {
    static var separatorHeight: CGFloat {
        1 / UIScreen.main.scale
    }

    static var actionTileBackground: UIColor {
        UIColor(named: "groupBgColorSecondary") ?? .buttonBgColorSecondary
    }

    static var actionTileSelectedBackground: UIColor {
        UIColor(named: "cellBgColorSelected") ?? .buttonBgColorTertiary
    }
}

private final class AstroActionCard: UIControl {
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

    override var isHighlighted: Bool {
        didSet {
            alpha = isHighlighted ? 0.65 : 1
        }
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
    }

    private func setupView() {
        translatesAutoresizingMaskIntoConstraints = false
        layer.cornerRadius = 6
        layer.masksToBounds = true

        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.isUserInteractionEnabled = false

        titleLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 2
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.8
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.isUserInteractionEnabled = false

        addSubview(iconView)
        addSubview(titleLabel)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 66),
            iconView.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            iconView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 4),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -4),
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10)
        ])
    }

    private func applyStyle() {
        backgroundColor = checked ? AstroConfigureTheme.actionTileSelectedBackground : AstroConfigureTheme.actionTileBackground
        layer.borderWidth = 2
        layer.borderColor = checked ? UIColor.iconColorActive.cgColor : UIColor.clear.cgColor
        iconView.tintColor = .iconColorActive
        titleLabel.textColor = .iconColorActive
    }
}

private final class AstroSwitchRow: UIControl {
    private let iconName: String
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let switcher = UISwitch()
    private let dividerView = UIView()
    private let onToggle: (Bool) -> Void
    private var checked: Bool

    init(iconName: String,
         title: String,
         checked: Bool,
         showDivider: Bool,
         smallItem: Bool,
         onToggle: @escaping (Bool) -> Void) {
        self.iconName = iconName
        self.checked = checked
        self.onToggle = onToggle
        super.init(frame: .zero)
        setupView(title: title, checked: checked, showDivider: showDivider, smallItem: smallItem)
        applyStyle()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isHighlighted: Bool {
        didSet {
            alpha = isHighlighted ? 0.65 : 1
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.hasDifferentColorAppearance(comparedTo: traitCollection) == true {
            applyStyle()
        }
    }

    private func setupView(title: String, checked: Bool, showDivider: Bool, smallItem: Bool) {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .clear
        addAction(UIAction { [weak self] _ in
            self?.toggleFromRow()
        }, for: .touchUpInside)

        let contentView = UIView()
        contentView.isUserInteractionEnabled = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)

        iconView.image = AstroIcon.template(iconName)
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.text = title
        titleLabel.textColor = .textColorPrimary
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
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

        let dividerHeight = showDivider ? AstroConfigureTheme.separatorHeight : 0

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: smallItem ? 48 : 56),
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.bottomAnchor.constraint(equalTo: dividerView.topAnchor),
            dividerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 72),
            dividerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            dividerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            dividerView.heightAnchor.constraint(equalToConstant: dividerHeight),
            iconView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24),
            switcher.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            switcher.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 32),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: switcher.leadingAnchor, constant: -32),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
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
        if sendAction {
            onToggle(checked)
        }
    }

    private func applyStyle() {
        iconView.image = AstroIcon.template(iconName)
        iconView.tintColor = checked ? .iconColorActive : .iconColorDefault
        titleLabel.textColor = .textColorPrimary
        dividerView.backgroundColor = .customSeparator
    }
}
