//
//  AstroConfigureViewBottomSheet.swift
//  OsmAnd Maps
//
//  Created by Codex on 20.05.2026.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

import UIKit

final class AstroConfigureViewBottomSheet: UIViewController {
    var config = AstronomyPluginSettings.StarMapConfig()
    var commonConfig = AstronomyPluginSettings.CommonConfig()
    var onConfigChanged: ((AstronomyPluginSettings.StarMapConfig) -> Void)?
    var onCommonConfigChanged: ((AstronomyPluginSettings.CommonConfig) -> Void)?
    var onClose: (() -> Void)?

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(white: 0.03, alpha: 0.97)
        setupScrollView()
        rebuildContent()
    }

    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = true
        view.addSubview(scrollView)

        contentStack.axis = .vertical
        contentStack.spacing = 12
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -16),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])
    }

    private func rebuildContent() {
        contentStack.arrangedSubviews.forEach { view in
            contentStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        addHeader()
        addTopActionCards()
        addVisibleObjectsSection()
        addPersonalSection()
        addRenderingSection()
    }

    private func addHeader() {
        let header = UIStackView()
        header.axis = .vertical
        header.spacing = 4
        header.layoutMargins = UIEdgeInsets(top: 6, left: 16, bottom: 0, right: 8)
        header.isLayoutMarginsRelativeArrangement = true

        let handle = UIView()
        handle.backgroundColor = UIColor(white: 0.65, alpha: 0.75)
        handle.layer.cornerRadius = 1
        handle.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            handle.widthAnchor.constraint(equalToConstant: 28),
            handle.heightAnchor.constraint(equalToConstant: 2)
        ])

        let handleRow = UIStackView()
        handleRow.alignment = .center
        handleRow.addArrangedSubview(UIView())
        handleRow.addArrangedSubview(handle)
        handleRow.addArrangedSubview(UIView())
        header.addArrangedSubview(handleRow)

        let titleRow = UIStackView()
        titleRow.axis = .horizontal
        titleRow.alignment = .center
        titleRow.spacing = 12

        let title = UILabel()
        title.text = localizedString("astro_configure_view")
        title.textColor = .white
        title.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        titleRow.addArrangedSubview(title)
        titleRow.addArrangedSubview(UIView())

        let closeButton = UIButton(type: .system)
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = UIColor(white: 0.78, alpha: 1)
        closeButton.backgroundColor = UIColor(white: 0.12, alpha: 1)
        closeButton.layer.cornerRadius = 16
        closeButton.addAction(UIAction { [weak self] _ in
            self?.onClose?()
        }, for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            closeButton.widthAnchor.constraint(equalToConstant: 32),
            closeButton.heightAnchor.constraint(equalToConstant: 32)
        ])
        titleRow.addArrangedSubview(closeButton)
        header.addArrangedSubview(titleRow)

        contentStack.addArrangedSubview(header)
    }

    private func addTopActionCards() {
        let row = horizontalCardRow()
        row.addArrangedSubview(actionCard(title: config.is2DMode ? localizedString("map_2d") : localizedString("map_3d"),
                                          systemName: config.is2DMode ? "map" : "globe.europe.africa",
                                          selected: !config.is2DMode) { [weak self] in
            guard let self else {
                return
            }
            config.is2DMode.toggle()
            onConfigChanged?(config)
            rebuildContent()
        })
        row.addArrangedSubview(actionCard(title: localizedString("shared_string_map"),
                                          systemName: commonConfig.showRegularMap ? "map.fill" : "map",
                                          selected: commonConfig.showRegularMap) { [weak self] in
            guard let self else {
                return
            }
            commonConfig.showRegularMap.toggle()
            onCommonConfigChanged?(commonConfig)
            rebuildContent()
        })
        row.addArrangedSubview(actionCard(title: localizedString("red_filter"),
                                          systemName: config.showRedFilter ? "circle.fill" : "circle",
                                          selected: config.showRedFilter) { [weak self] in
            guard let self else {
                return
            }
            config.showRedFilter.toggle()
            onConfigChanged?(config)
            rebuildContent()
        })
        contentStack.addArrangedSubview(row)
    }

    private func addVisibleObjectsSection() {
        let section = sectionCard(title: localizedString("astro_visible_objects"))
        section.addArrangedSubview(gridRow([
            actionCard(title: localizedString("astro_solar_system"),
                       systemName: "circle.grid.cross",
                       selected: config.showSun && config.showMoon && config.showPlanets) { [weak self] in
                self?.toggleSolarSystem()
            },
            actionCard(title: localizedString("astro_constellations"),
                       systemName: "point.3.connected.trianglepath.dotted",
                       selected: config.showConstellations) { [weak self] in
                self?.mutateConfig { $0.showConstellations.toggle() }
            },
            actionCard(title: localizedString("astro_stars"),
                       systemName: "sparkles",
                       selected: config.showStars) { [weak self] in
                self?.mutateConfig { $0.showStars.toggle() }
            }
        ]))
        section.addArrangedSubview(gridRow([
            actionCard(title: localizedString("astro_nebulas"),
                       systemName: "cloud",
                       selected: config.showNebulae) { [weak self] in
                self?.mutateConfig { $0.showNebulae.toggle() }
            },
            actionCard(title: localizedString("astro_star_clusters"),
                       systemName: "circle.hexagongrid",
                       selected: config.showOpenClusters && config.showGlobularClusters) { [weak self] in
                self?.toggleStarClusters()
            },
            actionCard(title: localizedString("astro_deep_sky"),
                       systemName: "circle.dotted",
                       selected: config.showGalaxies && config.showBlackHoles && config.showGalaxyClusters) { [weak self] in
                self?.toggleDeepSky()
            }
        ]))
        contentStack.addArrangedSubview(section)
    }

    private func addPersonalSection() {
        let section = sectionCard(title: localizedString("personal_category_name"))
        section.addArrangedSubview(switchRow(title: localizedString("astro_directions"),
                                             systemName: "location.north.line",
                                             isOn: config.showDirections) { [weak self] checked in
            self?.mutateConfig { $0.showDirections = checked }
        })
        section.addArrangedSubview(switchRow(title: localizedString("favorites_item"),
                                             systemName: "bookmark.fill",
                                             isOn: config.showFavorites) { [weak self] checked in
            self?.mutateConfig { $0.showFavorites = checked }
        })
        section.addArrangedSubview(switchRow(title: localizedString("astro_daily_path"),
                                             systemName: "point.topleft.down.curvedto.point.bottomright.up",
                                             isOn: config.showCelestialPaths) { [weak self] checked in
            self?.mutateConfig { $0.showCelestialPaths = checked }
        })
        contentStack.addArrangedSubview(section)
    }

    private func addRenderingSection() {
        let section = sectionCard(title: localizedString("astro_rendering"))
        section.addArrangedSubview(switchRow(title: localizedString("azimuthal_grid"),
                                             systemName: "scope",
                                             isOn: config.showAzimuthalGrid) { [weak self] checked in
            self?.mutateConfig { $0.showAzimuthalGrid = checked }
        })
        section.addArrangedSubview(switchRow(title: localizedString("meridian_line"),
                                             systemName: "line.diagonal",
                                             isOn: config.showMeridianLine) { [weak self] checked in
            self?.mutateConfig { $0.showMeridianLine = checked }
        })
        section.addArrangedSubview(switchRow(title: localizedString("equatorial_grid"),
                                             systemName: "globe",
                                             isOn: config.showEquatorialGrid) { [weak self] checked in
            self?.mutateConfig { $0.showEquatorialGrid = checked }
        })
        section.addArrangedSubview(switchRow(title: localizedString("ecliptic_line"),
                                             systemName: "circle.lefthalf.filled",
                                             isOn: config.showEclipticLine) { [weak self] checked in
            self?.mutateConfig { $0.showEclipticLine = checked }
        })
        section.addArrangedSubview(switchRow(title: localizedString("equator_line"),
                                             systemName: "circle.grid.cross",
                                             isOn: config.showEquatorLine) { [weak self] checked in
            self?.mutateConfig { $0.showEquatorLine = checked }
        })
        section.addArrangedSubview(switchRow(title: localizedString("galactic_line"),
                                             systemName: "scribble.variable",
                                             isOn: config.showGalacticLine) { [weak self] checked in
            self?.mutateConfig { $0.showGalacticLine = checked }
        })
        contentStack.addArrangedSubview(section)
    }

    private func horizontalCardRow() -> UIStackView {
        let row = UIStackView()
        row.axis = .horizontal
        row.distribution = .fillEqually
        row.spacing = 12
        row.layoutMargins = UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16)
        row.isLayoutMarginsRelativeArrangement = true
        return row
    }

    private func gridRow(_ cards: [UIView]) -> UIStackView {
        let row = UIStackView()
        row.axis = .horizontal
        row.distribution = .fillEqually
        row.spacing = 12
        for card in cards {
            row.addArrangedSubview(card)
        }
        return row
    }

    private func sectionCard(title: String) -> UIStackView {
        let wrapper = UIStackView()
        wrapper.axis = .vertical
        wrapper.spacing = 10
        wrapper.layoutMargins = UIEdgeInsets(top: 14, left: 16, bottom: 16, right: 16)
        wrapper.isLayoutMarginsRelativeArrangement = true
        wrapper.backgroundColor = UIColor(white: 0.07, alpha: 1)
        wrapper.layer.cornerRadius = 12

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.textColor = .white
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        wrapper.addArrangedSubview(titleLabel)
        return wrapper
    }

    private func actionCard(title: String, systemName: String, selected: Bool, action: @escaping () -> Void) -> UIControl {
        let control = UIControl()
        control.translatesAutoresizingMaskIntoConstraints = false
        control.backgroundColor = selected ? .systemBlue : UIColor(white: 0.12, alpha: 1)
        control.layer.cornerRadius = 10
        control.layer.borderWidth = selected ? 0 : 1
        control.layer.borderColor = UIColor(white: 0.24, alpha: 1).cgColor
        control.addAction(UIAction { _ in action() }, for: .touchUpInside)

        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 6
        stack.isUserInteractionEnabled = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        control.addSubview(stack)

        let icon = UIImageView(image: UIImage(systemName: systemName))
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.tintColor = selected ? .white : .systemBlue
        icon.contentMode = .scaleAspectFit
        NSLayoutConstraint.activate([
            icon.widthAnchor.constraint(equalToConstant: 22),
            icon.heightAnchor.constraint(equalToConstant: 22)
        ])
        stack.addArrangedSubview(icon)

        let label = UILabel()
        label.text = title
        label.textColor = selected ? .white : UIColor(white: 0.88, alpha: 1)
        label.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        label.textAlignment = .center
        label.numberOfLines = 2
        stack.addArrangedSubview(label)

        NSLayoutConstraint.activate([
            control.heightAnchor.constraint(equalToConstant: 66),
            stack.leadingAnchor.constraint(equalTo: control.leadingAnchor, constant: 6),
            stack.trailingAnchor.constraint(equalTo: control.trailingAnchor, constant: -6),
            stack.centerYAnchor.constraint(equalTo: control.centerYAnchor)
        ])
        return control
    }

    private func switchRow(title: String, systemName: String, isOn: Bool, action: @escaping (Bool) -> Void) -> UIView {
        let row = UIControl()
        row.translatesAutoresizingMaskIntoConstraints = false
        row.backgroundColor = .clear
        row.addAction(UIAction { _ in
            action(!isOn)
        }, for: .touchUpInside)

        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(stack)

        let icon = UIImageView(image: UIImage(systemName: systemName))
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.tintColor = isOn ? .systemBlue : UIColor(white: 0.55, alpha: 1)
        icon.contentMode = .scaleAspectFit
        NSLayoutConstraint.activate([
            icon.widthAnchor.constraint(equalToConstant: 24),
            icon.heightAnchor.constraint(equalToConstant: 24)
        ])
        stack.addArrangedSubview(icon)

        let label = UILabel()
        label.text = title
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        stack.addArrangedSubview(label)
        stack.addArrangedSubview(UIView())

        let toggle = UISwitch()
        toggle.isOn = isOn
        toggle.addAction(UIAction { _ in
            action(toggle.isOn)
        }, for: .valueChanged)
        stack.addArrangedSubview(toggle)

        NSLayoutConstraint.activate([
            row.heightAnchor.constraint(equalToConstant: 48),
            stack.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            stack.topAnchor.constraint(equalTo: row.topAnchor),
            stack.bottomAnchor.constraint(equalTo: row.bottomAnchor)
        ])
        return row
    }

    private func mutateConfig(_ mutation: (inout AstronomyPluginSettings.StarMapConfig) -> Void) {
        mutation(&config)
        onConfigChanged?(config)
        rebuildContent()
    }

    private func toggleSolarSystem() {
        let newValue = !(config.showSun && config.showMoon && config.showPlanets)
        mutateConfig {
            $0.showSun = newValue
            $0.showMoon = newValue
            $0.showPlanets = newValue
        }
    }

    private func toggleStarClusters() {
        let newValue = !(config.showOpenClusters && config.showGlobularClusters)
        mutateConfig {
            $0.showOpenClusters = newValue
            $0.showGlobularClusters = newValue
        }
    }

    private func toggleDeepSky() {
        let newValue = !(config.showGalaxies && config.showBlackHoles && config.showGalaxyClusters)
        mutateConfig {
            $0.showGalaxies = newValue
            $0.showBlackHoles = newValue
            $0.showGalaxyClusters = newValue
        }
    }
}
