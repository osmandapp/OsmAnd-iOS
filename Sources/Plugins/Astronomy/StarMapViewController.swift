//
//  StarMapViewController.swift
//  OsmAnd Maps
//
//  Created by Codex on 19.05.2026.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

import CoreLocation
import OsmAndShared
import UIKit

final class StarMapViewController: UIViewController, StarViewDelegate {
    private enum Layout {
        static let contentPadding: CGFloat = 16
        static let buttonSize: CGFloat = 48
        static let smallButtonSize: CGFloat = 40
        static let magnitudeButtonHeight: CGFloat = 76
        static let magnitudeSliderWidth: CGFloat = 240
        static let transparencySliderHeight: CGFloat = 150
        static let regularMapHeight: CGFloat = 300
        static let regularMapHeightLandscape: CGFloat = 110
        static let regularMapHeightFractionForPad: CGFloat = 0.33
        static let regularMapHeightFractionForPadLandscape: CGFloat = 0.3
        static let maxMagnitude: Double = 7.0
        static let leftPanelWidth: CGFloat = 393
    }
    private var settings: AstronomyPluginSettings
    private let plugin: AstronomyPlugin
    private let dataProvider: AstroDataProvider
    private let viewModel: StarObjectsViewModel

    private let mainLayout = UIView()
    private let starView = StarView()
    private let regularMapContainer = UIView()
    private let mapControlsContainer = StarMapControlsContainer()
    private let timeSelectionView = DateTimeSelectionView()
    private let timeControlCard = UIView()
    private let timeControlButton = StarMapTimeControlButton()
    private let resetTimeButton = StarMapResetButton()
    private let arModeButton = StarMapButton()
    private let cameraButton = StarMapButton()
    private let transparencySlider = UISlider()
    private let sliderContainer = UIView()
    private let resetFovButton = StarMapButton()
    private let magnitudeFilterButton = UIControl()
    private let magnitudeFilterIcon = UIImageView()
    private let magnitudeFilterText = UILabel()
    private let magnitudeSliderCard = UIView()
    private let magnitudeSlider = UISlider()
    private let magnitudeSliderTitle = UILabel()
    private let magnitudeSliderValue = UILabel()
    private let closeButton = StarMapButton()
    private let settingsButton = StarMapButton()
    private let searchButton = StarMapButton()
    private let compassButton = StarCompassButton()

    private let arModeHelper = StarMapARModeHelper()
    private let cameraHelper = StarMapCameraHelper()

    private var autoTimeUpdateTimer: Timer?
    private var isTimeAutoUpdateEnabled = true
    private var currentDate = Date()
    private var selectedObject: SkyObject?
    private var regularMapVisible = false
    private var previousAltitude = 45.0
    private var previousAzimuth = 0.0
    private var previousViewAngle = 150.0
    private var manualAzimuth = true
    private var lastUpdatedAzimuth = -1.0
    private var objectInfoController: AstroContextMenuViewController?
    private var objectInfoNavigationController: UINavigationController?
    private var isDismissingObjectInfoSheet = false
    private var configureSheetController: AstroConfigureViewBottomSheet?
    private var configureSheetNavigationController: UINavigationController?
    private var isDismissingConfigureSheet = false
    private var searchViewController: StarMapSearchViewController?
    private var searchNavigationController: UINavigationController?
    private var regularMapHeightConstraint: NSLayoutConstraint?
    private var mapLocationObserver: OAAutoObserverProxy?
    private var dayNightModeObserver: OAAutoObserverProxy?
    private var screenOrientationObserver: NSObjectProtocol?
    private var leftPanelLeadingConstraint: NSLayoutConstraint?
    private let mapVisibleAreaGuide = UILayoutGuide()
    private var mapVisibleAreaLeadingConstraint: NSLayoutConstraint?

    private var mapControlsLeadingInset: CGFloat {
        embeddedLeftPanelNavigationController != nil && OAUtilities.isIPad()
            ? Layout.contentPadding + Layout.leftPanelWidth
            : 0
    }

    private var embeddedLeftPanelNavigationController: UINavigationController? {
        if let navigationController = searchNavigationController, navigationController.parent === self {
            return navigationController
        }
        if let navigationController = configureSheetNavigationController, navigationController.parent === self {
            return navigationController
        }
        if let navigationController = objectInfoNavigationController, navigationController.parent === self {
            return navigationController
        }
        return nil
    }

    init(plugin: AstronomyPlugin) {
        let loadedSettings = AstronomyPluginSettings.load()
        let provider = plugin.dataProvider
        self.plugin = plugin
        settings = loadedSettings
        dataProvider = provider
        viewModel = StarObjectsViewModel(provider: provider, settings: loadedSettings)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        mapLocationObserver?.detach()
        dayNightModeObserver?.detach()
        if let screenOrientationObserver {
            NotificationCenter.default.removeObserver(screenOrientationObserver)
        }
        restoreRegularMapIfNeeded(refresh: false)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        setupLayout()
        setupControls()
        setupHelpers()
        setupListeners()
        applySettings(settings.starMap)
        updateRegularMapVisibility(settings.common.showRegularMap)
        updateStarMap(updateAzimuth: true)

        viewModel.onDataChanged = { [weak self] in
            self?.syncObjectsToStarView()
            self?.updateMagnitudeControls()
            self?.updateTimeControls()
        }
        viewModel.load(preferredLocale: OsmAndApp.swiftInstance()?.getLanguageCode())
        setTimeAutoUpdateEnabled(true)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if regularMapVisible {
            attachRegularMapIfNeeded()
        }
        arModeHelper.onResume()
        cameraHelper.onResume()
        if arModeHelper.isArModeEnabled {
            updateArModeUI(true)
        }
        if isTimeAutoUpdateEnabled {
            syncCurrentTimeForAutoUpdate(animate: true)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopAutoTimeUpdate()
        saveStarMapSettings()
        arModeHelper.onPause()
        cameraHelper.onPause()
        starView.isCameraMode = false
        restoreRegularMapIfNeeded(refresh: true)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateRegularMapLayout()
        layoutRegularMapRenderer()
        cameraHelper.layoutPreview()
    }

    private func setupLayout() {
        mainLayout.translatesAutoresizingMaskIntoConstraints = false
        starView.translatesAutoresizingMaskIntoConstraints = false
        regularMapContainer.translatesAutoresizingMaskIntoConstraints = false
        regularMapContainer.clipsToBounds = true
        mapControlsContainer.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(mainLayout)
        mainLayout.addSubview(starView)
        mainLayout.addSubview(regularMapContainer)
        mainLayout.addSubview(mapControlsContainer)

        let regularMapHeightConstraint = regularMapContainer.heightAnchor.constraint(equalToConstant: 0)
        self.regularMapHeightConstraint = regularMapHeightConstraint

        NSLayoutConstraint.activate([
            mainLayout.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mainLayout.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mainLayout.topAnchor.constraint(equalTo: view.topAnchor),
            mainLayout.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            starView.leadingAnchor.constraint(equalTo: mainLayout.leadingAnchor),
            starView.trailingAnchor.constraint(equalTo: mainLayout.trailingAnchor),
            starView.topAnchor.constraint(equalTo: mainLayout.topAnchor),
            starView.bottomAnchor.constraint(equalTo: regularMapContainer.topAnchor),

            regularMapContainer.leadingAnchor.constraint(equalTo: mainLayout.leadingAnchor),
            regularMapContainer.trailingAnchor.constraint(equalTo: mainLayout.trailingAnchor),
            regularMapContainer.bottomAnchor.constraint(equalTo: mainLayout.bottomAnchor),
            regularMapHeightConstraint,

            mapControlsContainer.leadingAnchor.constraint(equalTo: mainLayout.leadingAnchor),
            mapControlsContainer.trailingAnchor.constraint(equalTo: mainLayout.trailingAnchor),
            mapControlsContainer.topAnchor.constraint(equalTo: mainLayout.topAnchor),
            mapControlsContainer.bottomAnchor.constraint(equalTo: mainLayout.bottomAnchor)
        ])

        mapControlsContainer.addLayoutGuide(mapVisibleAreaGuide)
        let mapVisibleLeading = mapVisibleAreaGuide.leadingAnchor.constraint(equalTo: mapControlsContainer.safeAreaLayoutGuide.leadingAnchor)
        mapVisibleAreaLeadingConstraint = mapVisibleLeading
        NSLayoutConstraint.activate([
            mapVisibleLeading,
            mapVisibleAreaGuide.trailingAnchor.constraint(equalTo: mapControlsContainer.safeAreaLayoutGuide.trailingAnchor),
            mapVisibleAreaGuide.topAnchor.constraint(equalTo: mapControlsContainer.topAnchor),
            mapVisibleAreaGuide.bottomAnchor.constraint(equalTo: mapControlsContainer.bottomAnchor)
        ])
    }

    private func setupControls() {
        setupStarView()
        setupCompassAndLeftControls()
        setupRightControls()
        setupTimeControls()
        setupMagnitudeControls()
        setupCameraControls()
        updateMapControlThemes()
    }

    private func setupStarView() {
        starView.delegate = self
        starView.viewModel = viewModel
        starView.settings = settings
    }

    private func setupCompassAndLeftControls() {
        addRoundButton(compassButton, accessibilityLabel: localizedString("map_widget_compass"))
        compassButton.onSingleTap = { [weak self] in self?.setAzimuth(0, animate: true) }

        addRoundButton(arModeButton, iconName: "ic_custom_view_in_ar", accessibilityLabel: localizedString("astro_ar"))
        arModeButton.addTarget(self, action: #selector(toggleARMode), for: .touchUpInside)

        addRoundButton(cameraButton, iconName: "ic_custom_device", accessibilityLabel: localizedString("astro_camera"))
        cameraButton.addTarget(self, action: #selector(toggleCamera), for: .touchUpInside)
        cameraButton.isHidden = true

        addRoundButton(searchButton, iconName: "ic_custom_search", accessibilityLabel: localizedString("shared_string_search"))
        searchButton.addTarget(self, action: #selector(showSearchDialog), for: .touchUpInside)

        NSLayoutConstraint.activate([
            compassButton.leadingAnchor.constraint(equalTo: mapVisibleAreaGuide.leadingAnchor, constant: Layout.contentPadding),
            compassButton.topAnchor.constraint(equalTo: mapControlsContainer.safeAreaLayoutGuide.topAnchor, constant: Layout.contentPadding),

            arModeButton.centerXAnchor.constraint(equalTo: compassButton.centerXAnchor),
            arModeButton.topAnchor.constraint(equalTo: compassButton.bottomAnchor, constant: Layout.contentPadding),

            cameraButton.centerXAnchor.constraint(equalTo: arModeButton.centerXAnchor),
            cameraButton.topAnchor.constraint(equalTo: arModeButton.bottomAnchor, constant: Layout.contentPadding),

            searchButton.centerXAnchor.constraint(equalTo: compassButton.centerXAnchor),
            searchButton.bottomAnchor.constraint(equalTo: mapControlsContainer.safeAreaLayoutGuide.bottomAnchor, constant: -Layout.contentPadding)
        ])
    }

    private func setupRightControls() {
        addRoundButton(closeButton, iconName: "ic_navbar_close", accessibilityLabel: localizedString("shared_string_close"))
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)

        addRoundButton(settingsButton, iconName: "ic_custom_overlay_map", accessibilityLabel: localizedString("shared_string_settings"))
        settingsButton.addTarget(self, action: #selector(showConfigureSheet), for: .touchUpInside)

        NSLayoutConstraint.activate([
            closeButton.trailingAnchor.constraint(equalTo: mapControlsContainer.safeAreaLayoutGuide.trailingAnchor, constant: -Layout.contentPadding),
            closeButton.topAnchor.constraint(equalTo: mapControlsContainer.safeAreaLayoutGuide.topAnchor, constant: Layout.contentPadding),

            settingsButton.trailingAnchor.constraint(equalTo: mapControlsContainer.safeAreaLayoutGuide.trailingAnchor, constant: -Layout.contentPadding),
            settingsButton.bottomAnchor.constraint(equalTo: mapControlsContainer.safeAreaLayoutGuide.bottomAnchor, constant: -Layout.contentPadding)
        ])
    }

    private func setupTimeControls() {
        let nightMode = OADayNightHelper.instance().isNightMode()
        timeControlCard.translatesAutoresizingMaskIntoConstraints = false
        timeControlCard.backgroundColor = StarMapControlTheme.defaultBackground(nightMode: nightMode, alpha: 1)
        timeControlCard.layer.cornerRadius = Layout.buttonSize / 2
        timeControlCard.layer.shadowColor = UIColor.black.cgColor
        timeControlCard.layer.shadowOpacity = 0.16
        timeControlCard.layer.shadowRadius = 6
        timeControlCard.layer.shadowOffset = CGSize(width: 0, height: 2)
        mapControlsContainer.addSubview(timeControlCard)

        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 4
        stack.layoutMargins = UIEdgeInsets(top: 0, left: 6, bottom: 0, right: 6)
        stack.isLayoutMarginsRelativeArrangement = true
        stack.translatesAutoresizingMaskIntoConstraints = false
        timeControlCard.addSubview(stack)

        timeControlButton.setImage(AstroIcon.template("ic_action_time"), for: .normal)
        timeControlButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        timeControlButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        timeControlButton.addTarget(self, action: #selector(toggleTimeSelection), for: .touchUpInside)
        stack.addArrangedSubview(timeControlButton)

        resetTimeButton.addTarget(self, action: #selector(resetTimeButtonPressed), for: .touchUpInside)
        resetTimeButton.isHidden = true
        resetTimeButton.widthAnchor.constraint(equalToConstant: Layout.smallButtonSize).isActive = true
        resetTimeButton.heightAnchor.constraint(equalToConstant: Layout.smallButtonSize).isActive = true
        stack.addArrangedSubview(resetTimeButton)

        timeSelectionView.translatesAutoresizingMaskIntoConstraints = false
        timeSelectionView.isHidden = true
        mapControlsContainer.addSubview(timeSelectionView)

        NSLayoutConstraint.activate([
            timeControlCard.centerXAnchor.constraint(equalTo: mapVisibleAreaGuide.centerXAnchor),
            timeControlCard.bottomAnchor.constraint(equalTo: mapControlsContainer.safeAreaLayoutGuide.bottomAnchor, constant: -Layout.contentPadding),
            timeControlCard.heightAnchor.constraint(equalToConstant: Layout.buttonSize),

            stack.leadingAnchor.constraint(equalTo: timeControlCard.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: timeControlCard.trailingAnchor),
            stack.topAnchor.constraint(equalTo: timeControlCard.topAnchor),
            stack.bottomAnchor.constraint(equalTo: timeControlCard.bottomAnchor),

            timeSelectionView.centerXAnchor.constraint(equalTo: mapVisibleAreaGuide.centerXAnchor),
            timeSelectionView.bottomAnchor.constraint(equalTo: timeControlCard.topAnchor, constant: -Layout.contentPadding)
        ])
    }

    private func setupMagnitudeControls() {
        let nightMode = OADayNightHelper.instance().isNightMode()
        magnitudeFilterButton.translatesAutoresizingMaskIntoConstraints = false
        magnitudeFilterButton.backgroundColor = StarMapControlTheme.defaultBackground(nightMode: nightMode, alpha: 0.92)
        magnitudeFilterButton.layer.cornerRadius = Layout.buttonSize / 2
        magnitudeFilterButton.layer.shadowColor = UIColor.black.cgColor
        magnitudeFilterButton.layer.shadowOpacity = 0.16
        magnitudeFilterButton.layer.shadowRadius = 6
        magnitudeFilterButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        magnitudeFilterButton.addAction(UIAction { [weak self] _ in
            self?.toggleMagnitudeSlider()
        }, for: .touchUpInside)
        mapControlsContainer.addSubview(magnitudeFilterButton)

        let filterStack = UIStackView()
        filterStack.axis = .vertical
        filterStack.alignment = .center
        filterStack.spacing = 4
        filterStack.isUserInteractionEnabled = false
        filterStack.translatesAutoresizingMaskIntoConstraints = false
        magnitudeFilterButton.addSubview(filterStack)

        magnitudeFilterIcon.image = .icCustomMagnitude
        magnitudeFilterIcon.tintColor = StarMapControlTheme.foreground(active: false, nightMode: nightMode)
        magnitudeFilterIcon.contentMode = .scaleAspectFit
        magnitudeFilterIcon.widthAnchor.constraint(equalToConstant: 30).isActive = true
        magnitudeFilterIcon.heightAnchor.constraint(equalToConstant: 30).isActive = true
        filterStack.addArrangedSubview(magnitudeFilterIcon)

        magnitudeFilterText.textColor = StarMapControlTheme.foreground(active: false, nightMode: nightMode)
        magnitudeFilterText.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        filterStack.addArrangedSubview(magnitudeFilterText)

        magnitudeSliderCard.translatesAutoresizingMaskIntoConstraints = false
        magnitudeSliderCard.backgroundColor = StarMapControlTheme.defaultBackground(nightMode: nightMode, alpha: 0.94)
        magnitudeSliderCard.layer.cornerRadius = Layout.contentPadding
        magnitudeSliderCard.layer.shadowColor = UIColor.black.cgColor
        magnitudeSliderCard.layer.shadowOpacity = 0.16
        magnitudeSliderCard.layer.shadowRadius = 6
        magnitudeSliderCard.layer.shadowOffset = CGSize(width: 0, height: 2)
        magnitudeSliderCard.isHidden = true
        mapControlsContainer.addSubview(magnitudeSliderCard)

        let sliderStack = UIStackView()
        sliderStack.axis = .vertical
        sliderStack.spacing = 6
        sliderStack.layoutMargins = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)
        sliderStack.isLayoutMarginsRelativeArrangement = true
        sliderStack.translatesAutoresizingMaskIntoConstraints = false
        magnitudeSliderCard.addSubview(sliderStack)

        let sliderHeader = UIStackView()
        sliderHeader.axis = .horizontal
        sliderHeader.alignment = .center
        sliderHeader.spacing = 8
        magnitudeSliderTitle.text = localizedString("astro_min_magnitude")
        magnitudeSliderTitle.textColor = StarMapControlTheme.textColor(nightMode: nightMode)
        magnitudeSliderTitle.font = UIFont.systemFont(ofSize: 14)
        sliderHeader.addArrangedSubview(magnitudeSliderTitle)
        sliderHeader.addArrangedSubview(UIView())
        magnitudeSliderValue.textColor = StarMapControlTheme.activeBackground()
        magnitudeSliderValue.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        sliderHeader.addArrangedSubview(magnitudeSliderValue)
        sliderStack.addArrangedSubview(sliderHeader)

        magnitudeSlider.minimumValue = -1
        magnitudeSlider.maximumValue = Float(Layout.maxMagnitude)
        magnitudeSlider.addTarget(self, action: #selector(magnitudeChanged), for: .valueChanged)
        sliderStack.addArrangedSubview(magnitudeSlider)

        NSLayoutConstraint.activate([
            magnitudeFilterButton.widthAnchor.constraint(equalToConstant: Layout.buttonSize),
            magnitudeFilterButton.heightAnchor.constraint(equalToConstant: Layout.magnitudeButtonHeight),
            magnitudeFilterButton.centerXAnchor.constraint(equalTo: settingsButton.centerXAnchor),
            magnitudeFilterButton.bottomAnchor.constraint(equalTo: settingsButton.topAnchor, constant: -Layout.contentPadding),

            filterStack.centerXAnchor.constraint(equalTo: magnitudeFilterButton.centerXAnchor),
            filterStack.centerYAnchor.constraint(equalTo: magnitudeFilterButton.centerYAnchor),

            magnitudeSliderCard.widthAnchor.constraint(equalToConstant: Layout.magnitudeSliderWidth),
            magnitudeSliderCard.heightAnchor.constraint(equalTo: magnitudeFilterButton.heightAnchor),
            magnitudeSliderCard.trailingAnchor.constraint(equalTo: magnitudeFilterButton.leadingAnchor, constant: -Layout.contentPadding),
            magnitudeSliderCard.topAnchor.constraint(equalTo: magnitudeFilterButton.topAnchor),

            sliderStack.leadingAnchor.constraint(equalTo: magnitudeSliderCard.leadingAnchor),
            sliderStack.trailingAnchor.constraint(equalTo: magnitudeSliderCard.trailingAnchor),
            sliderStack.topAnchor.constraint(equalTo: magnitudeSliderCard.topAnchor),
            sliderStack.bottomAnchor.constraint(equalTo: magnitudeSliderCard.bottomAnchor)
        ])
    }

    private func setupCameraControls() {
        sliderContainer.translatesAutoresizingMaskIntoConstraints = false
        sliderContainer.isHidden = true
        mapControlsContainer.addSubview(sliderContainer)

        transparencySlider.minimumValue = 0
        transparencySlider.maximumValue = 100
        transparencySlider.value = 50
        transparencySlider.transform = CGAffineTransform(rotationAngle: -.pi / 2)
        transparencySlider.translatesAutoresizingMaskIntoConstraints = false
        transparencySlider.addTarget(self, action: #selector(transparencyChanged), for: .valueChanged)
        sliderContainer.addSubview(transparencySlider)

        addRoundButton(resetFovButton, iconName: "ic_custom_reset", accessibilityLabel: localizedString("shared_string_reset"))
        resetFovButton.addTarget(self, action: #selector(resetFov), for: .touchUpInside)
        resetFovButton.isHidden = true

        let cameraSliderTopConstraint = sliderContainer.topAnchor.constraint(equalTo: cameraButton.bottomAnchor, constant: Layout.contentPadding)
        cameraSliderTopConstraint.priority = .defaultHigh

        NSLayoutConstraint.activate([
            sliderContainer.widthAnchor.constraint(equalToConstant: Layout.buttonSize),
            sliderContainer.heightAnchor.constraint(equalToConstant: Layout.transparencySliderHeight),
            sliderContainer.centerXAnchor.constraint(equalTo: cameraButton.centerXAnchor),
            cameraSliderTopConstraint,
            sliderContainer.topAnchor.constraint(greaterThanOrEqualTo: mapControlsContainer.safeAreaLayoutGuide.topAnchor, constant: Layout.contentPadding),

            transparencySlider.centerXAnchor.constraint(equalTo: sliderContainer.centerXAnchor),
            transparencySlider.centerYAnchor.constraint(equalTo: sliderContainer.centerYAnchor),
            transparencySlider.widthAnchor.constraint(equalToConstant: Layout.transparencySliderHeight),
            transparencySlider.heightAnchor.constraint(equalToConstant: 40),

            resetFovButton.centerXAnchor.constraint(equalTo: sliderContainer.centerXAnchor),
            resetFovButton.topAnchor.constraint(equalTo: sliderContainer.bottomAnchor, constant: 8),
            resetFovButton.bottomAnchor.constraint(lessThanOrEqualTo: mapControlsContainer.safeAreaLayoutGuide.bottomAnchor, constant: -Layout.contentPadding)
        ])
    }

    private func addRoundButton(_ button: StarMapButton, iconName: String? = nil, accessibilityLabel: String) {
        button.translatesAutoresizingMaskIntoConstraints = false
        if let iconName {
            button.setIcon(iconName: iconName, accessibilityLabel: accessibilityLabel)
        } else {
            button.accessibilityLabel = accessibilityLabel
        }
        mapControlsContainer.addSubview(button)
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: Layout.buttonSize),
            button.heightAnchor.constraint(equalToConstant: Layout.buttonSize)
        ])
    }

    private func setupHelpers() {
        cameraHelper.bind(starView: starView)
        arModeHelper.onOrientationChanged = { [weak self] azimuth, altitude, roll in
            self?.starView.setCameraOrientation(azimuth: azimuth, altitude: altitude, roll: roll)
        }
        arModeHelper.onArModeChanged = { [weak self] enabled in
            guard let self else {
                return
            }
            updateArModeUI(enabled)
            if !enabled {
                manualAzimuth = true
            }
        }
        arModeHelper.onUnavailable = { [weak self] in
            self?.showMessage(localizedString("astro_ar_unavailable"))
        }
        cameraHelper.onUnavailable = { [weak self] message in
            self?.updateCameraUI(false)
            self?.showMessage(message)
        }
        cameraHelper.onCameraStateChanged = { [weak self] enabled in
            guard let self else {
                return
            }
            updateCameraUI(enabled)
            if enabled && !arModeHelper.isArModeEnabled {
                arModeHelper.toggleArMode(enable: true)
            }
        }
    }

    private func setupListeners() {
        timeSelectionView.setOnDateTimeChangeListener { [weak self] date in
            self?.setTimeAutoUpdateEnabled(false)
            self?.updateTime(date, animate: true)
        }
        starView.setOnObjectClickListener { [weak self] object in
            self?.selectedObject = object
            if let object {
                self?.showObjectInfo(object)
            } else if self?.starView.getSelectedConstellationItem() == nil {
                self?.hideBottomSheet()
            }
        }
        starView.setOnConstellationClickListener { [weak self] constellation in
            if let constellation {
                self?.selectedObject = constellation
                self?.showObjectInfo(constellation)
            } else if self?.selectedObject == nil {
                self?.hideBottomSheet()
            }
        }
        starView.onAzimuthManualChangeListener = { [weak self] azimuth in
            guard let self, !cameraHelper.isCameraOverlayEnabled else {
                return
            }
            if arModeHelper.isArModeEnabled {
                arModeHelper.toggleArMode(enable: false)
            }
            manualAzimuth = true
            compassButton.update(mapRotation: CGFloat(-azimuth))
        }
        starView.onViewAngleChangeListener = { [weak self] fov in
            self?.cameraHelper.updateCameraZoom(fov: fov)
        }

        if let mapObservable = currentMapViewController()?.mapObservable {
            mapLocationObserver = OAAutoObserverProxy(self,
                                                      withHandler: #selector(onMapLocationChanged),
                                                      andObserve: mapObservable)
        }
        dayNightModeObserver = OAAutoObserverProxy(self,
                                                   withHandler: #selector(onDayNightModeChanged),
                                                   andObserve: OsmAndApp.swiftInstance().dayNightModeObservable)
        screenOrientationObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name(ScreenOrientationHelper.screenOrientationChangedKey),
                                                                           object: nil,
                                                                           queue: .main) { [weak self] _ in
            self?.cameraHelper.layoutPreview()
        }
    }

    private func syncObjectsToStarView() {
        starView.setSkyObjects(viewModel.skyObjects)
        starView.setConstellations(viewModel.constellations)
        starView.setNeedsDisplay()
    }

    private func applySettings(_ config: AstronomyPluginSettings.StarMapConfig) {
        let shouldApply2DMode = starView.is2DMode != config.is2DMode
        starView.showAzimuthalGrid = config.showAzimuthalGrid
        starView.showEquatorialGrid = config.showEquatorialGrid
        starView.showEclipticLine = config.showEclipticLine
        starView.showMeridianLine = config.showMeridianLine
        starView.showEquatorLine = config.showEquatorLine
        starView.showGalacticLine = config.showGalacticLine
        starView.showFavorites = config.showFavorites
        starView.showDirections = config.showDirections
        starView.showCelestialPaths = config.showCelestialPaths
        starView.showRedFilter = config.showRedFilter
        starView.showConstellations = config.showConstellations
        starView.showStars = config.showStars
        starView.showGalaxies = config.showGalaxies
        starView.showBlackHoles = config.showBlackHoles
        starView.showNebulae = config.showNebulae
        starView.showOpenClusters = config.showOpenClusters
        starView.showGlobularClusters = config.showGlobularClusters
        starView.showGalaxyClusters = config.showGalaxyClusters
        starView.showSun = config.showSun
        starView.showMoon = config.showMoon
        starView.showPlanets = config.showPlanets
        starView.showMagnitudeFilter = config.showMagnitudeFilter || config.magnitudeFilter != nil
        starView.magnitudeFilter = config.magnitudeFilter
        if shouldApply2DMode {
            apply2DMode(config.is2DMode)
        }
        updateRedMode(config.showRedFilter)
        updateMagnitudeControls()
    }

    private func saveCommonSettings() {
        settings.setCommonConfig(AstronomyPluginSettings.CommonConfig(showRegularMap: regularMapVisible))
    }

    private func saveStarMapSettings() {
        settings.updateStarMapConfig { current in
            var config = current
            config.showAzimuthalGrid = starView.showAzimuthalGrid
            config.showEquatorialGrid = starView.showEquatorialGrid
            config.showEclipticLine = starView.showEclipticLine
            config.showMeridianLine = starView.showMeridianLine
            config.showEquatorLine = starView.showEquatorLine
            config.showGalacticLine = starView.showGalacticLine
            config.showFavorites = starView.showFavorites
            config.showDirections = starView.showDirections
            config.showCelestialPaths = starView.showCelestialPaths
            config.showRedFilter = starView.showRedFilter
            config.showSun = starView.showSun
            config.showMoon = starView.showMoon
            config.showPlanets = starView.showPlanets
            config.showConstellations = starView.showConstellations
            config.showStars = starView.showStars
            config.showGalaxies = starView.showGalaxies
            config.showBlackHoles = starView.showBlackHoles
            config.showNebulae = starView.showNebulae
            config.showOpenClusters = starView.showOpenClusters
            config.showGlobularClusters = starView.showGlobularClusters
            config.showGalaxyClusters = starView.showGalaxyClusters
            config.is2DMode = starView.is2DMode
            config.showMagnitudeFilter = starView.showMagnitudeFilter || starView.magnitudeFilter != nil
            config.magnitudeFilter = starView.magnitudeFilter
            return config
        }
        viewModel.updateSettings(settings)
    }

    private func setStarMapSettings(_ config: AstronomyPluginSettings.StarMapConfig) {
        let updatedConfig = settings.updateStarMapConfig { current in
            var updated = config
            updated.favorites = current.favorites
            updated.directions = current.directions
            updated.celestialPaths = current.celestialPaths
            return updated
        }
        applySettings(updatedConfig)
        viewModel.updateSettings(settings)
    }

    private func updateRegularMapVisibility(_ visible: Bool) {
        regularMapVisible = visible
        starView.settings.common.showRegularMap = visible
        updateRegularMapLayout()
        if visible {
            attachRegularMapIfNeeded()
        } else {
            restoreRegularMapIfNeeded(refresh: true)
        }
        starView.setNeedsDisplay()
    }

    func applyRedFilter(enabled: Bool) {
        starView.showRedFilter = enabled
        updateRedMode(enabled)
        saveStarMapSettings()
    }

    func setRegularMapVisibility(enabled: Bool) {
        updateRegularMapVisibility(enabled)
        saveCommonSettings()
    }

    private func apply2DMode(_ is2D: Bool) {
        if is2D {
            previousAltitude = starView.getAltitude()
            previousAzimuth = starView.getAzimuth()
            previousViewAngle = starView.getViewAngle()
            starView.is2DMode = true
            starView.setCenter(azimuth: 180, altitude: 90)
            if cameraHelper.isCameraOverlayEnabled {
                cameraHelper.toggleCameraOverlay()
            }
            cameraButton.isHidden = true
            if arModeHelper.isArModeEnabled {
                arModeHelper.toggleArMode(enable: false)
            }
            arModeButton.isHidden = true
            manualAzimuth = true
        } else {
            starView.is2DMode = false
            starView.setCenter(azimuth: previousAzimuth, altitude: previousAltitude)
            starView.setViewAngle(previousViewAngle)
            arModeButton.isHidden = false
            cameraButton.isHidden = !arModeHelper.isArModeEnabled
        }
        starView.setNeedsDisplay()
    }

    private func updateTime(_ date: Date, animate: Bool) {
        currentDate = date
        timeSelectionView.setDateTime(date)
        starView.setDateTime(AstroUtils.astronomyTime(from: date), animate: animate)
        updateTimeControls()
        objectInfoController?.onTimeChanged()
    }

    private func syncCurrentTimeForAutoUpdate(animate: Bool) {
        guard isTimeAutoUpdateEnabled else {
            return
        }
        updateTime(Date(), animate: animate)
        scheduleAutoTimeUpdate()
    }

    private func setTimeAutoUpdateEnabled(_ enabled: Bool) {
        isTimeAutoUpdateEnabled = enabled
        resetTimeButton.isHidden = enabled
        if enabled {
            syncCurrentTimeForAutoUpdate(animate: true)
        } else {
            stopAutoTimeUpdate()
        }
        updateTimeControlTheme()
    }

    private func scheduleAutoTimeUpdate() {
        stopAutoTimeUpdate()
        guard isTimeAutoUpdateEnabled else {
            return
        }
        let now = Date()
        let nextMinute = Calendar.current.dateInterval(of: .minute, for: now)?.end ?? now.addingTimeInterval(60)
        let delay = max(0.1, nextMinute.timeIntervalSince(now))
        let timer = Timer(timeInterval: delay, repeats: false) { [weak self] _ in
            self?.syncCurrentTimeForAutoUpdate(animate: true)
        }
        autoTimeUpdateTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func stopAutoTimeUpdate() {
        autoTimeUpdateTimer?.invalidate()
        autoTimeUpdateTimer = nil
    }

    private func updateTimeControls() {
        let date = currentDate
        timeSelectionView.setDateTime(date)
        let calendar = Calendar.current
        let now = Date()
        let formatter = DateFormatter()
        if calendar.isDate(date, inSameDayAs: now) {
            formatter.dateFormat = "HH:mm"
        } else {
            formatter.dateStyle = .short
            formatter.timeStyle = .short
        }
        timeControlButton.setTitle(formatter.string(from: date), for: .normal)

        updateTimeControlTheme()
    }

    private func updateTimeControlTheme() {
        let nightMode = OADayNightHelper.instance().isNightMode()
        let active = !timeSelectionView.isHidden
        timeControlCard.backgroundColor = active
            ? StarMapControlTheme.activeBackground()
            : StarMapControlTheme.defaultBackground(nightMode: nightMode, alpha: 1)
        timeControlButton.nightMode = nightMode
        resetTimeButton.nightMode = nightMode
        timeControlButton.active = active
        resetTimeButton.active = active
    }

    private func updateMagnitudeControls() {
        let filterToUse = min(starView.magnitudeFilter ?? Layout.maxMagnitude, Layout.maxMagnitude)
        if starView.magnitudeFilter == nil || (starView.magnitudeFilter ?? 0) > Layout.maxMagnitude {
            starView.magnitudeFilter = Layout.maxMagnitude
        }
        magnitudeSlider.value = Float(filterToUse)
        let text = String(format: "%.1f", filterToUse)
        magnitudeFilterText.text = text
        magnitudeSliderValue.text = text
        updateMagnitudeFilterTheme()
    }

    private func updateMagnitudeFilterTheme() {
        let nightMode = OADayNightHelper.instance().isNightMode()
        let active = !magnitudeSliderCard.isHidden
        magnitudeFilterButton.backgroundColor = active
            ? StarMapControlTheme.activeBackground()
            : StarMapControlTheme.defaultBackground(nightMode: nightMode, alpha: 0.92)
        magnitudeFilterIcon.tintColor = StarMapControlTheme.foreground(active: active, nightMode: nightMode)
        magnitudeFilterText.textColor = StarMapControlTheme.foreground(active: active, nightMode: nightMode)
        magnitudeSliderCard.backgroundColor = StarMapControlTheme.defaultBackground(nightMode: nightMode, alpha: 0.94)
        magnitudeSliderTitle.textColor = StarMapControlTheme.textColor(nightMode: nightMode)
        magnitudeSliderValue.textColor = StarMapControlTheme.activeBackground()
    }

    private func updateArModeUI(_ enabled: Bool) {
        arModeButton.active = enabled
        cameraButton.isHidden = !enabled || starView.is2DMode
        if enabled {
            starView.isCameraMode = true
            starView.setNeedsDisplay()
        } else {
            starView.roll = 0
            starView.setNeedsDisplay()
            if cameraHelper.isCameraOverlayEnabled {
                cameraHelper.toggleCameraOverlay()
            }
            updateCameraUI(false)
        }
    }

    private func updateCameraUI(_ enabled: Bool) {
        cameraButton.active = enabled
        sliderContainer.isHidden = !enabled
        resetFovButton.isHidden = !enabled
        starView.isCameraMode = enabled || arModeHelper.isRunning
    }

    private func updateMapControlThemes() {
        updateButtonsNightMode()
        updateTimeControlTheme()
        updateMagnitudeFilterTheme()
    }

    private func updateButtonsNightMode() {
        let nightMode = OADayNightHelper.instance().isNightMode()
        arModeButton.nightMode = nightMode
        cameraButton.nightMode = nightMode
        resetFovButton.nightMode = nightMode
        closeButton.nightMode = nightMode
        settingsButton.nightMode = nightMode
        searchButton.nightMode = nightMode
        compassButton.nightMode = nightMode
        resetTimeButton.nightMode = nightMode
        timeControlButton.nightMode = nightMode
    }

    private func updateRedMode(_ enabled: Bool) {
        starView.showRedFilter = enabled
        AstroRedFilter.apply(enabled,
                             to: timeControlCard,
                             timeSelectionView,
                             arModeButton,
                             cameraButton,
                             resetFovButton,
                             magnitudeFilterButton,
                             magnitudeSliderCard,
                             compassButton,
                             searchButton,
                             closeButton,
                             settingsButton,
                             sliderContainer,
                             regularMapContainer)
        objectInfoController?.applyRedFilter(enabled: enabled)
        configureSheetController?.applyRedFilter(enabled: enabled)
    }

    private func regularMapHeight() -> CGFloat {
        let isLandscape = OAUtilities.isLandscape()
        
        if OAUtilities.isIPad() {
            let fraction: CGFloat = isLandscape ? Layout.regularMapHeightFractionForPadLandscape : Layout.regularMapHeightFractionForPad
            return view.bounds.height * fraction
        }
        return isLandscape ? Layout.regularMapHeightLandscape : Layout.regularMapHeight
    }

    private func updateRegularMapLayout() {
        let height = regularMapVisible ? regularMapHeight() : 0
        if regularMapHeightConstraint?.constant != height {
            regularMapHeightConstraint?.constant = height
        }
        if additionalSafeAreaInsets.bottom != height {
            additionalSafeAreaInsets.bottom = height
            view.layoutIfNeeded()
        }
    }

    private func attachRegularMapIfNeeded() {
        guard regularMapVisible,
              let mapPanel = OARootViewController.instance()?.mapPanel else {
            return
        }
        let mapViewController = mapPanel.mapViewController
        updateRegularMapLayout()
        view.layoutIfNeeded()
        mapViewController.setSingleTapContextMenuGestureEnabled(false)
        if mapViewController.parent !== self {
            mapPanel.doMapReuse(self, destinationView: regularMapContainer)
        }
        layoutRegularMapRenderer(forceResize: true)
        mapPanel.refreshMap(true)
        
        if starView.showRedFilter {
            AstroRedFilter.apply(true, to: regularMapContainer)
        }
    }

    private func restoreRegularMapIfNeeded(refresh: Bool) {
        guard let mapPanel = OARootViewController.instance()?.mapPanel else {
            return
        }
        mapPanel.mapViewController.setSingleTapContextMenuGestureEnabled(true)
        mapPanel.restoreMapAfterReuseIfNeeded()
        if refresh {
            mapPanel.refreshMap(true)
        }
    }

    private func layoutRegularMapRenderer(forceResize: Bool = false) {
        guard regularMapVisible,
              let mapView = currentMapViewController()?.view,
              mapView.superview === regularMapContainer else {
            return
        }
        let bounds = regularMapContainer.bounds
        guard !bounds.isEmpty else { return }
        
        if forceResize || mapView.frame != bounds {
            mapView.frame = bounds
            mapView.autoresizingMask = []
            mapView.layoutIfNeeded()
        }
    }

    private func currentMapViewController() -> OAMapViewController? {
        OARootViewController.instance()?.mapPanel?.mapViewController
    }

    private func currentMapCenterLocation() -> CLLocation? {
        currentMapViewController()?.getMapLocation()
    }

    @objc private func onMapLocationChanged() {
        DispatchQueue.main.async { [weak self] in
            self?.updateStarMap()
        }
    }

    @objc private func onDayNightModeChanged() {
        DispatchQueue.main.async { [weak self] in
            self?.updateMapControlThemes()
        }
    }

    private func updateStarMap(updateAzimuth: Bool = false) {
        let deviceLocation = OsmAndApp.swiftInstance()?.locationServices?.lastKnownLocation
        if let deviceLocation {
            arModeHelper.updateGeomagneticField(location: deviceLocation)
        }

        let mapLocation = currentMapCenterLocation()
        let observerLocation = mapLocation ?? deviceLocation
        let coordinate = observerLocation?.coordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
        let altitude = mapLocation == nil ? observerLocation?.altitude ?? 0 : 0
        starView.setObserverLocation(lat: coordinate.latitude, lon: coordinate.longitude, alt: altitude)
        if selectedObject != nil {
            updateTimeControls()
        }
        objectInfoController?.onLocationChanged()
        if updateAzimuth && !arModeHelper.isArModeEnabled && !starView.is2DMode {
            setAzimuth(lastUpdatedAzimuth >= 0 ? lastUpdatedAzimuth : 0)
        }
    }

    private func setAzimuth(_ azimuth: Double, animate: Bool = false) {
        starView.setAzimuth(azimuth, animate: animate)
        compassButton.update(mapRotation: CGFloat(-azimuth), animated: animate)
        lastUpdatedAzimuth = azimuth
    }

    private func updateMapControlsVisibility() {
        let isPhoneSheet = OAUtilities.isIPhone()
            && (objectInfoController != nil || configureSheetController != nil)
        mapControlsContainer.isHidden = isPhoneSheet
        mapVisibleAreaLeadingConstraint?.constant = mapControlsLeadingInset
    }

    private func clearSelectedObject() {
        selectedObject = nil
        starView.setSelectedObject(nil)
        starView.setSelectedConstellation(nil)
        starView.setNeedsDisplay()
    }

    func trackableObjects() -> [SkyObject] {
        viewModel.skyObjects + viewModel.constellations.map { $0 as SkyObject }
    }

    func findTrackableObjectById(_ id: String) -> SkyObject? {
        trackableObjects().first { $0.id == id }
    }

    private func hideBottomSheet() {
        hideBottomSheet(clearSelection: true)
    }

    private func hideBottomSheet(clearSelection: Bool) {
        dismissObjectInfoSheet(clearSelection: clearSelection, animated: false)
        dismissConfigureSheet(animated: false)
        if clearSelection {
            clearSelectedObject()
        }
        updateMapControlsVisibility()
    }

    private func dismissObjectInfoSheet(clearSelection: Bool, animated: Bool) {
        guard let navigationController = objectInfoNavigationController else {
            if objectInfoController != nil {
                finishObjectInfoDismiss(clearSelection: clearSelection)
            }
            return
        }
        if navigationController.parent === self {
            isDismissingObjectInfoSheet = true
            dismissLeftPanel(navigationController: navigationController, animated: animated) { [weak self] in
                guard let self else { return }
                isDismissingObjectInfoSheet = false
                finishObjectInfoDismiss(clearSelection: clearSelection)
            }
            return
        }
        isDismissingObjectInfoSheet = true
        navigationController.dismiss(animated: animated) { [weak self] in
            guard let self else { return }
            isDismissingObjectInfoSheet = false
            finishObjectInfoDismiss(clearSelection: clearSelection)
        }
    }

    private func finishObjectInfoDismiss(clearSelection: Bool) {
        objectInfoController = nil
        objectInfoNavigationController = nil
        if clearSelection {
            clearSelectedObject()
        }
        updateMapControlsVisibility()
    }

    private func dismissConfigureSheet(animated: Bool) {
        guard let navigationController = configureSheetNavigationController else {
            if configureSheetController != nil {
                finishConfigureSheetDismiss()
            }
            return
        }
        if navigationController.parent === self {
            isDismissingConfigureSheet = true
            dismissLeftPanel(navigationController: navigationController, animated: animated) { [weak self] in
                guard let self else { return }
                isDismissingConfigureSheet = false
                finishConfigureSheetDismiss()
            }
            return
        }
        isDismissingConfigureSheet = true
        navigationController.dismiss(animated: animated) { [weak self] in
            guard let self else { return }
            isDismissingConfigureSheet = false
            finishConfigureSheetDismiss()
        }
    }

    private func finishConfigureSheetDismiss() {
        configureSheetController = nil
        configureSheetNavigationController = nil
        updateMapControlsVisibility()
    }

    private func showObjectInfo(_ object: SkyObject, centerInVisibleMapOnPresentation: Bool = false) {
        if let objectInfoController {
            if !objectInfoController.isDisplaying(object) {
                objectInfoController.updateObjectInfo(object)
            }
            updateMapControlsVisibility()
            if centerInVisibleMapOnPresentation {
                DispatchQueue.main.async { [weak self] in
                    self?.centerObjectInVisibleStarMap(object, animate: true)
                }
            }
            return
        }
        hideBottomSheet(clearSelection: false)

        let dependencies = AstroContextMenuDependencies(
            currentDate: { [weak self] in self?.currentDate ?? Date() },
            observer: { [weak self] in self?.starView.observer ?? AstroUtils.observer(from: nil) },
            dataProvider: dataProvider,
            preferredLocale: { OsmAndApp.swiftInstance()?.getLanguageCode() },
            trackableObjects: { [weak self] in self?.trackableObjects() ?? [] },
            constellations: { [weak self] in self?.viewModel.constellations ?? [] },
            onClose: { [weak self] in self?.dismissObjectInfoSheet(clearSelection: true, animated: true) },
            onDismissed: { [weak self] in
                guard let self, !isDismissingObjectInfoSheet else {
                    return
                }
                finishObjectInfoDismiss(clearSelection: true)
            },
            onCenterObject: { [weak self] object in
                self?.centerObjectInVisibleStarMap(object, animate: true)
            },
            onFavoriteChanged: { [weak self] object, enabled in
                guard let self else { return }
                if enabled {
                    self.settings.addFavorite(id: object.id)
                } else {
                    self.settings.removeFavorite(id: object.id)
                }
                self.viewModel.updateSettings(self.settings)
                self.starView.refreshObjects()
            },
            onDirectionChanged: { [weak self] object, enabled in
                guard let self else { return object.colorIndex }
                let colorIndex: Int
                if enabled {
                    colorIndex = self.settings.addDirection(id: object.id)
                } else {
                    self.settings.removeDirection(id: object.id)
                    colorIndex = object.colorIndex
                }
                self.viewModel.updateSettings(self.settings)
                self.starView.refreshObjects()
                return colorIndex
            },
            onCelestialPathChanged: { [weak self] object, enabled in
                guard let self else { return }
                if enabled {
                    self.settings.addCelestialPath(id: object.id)
                } else {
                    self.settings.removeCelestialPath(id: object.id)
                }
                self.viewModel.updateSettings(self.settings)
                self.starView.refreshObjects()
            },
            onSetObjectPinned: { [weak self] object, pinned, forceUpdate in
                self?.starView.setObjectPinned(object, pinned: pinned, forceUpdate: forceUpdate)
            },
            onRefreshObjects: { [weak self] in
                guard let self else { return }
                self.viewModel.updateSettings(self.settings)
                self.starView.refreshObjects()
            },
            onCatalogClick: { [weak self] catalog in
                self?.showSearchDialog(initialCatalogWid: catalog.wid)
            }
        )
        let controller = AstroContextMenuViewController(object: object, dependencies: dependencies)
        controller.applyRedFilter(enabled: starView.showRedFilter)
        let navigationController = UINavigationController(rootViewController: controller)
        navigationController.modalPresentationStyle = .pageSheet
        navigationController.navigationBar.prefersLargeTitles = false
        
        objectInfoController = controller
        objectInfoNavigationController = navigationController
        if OAUtilities.isIPad() {
            showLeftPanel(navigationController) { [weak self] in
                guard centerInVisibleMapOnPresentation else { return }
                self?.centerObjectInVisibleStarMap(object, animate: true)
            }
        } else {
            if let sheet = navigationController.sheetPresentationController {
                sheet.detents = [.medium(), .large()]
                sheet.selectedDetentIdentifier = .medium
                sheet.prefersGrabberVisible = true
                sheet.prefersScrollingExpandsWhenScrolledToEdge = true
                sheet.preferredCornerRadius = 34
                sheet.largestUndimmedDetentIdentifier = .medium
            }
            present(navigationController, animated: true) { [weak self] in
                guard centerInVisibleMapOnPresentation else {
                    return
                }
                self?.centerObjectInVisibleStarMap(object, animate: true)
            }
        }
        updateMapControlsVisibility()
    }

    private func visibleStarMapTargetPoint() -> CGPoint {
        view.layoutIfNeeded()
        
        if OAUtilities.isIPad(), embeddedLeftPanelNavigationController != nil {
            let visibleArea = mapVisibleAreaGuide.layoutFrame
            guard visibleArea.width > 0, visibleArea.height > 0 else {
                return CGPoint(x: starView.bounds.midX, y: starView.bounds.midY)
            }
            let targetInControls = CGPoint(x: visibleArea.midX, y: visibleArea.midY)
            let targetInView = mapControlsContainer.convert(targetInControls, to: view)
            return view.convert(targetInView, to: starView)
        }
        
        let starFrame = starView.convert(starView.bounds, to: view)
        var visibleFrame = starFrame
        if let sheetView = objectInfoNavigationController?.view, !sheetView.isHidden {
            let sheetFrame = sheetView.convert(sheetView.bounds, to: view)
            let visibleBottom = min(visibleFrame.maxY, max(visibleFrame.minY, sheetFrame.minY))
            visibleFrame.size.height = max(0, visibleBottom - visibleFrame.minY)
        }
        guard visibleFrame.width > 0, visibleFrame.height > 0 else {
            return CGPoint(x: starView.bounds.midX, y: starView.bounds.midY)
        }
        let targetInView = CGPoint(x: visibleFrame.midX, y: visibleFrame.midY)
        return view.convert(targetInView, to: starView)
    }

    private func centerObjectInVisibleStarMap(_ object: SkyObject, animate: Bool) {
        starView.setSelectedObject(object, centerAt: visibleStarMapTargetPoint(), animate: animate)
    }

    private func showMessage(_ message: String) {
        let alert = UIAlertController(title: localizedString("astronomy_plugin_name"), message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: localizedString("shared_string_ok"), style: .default))
        present(alert, animated: true)
    }

    func starView(_ starView: StarView, didSelect object: SkyObject?) {
        selectedObject = object
        updateTimeControls()
    }

    private func handleSearchObjectSelected(_ obj: SkyObject) {
        manualAzimuth = true
        selectedObject = obj
        starView.setSelectedObject(obj)
        showObjectInfo(obj, centerInVisibleMapOnPresentation: true)
    }

    @objc func showSearchDialog() {
        if UIDevice.current.userInterfaceIdiom == .pad, searchViewController != nil {
            dismissSearchDialog(animated: true)
        } else {
            showSearchDialog(initialCatalogWid: nil)
        }
    }

    func showSearchDialog(initialCatalogWid: String? = nil) {
        clearPreviousSearchDialog()
        let controller = StarMapSearchViewController.newInstance(initialCatalogWid: initialCatalogWid,
                                                                 parent: self,
                                                                 plugin: plugin)
        controller.onObjectSelected = { [weak self] obj in
            self?.handleSearchObjectSelected(obj)
        }
        controller.onDismiss = { [weak self] in
            self?.dismissSearchDialog(animated: true)
        }
        controller.applyRedFilter(enabled: starView.showRedFilter)
        searchViewController = controller
        
        let nav = UINavigationController(rootViewController: controller)
        nav.modalPresentationStyle = .fullScreen
        nav.navigationBar.prefersLargeTitles = true
        searchNavigationController = nav
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            showLeftPanel(nav)
            updateMapControlsVisibility()
        } else {
            nav.modalPresentationStyle = .fullScreen
            (presentedViewController ?? self).present(nav, animated: true)
        }
    }
    
    private func dismissSearchDialog(animated: Bool, completion: (() -> Void)? = nil) {
        guard let navigationController = searchNavigationController else {
            finishSearchDismiss()
            completion?()
            return
        }
        if navigationController.parent === self {
            dismissLeftPanel(navigationController: navigationController, animated: animated) { [weak self] in
                self?.finishSearchDismiss()
                completion?()
            }
        } else {
            navigationController.dismiss(animated: animated) { [weak self] in
                self?.finishSearchDismiss()
                completion?()
            }
        }
    }

    private func finishSearchDismiss() {
        searchViewController = nil
        searchNavigationController = nil
        updateMapControlsVisibility()
    }

    private func clearPreviousSearchDialog() {
        dismissSearchDialog(animated: false)
    }

    func searchableObjects() -> [SkyObject] {
        trackableObjects()
    }

    func searchConstellations() -> [Constellation] {
        viewModel.constellations
    }

    func searchObserver() -> Observer {
        starView.observer
    }

    func searchCurrentDate() -> Date {
        currentDate
    }

    func searchStarMapConfig() -> AstronomyPluginSettings.StarMapConfig {
        settings.starMap
    }

    func isSearchRedFilterEnabled() -> Bool {
        starView.showRedFilter
    }
    
    func makeSearchObjectActionHandler() -> StarMapObjectActionHandler {
        StarMapObjectActionHandler(
            onFavoriteChanged: { [weak self] object, enabled in
                guard let self else { return }
                if enabled { settings.addFavorite(id: object.id) }
                else { settings.removeFavorite(id: object.id) }
                viewModel.updateSettings(settings)
                starView.refreshObjects()
            },
            onDirectionChanged: { [weak self] object, enabled in
                guard let self else { return object.colorIndex }
                let colorIndex = enabled ? settings.addDirection(id: object.id) : object.colorIndex
                if !enabled { settings.removeDirection(id: object.id) }
                viewModel.updateSettings(settings)
                starView.refreshObjects()
                return colorIndex
            },
            onCelestialPathChanged: { [weak self] object, enabled in
                guard let self else { return }
                if enabled { settings.addCelestialPath(id: object.id) }
                else { settings.removeCelestialPath(id: object.id) }
                viewModel.updateSettings(settings)
                starView.refreshObjects()
            },
            onSetObjectPinned: { [weak self] object, pinned, forceUpdate in
                self?.starView.setObjectPinned(object, pinned: pinned, forceUpdate: forceUpdate)
            }
        )
    }

    @objc private func close() {
        dismiss(animated: true)
    }

    @objc private func showConfigureSheet() {
        if configureSheetController != nil {
            if OAUtilities.isIPhone() {
                configureSheetNavigationController?.sheetPresentationController?.animateChanges { [weak self] in
                    self?.configureSheetNavigationController?.sheetPresentationController?.selectedDetentIdentifier = .medium
                }
                updateMapControlsVisibility()
            } else {
                dismissConfigureSheet(animated: true)
            }
            return
        }
        hideBottomSheet(clearSelection: false)

        let sheet = AstroConfigureViewBottomSheet()
        sheet.config = settings.starMap
        sheet.commonConfig = settings.common
        sheet.onConfigChanged = { [weak self] config in
            self?.setStarMapSettings(config)
        }
        sheet.onCommonConfigChanged = { [weak self] config in
            self?.settings.common = config
            self?.updateRegularMapVisibility(config.showRegularMap)
            self?.saveCommonSettings()
        }
        sheet.onRedFilterChanged = { [weak self] enabled in
            self?.applyRedFilter(enabled: enabled)
        }
        sheet.onClose = { [weak self] in
            self?.dismissConfigureSheet(animated: true)
        }
        sheet.onDismissed = { [weak self] in
            guard let self, !isDismissingConfigureSheet else {
                return
            }
            finishConfigureSheetDismiss()
        }

        let navigationController = UINavigationController(rootViewController: sheet)
        navigationController.modalPresentationStyle = .pageSheet
        navigationController.navigationBar.prefersLargeTitles = false
        
        configureSheetController = sheet
        configureSheetNavigationController = navigationController

        if OAUtilities.isIPad() {
            showLeftPanel(navigationController)
        } else {
            if let sheetPresentationController = navigationController.sheetPresentationController {
                sheetPresentationController.detents = [.medium(), .large()]
                sheetPresentationController.selectedDetentIdentifier = .medium
                sheetPresentationController.prefersGrabberVisible = true
                sheetPresentationController.prefersScrollingExpandsWhenScrolledToEdge = true
                sheetPresentationController.preferredCornerRadius = 38
                sheetPresentationController.largestUndimmedDetentIdentifier = .large
            }
            present(navigationController, animated: true)
            updateMapControlsVisibility()
        }
    }

    private func showLeftPanel(_ navigationController: UINavigationController, animated: Bool = true, completion: (() -> Void)? = nil) {
        if let existingPanel = embeddedLeftPanelNavigationController, existingPanel !== navigationController {
            dismissLeftPanel(navigationController: existingPanel, animated: false)
            if existingPanel === configureSheetNavigationController {
                finishConfigureSheetDismiss()
            } else if existingPanel === objectInfoNavigationController {
                finishObjectInfoDismiss(clearSelection: false)
            } else if existingPanel === searchNavigationController {
                finishSearchDismiss()
            }
        }

        addChild(navigationController)
        view.insertSubview(navigationController.view, belowSubview: mapControlsContainer)
        navigationController.view.translatesAutoresizingMaskIntoConstraints = false
        navigationController.view.layer.cornerRadius = 24
        navigationController.view.clipsToBounds = true

        let offscreenLeading = -(Layout.leftPanelWidth + Layout.contentPadding)
        let leading = navigationController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: offscreenLeading)
        leftPanelLeadingConstraint = leading

        NSLayoutConstraint.activate([
            navigationController.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: Layout.contentPadding),
            leading,
            navigationController.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -Layout.contentPadding),
            navigationController.view.widthAnchor.constraint(equalToConstant: Layout.leftPanelWidth)
        ])

        navigationController.didMove(toParent: self)

        view.layoutIfNeeded()

        guard animated else {
            leading.constant = Layout.contentPadding
            mapVisibleAreaLeadingConstraint?.constant = mapControlsLeadingInset
            view.layoutIfNeeded()
            completion?()
            return
        }

        UIView.animate(withDuration: 0.25, animations: {
            leading.constant = Layout.contentPadding
            self.mapVisibleAreaLeadingConstraint?.constant = self.mapControlsLeadingInset
            self.view.layoutIfNeeded()
        }, completion: { _ in
            completion?()
        })
    }

    private func dismissLeftPanel(navigationController: UINavigationController, animated: Bool, completion: (() -> Void)? = nil) {
        guard navigationController.parent === self else {
            completion?()
            return
        }

        let finish = {
            navigationController.willMove(toParent: nil)
            navigationController.view.removeFromSuperview()
            navigationController.removeFromParent()
            self.leftPanelLeadingConstraint = nil
            completion?()
        }

        guard animated, let leading = leftPanelLeadingConstraint else {
            finish()
            return
        }

        UIView.animate(withDuration: 0.25, animations: {
            leading.constant = -(Layout.leftPanelWidth + Layout.contentPadding)
            if OAUtilities.isIPad() {
                self.mapVisibleAreaLeadingConstraint?.constant = Layout.contentPadding
            }
            self.view.layoutIfNeeded()
        }, completion: { _ in
            finish()
        })
    }

    @objc private func toggleTimeSelection() {
        timeSelectionView.isHidden.toggle()
        updateTimeControlTheme()
    }

    @objc private func resetTimeButtonPressed() {
        setTimeAutoUpdateEnabled(true)
    }

    @objc private func toggleARMode() {
        arModeHelper.toggleArMode()
    }

    @objc private func toggleCamera() {
        cameraHelper.toggleCameraOverlay(in: view, below: starView)
    }

    @objc private func transparencyChanged() {
        cameraHelper.setTransparency(progress: Int(transparencySlider.value))
    }

    @objc private func resetFov() {
        cameraHelper.resetFov()
    }

    @objc private func toggleMagnitudeSlider() {
        magnitudeSliderCard.isHidden.toggle()
        updateMagnitudeFilterTheme()
    }

    @objc private func magnitudeChanged() {
        starView.magnitudeFilter = Double(magnitudeSlider.value)
        starView.showMagnitudeFilter = true
        settings.updateStarMapConfig { current in
            var config = current
            config.showMagnitudeFilter = true
            config.magnitudeFilter = starView.magnitudeFilter
            return config
        }
        updateMagnitudeControls()
        starView.setNeedsDisplay()
    }
}

private final class StarMapControlsContainer: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)
        return hitView === self ? nil : hitView
    }
}
