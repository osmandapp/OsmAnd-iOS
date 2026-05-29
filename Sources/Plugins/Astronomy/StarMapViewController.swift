//
//  StarMapViewController.swift
//  OsmAnd Maps
//
//  Created by Codex on 19.05.2026.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

import CoreLocation
import UIKit

final class StarMapViewController: UIViewController, StarViewDelegate {
    private enum Layout {
        static let contentPadding: CGFloat = 16
        static let buttonSize: CGFloat = 52
        static let smallButtonSize: CGFloat = 40
        static let magnitudeButtonHeight: CGFloat = 76
        static let magnitudeSliderWidth: CGFloat = 240
        static let transparencySliderHeight: CGFloat = 150
        static let bottomSheetHeight: CGFloat = 280
        static let objectInfoSheetHeight: CGFloat = 420
        static let settingsSheetHeight: CGFloat = 520
        static let maxMagnitude: Double = 7.0
    }
    private var settings: AstronomyPluginSettings
    private let dataProvider: AstroDataProvider
    private let viewModel: StarObjectsViewModel

    private let mainLayout = UIView()
    private let starView = StarView()
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
    private let magnitudeSliderValue = UILabel()
    private let timeLabel = UILabel()
    private let closeButton = StarMapButton()
    private let settingsButton = StarMapButton()
    private let compassButton = StarCompassButton()
    private let bottomSheetContainer = UIView()

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
    private var bottomSheetController: UIViewController?
    private var bottomSheetHeightConstraint: NSLayoutConstraint?
    private var mapLocationObserver: OAAutoObserverProxy?

    init(plugin: AstronomyPlugin) {
        let loadedSettings = AstronomyPluginSettings.load()
        let provider = plugin.dataProvider
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
        resetTime()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        arModeHelper.onResume()
        cameraHelper.onResume()
        if arModeHelper.isArModeEnabled {
            updateArModeUI(true)
        }
        if isTimeAutoUpdateEnabled {
            resetTime()
            scheduleAutoTimeUpdate()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopAutoTimeUpdate()
        saveStarMapSettings()
        arModeHelper.onPause()
        cameraHelper.onPause()
        starView.isCameraMode = false
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        cameraHelper.layoutPreview()
    }

    private func setupLayout() {
        mainLayout.translatesAutoresizingMaskIntoConstraints = false
        starView.translatesAutoresizingMaskIntoConstraints = false
        mapControlsContainer.translatesAutoresizingMaskIntoConstraints = false
        bottomSheetContainer.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(mainLayout)
        mainLayout.addSubview(starView)
        mainLayout.addSubview(mapControlsContainer)
        view.addSubview(bottomSheetContainer)

        let bottomSheetHeightConstraint = bottomSheetContainer.heightAnchor.constraint(equalToConstant: Layout.bottomSheetHeight)
        self.bottomSheetHeightConstraint = bottomSheetHeightConstraint

        NSLayoutConstraint.activate([
            mainLayout.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mainLayout.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mainLayout.topAnchor.constraint(equalTo: view.topAnchor),
            mainLayout.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            starView.leadingAnchor.constraint(equalTo: mainLayout.leadingAnchor),
            starView.trailingAnchor.constraint(equalTo: mainLayout.trailingAnchor),
            starView.topAnchor.constraint(equalTo: mainLayout.topAnchor),
            starView.bottomAnchor.constraint(equalTo: mainLayout.bottomAnchor),

            mapControlsContainer.leadingAnchor.constraint(equalTo: mainLayout.leadingAnchor),
            mapControlsContainer.trailingAnchor.constraint(equalTo: mainLayout.trailingAnchor),
            mapControlsContainer.topAnchor.constraint(equalTo: mainLayout.topAnchor),
            mapControlsContainer.bottomAnchor.constraint(equalTo: mainLayout.bottomAnchor),

            bottomSheetContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomSheetContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomSheetContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bottomSheetHeightConstraint
        ])

        bottomSheetContainer.backgroundColor = UIColor(white: 0.03, alpha: 0.96)
        bottomSheetContainer.layer.cornerRadius = 16
        bottomSheetContainer.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        bottomSheetContainer.layer.masksToBounds = true
        bottomSheetContainer.isHidden = true
    }

    private func setupControls() {
        setupStarView()
        setupCompassAndLeftControls()
        setupRightControls()
        setupTimeControls()
        setupMagnitudeControls()
        setupCameraControls()
        setupBottomSheetLabel()
        updateButtonsNightMode()
    }

    private func setupStarView() {
        starView.delegate = self
        starView.viewModel = viewModel
        starView.settings = settings
    }

    private func setupCompassAndLeftControls() {
        addRoundButton(compassButton, systemName: "location.north.fill", accessibilityLabel: localizedString("map_widget_compass"))
        compassButton.onSingleTap = { [weak self] in self?.setAzimuth(0, animate: true) }

        addRoundButton(arModeButton, systemName: "arkit", accessibilityLabel: localizedString("astro_ar"))
        arModeButton.addTarget(self, action: #selector(toggleARMode), for: .touchUpInside)

        addRoundButton(cameraButton, systemName: "camera", accessibilityLabel: localizedString("astro_camera"))
        cameraButton.addTarget(self, action: #selector(toggleCamera), for: .touchUpInside)

        NSLayoutConstraint.activate([
            compassButton.leadingAnchor.constraint(equalTo: mapControlsContainer.safeAreaLayoutGuide.leadingAnchor, constant: Layout.contentPadding),
            compassButton.topAnchor.constraint(equalTo: mapControlsContainer.safeAreaLayoutGuide.topAnchor, constant: Layout.contentPadding),

            arModeButton.centerXAnchor.constraint(equalTo: compassButton.centerXAnchor),
            arModeButton.topAnchor.constraint(equalTo: compassButton.bottomAnchor, constant: Layout.contentPadding),

            cameraButton.centerXAnchor.constraint(equalTo: arModeButton.centerXAnchor),
            cameraButton.topAnchor.constraint(equalTo: arModeButton.bottomAnchor, constant: Layout.contentPadding)
        ])
    }

    private func setupRightControls() {
        addRoundButton(closeButton, systemName: "xmark", accessibilityLabel: localizedString("shared_string_close"))
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)

        addRoundButton(settingsButton, systemName: "square.stack.3d.up", accessibilityLabel: localizedString("shared_string_settings"))
        settingsButton.addTarget(self, action: #selector(showConfigureSheet), for: .touchUpInside)

        NSLayoutConstraint.activate([
            closeButton.trailingAnchor.constraint(equalTo: mapControlsContainer.safeAreaLayoutGuide.trailingAnchor, constant: -Layout.contentPadding),
            closeButton.topAnchor.constraint(equalTo: mapControlsContainer.safeAreaLayoutGuide.topAnchor, constant: Layout.contentPadding),

            settingsButton.trailingAnchor.constraint(equalTo: mapControlsContainer.safeAreaLayoutGuide.trailingAnchor, constant: -Layout.contentPadding),
            settingsButton.bottomAnchor.constraint(equalTo: mapControlsContainer.safeAreaLayoutGuide.bottomAnchor, constant: -Layout.contentPadding)
        ])
    }

    private func setupTimeControls() {
        timeControlCard.translatesAutoresizingMaskIntoConstraints = false
        timeControlCard.backgroundColor = UIColor(white: 1, alpha: 0.92)
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

        timeControlButton.setImage(UIImage(systemName: "clock"), for: .normal)
        timeControlButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        timeControlButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        timeControlButton.addTarget(self, action: #selector(toggleTimeSelection), for: .touchUpInside)
        stack.addArrangedSubview(timeControlButton)

        resetTimeButton.addTarget(self, action: #selector(resetTimeButtonPressed), for: .touchUpInside)
        resetTimeButton.widthAnchor.constraint(equalToConstant: Layout.smallButtonSize).isActive = true
        resetTimeButton.heightAnchor.constraint(equalToConstant: Layout.smallButtonSize).isActive = true
        stack.addArrangedSubview(resetTimeButton)

        timeSelectionView.translatesAutoresizingMaskIntoConstraints = false
        timeSelectionView.isHidden = true
        mapControlsContainer.addSubview(timeSelectionView)

        NSLayoutConstraint.activate([
            timeControlCard.centerXAnchor.constraint(equalTo: mapControlsContainer.centerXAnchor),
            timeControlCard.bottomAnchor.constraint(equalTo: mapControlsContainer.safeAreaLayoutGuide.bottomAnchor, constant: -Layout.contentPadding),
            timeControlCard.heightAnchor.constraint(equalToConstant: Layout.buttonSize),

            stack.leadingAnchor.constraint(equalTo: timeControlCard.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: timeControlCard.trailingAnchor),
            stack.topAnchor.constraint(equalTo: timeControlCard.topAnchor),
            stack.bottomAnchor.constraint(equalTo: timeControlCard.bottomAnchor),

            timeSelectionView.centerXAnchor.constraint(equalTo: mapControlsContainer.centerXAnchor),
            timeSelectionView.bottomAnchor.constraint(equalTo: timeControlCard.topAnchor, constant: -Layout.contentPadding)
        ])
    }

    private func setupMagnitudeControls() {
        magnitudeFilterButton.translatesAutoresizingMaskIntoConstraints = false
        magnitudeFilterButton.backgroundColor = UIColor(white: 1, alpha: 0.92)
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

        magnitudeFilterIcon.image = UIImage(systemName: "sparkles")
        magnitudeFilterIcon.tintColor = .systemBlue
        magnitudeFilterIcon.contentMode = .scaleAspectFit
        magnitudeFilterIcon.widthAnchor.constraint(equalToConstant: 24).isActive = true
        magnitudeFilterIcon.heightAnchor.constraint(equalToConstant: 24).isActive = true
        filterStack.addArrangedSubview(magnitudeFilterIcon)

        magnitudeFilterText.textColor = .systemBlue
        magnitudeFilterText.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        filterStack.addArrangedSubview(magnitudeFilterText)

        magnitudeSliderCard.translatesAutoresizingMaskIntoConstraints = false
        magnitudeSliderCard.backgroundColor = UIColor(white: 1, alpha: 0.94)
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
        let title = UILabel()
        title.text = localizedString("astro_min_magnitude")
        title.textColor = .black
        title.font = UIFont.systemFont(ofSize: 14)
        sliderHeader.addArrangedSubview(title)
        sliderHeader.addArrangedSubview(UIView())
        magnitudeSliderValue.textColor = .systemBlue
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

        addRoundButton(resetFovButton, systemName: "arrow.counterclockwise", accessibilityLabel: localizedString("shared_string_reset"))
        resetFovButton.addTarget(self, action: #selector(resetFov), for: .touchUpInside)
        resetFovButton.isHidden = true

        NSLayoutConstraint.activate([
            sliderContainer.widthAnchor.constraint(equalToConstant: Layout.buttonSize),
            sliderContainer.heightAnchor.constraint(equalToConstant: Layout.transparencySliderHeight),
            sliderContainer.centerXAnchor.constraint(equalTo: cameraButton.centerXAnchor),
            sliderContainer.topAnchor.constraint(equalTo: cameraButton.bottomAnchor, constant: Layout.contentPadding),

            transparencySlider.centerXAnchor.constraint(equalTo: sliderContainer.centerXAnchor),
            transparencySlider.centerYAnchor.constraint(equalTo: sliderContainer.centerYAnchor),
            transparencySlider.widthAnchor.constraint(equalToConstant: Layout.transparencySliderHeight),
            transparencySlider.heightAnchor.constraint(equalToConstant: 40),

            resetFovButton.centerXAnchor.constraint(equalTo: sliderContainer.centerXAnchor),
            resetFovButton.topAnchor.constraint(equalTo: sliderContainer.bottomAnchor, constant: 8)
        ])
    }

    private func setupBottomSheetLabel() {
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.textColor = .white
        timeLabel.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        timeLabel.numberOfLines = 2
        timeLabel.textAlignment = .center
        timeLabel.backgroundColor = UIColor(white: 0.02, alpha: 0.68)
        timeLabel.layer.cornerRadius = 8
        timeLabel.layer.masksToBounds = true
        timeLabel.isHidden = true
        mapControlsContainer.addSubview(timeLabel)
        NSLayoutConstraint.activate([
            timeLabel.leadingAnchor.constraint(greaterThanOrEqualTo: mapControlsContainer.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            timeLabel.trailingAnchor.constraint(lessThanOrEqualTo: mapControlsContainer.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            timeLabel.centerXAnchor.constraint(equalTo: mapControlsContainer.centerXAnchor),
            timeLabel.bottomAnchor.constraint(equalTo: timeControlCard.topAnchor, constant: -12)
        ])
    }

    private func addRoundButton(_ button: StarMapButton, systemName: String, accessibilityLabel: String) {
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setIcon(systemName: systemName, accessibilityLabel: accessibilityLabel)
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
    }

    private func syncObjectsToStarView() {
        starView.setSkyObjects(viewModel.skyObjects)
        starView.setConstellations(viewModel.constellations)
        starView.setNeedsDisplay()
    }

    private func applySettings(_ config: AstronomyPluginSettings.StarMapConfig) {
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
        apply2DMode(config.is2DMode)
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
        additionalSafeAreaInsets.bottom = 0
        starView.settings.common.showRegularMap = visible
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
    }

    private func resetTime() {
        updateTime(Date(), animate: true)
    }

    private func setTimeAutoUpdateEnabled(_ enabled: Bool) {
        isTimeAutoUpdateEnabled = enabled
        resetTimeButton.isHidden = enabled
        if enabled {
            resetTime()
            scheduleAutoTimeUpdate()
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
        autoTimeUpdateTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.resetTime()
        }
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

        if let object = selectedObject {
            let altitude = String(format: "%.1f", object.altitude)
            let azimuth = String(format: "%.1f", object.azimuth)
            timeLabel.text = "\(object.getDisplayName())  alt \(altitude) deg, az \(azimuth) deg"
            timeLabel.isHidden = false
        } else {
            timeLabel.isHidden = true
        }
        updateTimeControlTheme()
    }

    private func updateTimeControlTheme() {
        let active = !timeSelectionView.isHidden
        timeControlCard.backgroundColor = active ? .systemBlue : UIColor(white: 1, alpha: 0.92)
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
        let active = !magnitudeSliderCard.isHidden
        magnitudeFilterButton.backgroundColor = active ? .systemBlue : UIColor(white: 1, alpha: 0.92)
        magnitudeFilterIcon.tintColor = active ? .white : .systemBlue
        magnitudeFilterText.textColor = active ? .white : .systemBlue
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

    private func updateButtonsNightMode() {
        let nightMode = true
        arModeButton.nightMode = nightMode
        cameraButton.nightMode = nightMode
        resetFovButton.nightMode = nightMode
        closeButton.nightMode = nightMode
        settingsButton.nightMode = nightMode
        compassButton.nightMode = nightMode
        resetTimeButton.nightMode = nightMode
        timeControlButton.nightMode = nightMode
    }

    private func updateRedMode(_ enabled: Bool) {
        starView.showRedFilter = enabled
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
        mapControlsContainer.isHidden = !bottomSheetContainer.isHidden
    }

    private func clearSelectedObject() {
        selectedObject = nil
        starView.setSelectedObject(nil)
        starView.setSelectedConstellation(nil)
        starView.setNeedsDisplay()
    }

    func getTrackableObjects() -> [SkyObject] {
        viewModel.skyObjects + viewModel.constellations.map { $0 as SkyObject }
    }

    func findTrackableObjectById(_ id: String) -> SkyObject? {
        getTrackableObjects().first { $0.id == id }
    }

    private func hideBottomSheet() {
        hideBottomSheet(clearSelection: true)
    }

    private func hideBottomSheet(clearSelection: Bool) {
        bottomSheetController?.willMove(toParent: nil)
        bottomSheetController?.view.removeFromSuperview()
        bottomSheetController?.removeFromParent()
        bottomSheetController = nil
        bottomSheetContainer.isHidden = true
        if clearSelection {
            clearSelectedObject()
        }
        updateMapControlsVisibility()
    }

    private func setBottomSheetHeight(_ height: CGFloat) {
        let maxHeight = max(Layout.bottomSheetHeight, view.bounds.height * 0.72)
        bottomSheetHeightConstraint?.constant = min(height, maxHeight)
    }

    private func showObjectInfo(_ object: SkyObject) {
        hideBottomSheet(clearSelection: false)

        let controller: UIViewController
        if let constellation = object as? Constellation {
            let sheet = ConstellationInfoFragment(constellation: constellation)
            sheet.onClose = { [weak self] in
                self?.hideBottomSheet()
            }
            controller = sheet
        } else {
            let sheet = SkyObjectInfoFragment(object: object,
                                              date: currentDate,
                                              observer: starView.observer,
                                              dataProvider: dataProvider,
                                              preferredLocale: OsmAndApp.swiftInstance()?.getLanguageCode())
            sheet.onClose = { [weak self] in
                self?.hideBottomSheet()
            }
            controller = sheet
        }

        setBottomSheetHeight(object is Constellation ? Layout.bottomSheetHeight : Layout.objectInfoSheetHeight)
        addChild(controller)
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        bottomSheetContainer.addSubview(controller.view)
        NSLayoutConstraint.activate([
            controller.view.leadingAnchor.constraint(equalTo: bottomSheetContainer.leadingAnchor),
            controller.view.trailingAnchor.constraint(equalTo: bottomSheetContainer.trailingAnchor),
            controller.view.topAnchor.constraint(equalTo: bottomSheetContainer.topAnchor),
            controller.view.bottomAnchor.constraint(equalTo: bottomSheetContainer.bottomAnchor)
        ])
        controller.didMove(toParent: self)
        bottomSheetController = controller
        bottomSheetContainer.isHidden = false
        updateMapControlsVisibility()
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

    @objc private func close() {
        dismiss(animated: true)
    }

    @objc private func showConfigureSheet() {
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
        sheet.onClose = { [weak self] in
            self?.hideBottomSheet(clearSelection: false)
        }

        setBottomSheetHeight(Layout.settingsSheetHeight)
        addChild(sheet)
        sheet.view.translatesAutoresizingMaskIntoConstraints = false
        bottomSheetContainer.addSubview(sheet.view)
        NSLayoutConstraint.activate([
            sheet.view.leadingAnchor.constraint(equalTo: bottomSheetContainer.leadingAnchor),
            sheet.view.trailingAnchor.constraint(equalTo: bottomSheetContainer.trailingAnchor),
            sheet.view.topAnchor.constraint(equalTo: bottomSheetContainer.topAnchor),
            sheet.view.bottomAnchor.constraint(equalTo: bottomSheetContainer.bottomAnchor)
        ])
        sheet.didMove(toParent: self)
        bottomSheetController = sheet
        bottomSheetContainer.isHidden = false
        updateMapControlsVisibility()
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
