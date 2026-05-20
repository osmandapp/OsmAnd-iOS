//
//  AstronomyViewController.swift
//  OsmAnd Maps
//
//  Created by Codex on 19.05.2026.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

import CoreLocation
import UIKit

final class AstronomyViewController: UIViewController, StarViewDelegate {
    private let plugin: AstronomyPlugin
    private var settings: AstronomyPluginSettings
    private let viewModel: StarObjectsViewModel
    private let starView = StarView()
    private let arModeHelper = StarMapARModeHelper()
    private let cameraHelper = StarMapCameraHelper()
    private let topStack = UIStackView()
    private let bottomStack = UIStackView()
    private let settingsPanel = UIStackView()
    private let infoLabel = UILabel()
    private let timeLabel = UILabel()
    private let magnitudeSlider = UISlider()

    private var timer: Timer?
    private var isPlaying = false
    private var isSettingsVisible = false

    init(plugin: AstronomyPlugin) {
        self.plugin = plugin
        settings = AstronomyPluginSettings.load()
        viewModel = StarObjectsViewModel(provider: plugin.dataProvider, settings: settings)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupStarView()
        setupTopControls()
        setupBottomControls()
        setupSettingsPanel()
        setupInfoLabel()
        setupHelpers()

        viewModel.onDataChanged = { [weak self] in
            self?.starView.setNeedsDisplay()
            self?.updateLabels()
        }
        viewModel.load(preferredLocale: OsmAndApp.swiftInstance()?.getLanguageCode())
        updatePositions()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        timer?.invalidate()
        arModeHelper.stop()
        cameraHelper.stopPreview()
        starView.isCameraMode = false
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        cameraHelper.layoutPreview()
    }

    private func setupStarView() {
        starView.translatesAutoresizingMaskIntoConstraints = false
        starView.delegate = self
        starView.viewModel = viewModel
        starView.settings = settings
        view.addSubview(starView)
        NSLayoutConstraint.activate([
            starView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            starView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            starView.topAnchor.constraint(equalTo: view.topAnchor),
            starView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupTopControls() {
        topStack.axis = .horizontal
        topStack.alignment = .center
        topStack.spacing = 8
        topStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(topStack)

        topStack.addArrangedSubview(makeButton(systemName: "xmark", title: "x", action: #selector(close)))
        topStack.addArrangedSubview(makeButton(systemName: "slider.horizontal.3", title: localizedString("shared_string_settings"), action: #selector(toggleSettingsPanel)))
        topStack.addArrangedSubview(makeButton(systemName: "scope", title: localizedString("astro_ar"), action: #selector(toggleARMode)))
        topStack.addArrangedSubview(makeButton(systemName: "camera", title: localizedString("astro_camera"), action: #selector(toggleCamera)))
        topStack.addArrangedSubview(makeButton(systemName: "arrow.counterclockwise", title: localizedString("shared_string_reset"), action: #selector(resetView)))

        timeLabel.textColor = .white
        timeLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 13, weight: .medium)
        timeLabel.numberOfLines = 1
        timeLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        topStack.addArrangedSubview(timeLabel)

        NSLayoutConstraint.activate([
            topStack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 12),
            topStack.trailingAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -12),
            topStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10)
        ])
    }

    private func setupBottomControls() {
        bottomStack.axis = .horizontal
        bottomStack.alignment = .center
        bottomStack.spacing = 8
        bottomStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bottomStack)

        bottomStack.addArrangedSubview(makeButton(systemName: "gobackward.15", title: "-15", action: #selector(stepBackward)))
        bottomStack.addArrangedSubview(makeButton(systemName: "playpause", title: localizedString("shared_string_play"), action: #selector(togglePlay)))
        bottomStack.addArrangedSubview(makeButton(systemName: "goforward.15", title: "+15", action: #selector(stepForward)))
        bottomStack.addArrangedSubview(makeButton(systemName: "square.grid.2x2", title: "2D", action: #selector(toggle2DMode)))
        bottomStack.addArrangedSubview(makeButton(systemName: "map", title: localizedString("shared_string_map"), action: #selector(toggleMapOverlay)))

        magnitudeSlider.minimumValue = -2
        magnitudeSlider.maximumValue = 8
        magnitudeSlider.value = Float(settings.starMap.magnitudeFilter ?? 6)
        magnitudeSlider.isEnabled = settings.starMap.showMagnitudeFilter
        magnitudeSlider.addTarget(self, action: #selector(magnitudeChanged), for: .valueChanged)
        magnitudeSlider.widthAnchor.constraint(equalToConstant: 120).isActive = true
        bottomStack.addArrangedSubview(magnitudeSlider)

        NSLayoutConstraint.activate([
            bottomStack.leadingAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 12),
            bottomStack.trailingAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -12),
            bottomStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            bottomStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }

    private func setupSettingsPanel() {
        settingsPanel.axis = .vertical
        settingsPanel.spacing = 10
        settingsPanel.isHidden = true
        settingsPanel.translatesAutoresizingMaskIntoConstraints = false
        settingsPanel.layoutMargins = UIEdgeInsets(top: 14, left: 14, bottom: 14, right: 14)
        settingsPanel.isLayoutMarginsRelativeArrangement = true
        settingsPanel.backgroundColor = UIColor(white: 0.03, alpha: 0.88)
        settingsPanel.layer.cornerRadius = 8
        settingsPanel.layer.masksToBounds = true
        view.addSubview(settingsPanel)

        addSwitchRow(localizedString("astro_stars"), isOn: settings.starMap.showStars) { [weak self] value in
            self?.settings.starMap.showStars = value
        }
        addSwitchRow(localizedString("astro_planets"), isOn: settings.starMap.showPlanets) { [weak self] value in
            self?.settings.starMap.showPlanets = value
        }
        addSwitchRow(localizedString("astro_sun"), isOn: settings.starMap.showSun) { [weak self] value in
            self?.settings.starMap.showSun = value
        }
        addSwitchRow(localizedString("astro_moon"), isOn: settings.starMap.showMoon) { [weak self] value in
            self?.settings.starMap.showMoon = value
        }
        addSwitchRow(localizedString("astro_constellations"), isOn: settings.starMap.showConstellations) { [weak self] value in
            self?.settings.starMap.showConstellations = value
        }
        addSwitchRow(localizedString("astro_deep_sky"), isOn: deepSkyEnabled) { [weak self] value in
            self?.settings.starMap.showGalaxies = value
            self?.settings.starMap.showNebulae = value
            self?.settings.starMap.showOpenClusters = value
            self?.settings.starMap.showGlobularClusters = value
            self?.settings.starMap.showGalaxyClusters = value
            self?.settings.starMap.showBlackHoles = value
        }
        addSwitchRow(localizedString("astro_azimuthal_grid"), isOn: settings.starMap.showAzimuthalGrid) { [weak self] value in
            self?.settings.starMap.showAzimuthalGrid = value
        }
        addSwitchRow(localizedString("astro_reference_lines"), isOn: referenceLinesEnabled) { [weak self] value in
            self?.settings.starMap.showEquatorialGrid = value
            self?.settings.starMap.showEclipticLine = value
            self?.settings.starMap.showEquatorLine = value
            self?.settings.starMap.showGalacticLine = value
        }
        addSwitchRow(localizedString("astro_magnitude_filter"), isOn: settings.starMap.showMagnitudeFilter) { [weak self] value in
            self?.settings.starMap.showMagnitudeFilter = value
            self?.magnitudeSlider.isEnabled = value
        }
        addSwitchRow(localizedString("astro_red_filter"), isOn: settings.starMap.showRedFilter) { [weak self] value in
            self?.settings.starMap.showRedFilter = value
        }

        NSLayoutConstraint.activate([
            settingsPanel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 12),
            settingsPanel.topAnchor.constraint(equalTo: topStack.bottomAnchor, constant: 12),
            settingsPanel.widthAnchor.constraint(lessThanOrEqualToConstant: 310)
        ])
    }

    private func setupInfoLabel() {
        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        infoLabel.textColor = .white
        infoLabel.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        infoLabel.numberOfLines = 2
        infoLabel.textAlignment = .center
        infoLabel.backgroundColor = UIColor(white: 0.02, alpha: 0.68)
        infoLabel.layer.cornerRadius = 8
        infoLabel.layer.masksToBounds = true
        view.addSubview(infoLabel)
        NSLayoutConstraint.activate([
            infoLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            infoLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            infoLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            infoLabel.bottomAnchor.constraint(equalTo: bottomStack.topAnchor, constant: -12)
        ])
        updateLabels()
    }

    private func setupHelpers() {
        arModeHelper.onOrientationChanged = { [weak self] azimuth, altitude, roll in
            self?.starView.setCameraOrientation(azimuth: azimuth, altitude: altitude, roll: roll)
        }
        arModeHelper.onUnavailable = { [weak self] in
            self?.starView.isCameraMode = self?.cameraHelper.isRunning == true
            self?.showMessage(localizedString("astro_ar_unavailable"))
        }
        cameraHelper.onUnavailable = { [weak self] message in
            self?.starView.isCameraMode = self?.arModeHelper.isRunning == true
            self?.showMessage(message)
        }
    }

    private var deepSkyEnabled: Bool {
        settings.starMap.showGalaxies || settings.starMap.showNebulae || settings.starMap.showOpenClusters ||
            settings.starMap.showGlobularClusters || settings.starMap.showGalaxyClusters || settings.starMap.showBlackHoles
    }

    private var referenceLinesEnabled: Bool {
        settings.starMap.showEquatorialGrid || settings.starMap.showEclipticLine ||
            settings.starMap.showEquatorLine || settings.starMap.showGalacticLine
    }

    private func addSwitchRow(_ title: String, isOn: Bool, onChange: @escaping (Bool) -> Void) {
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 12

        let label = UILabel()
        label.text = title
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 14)
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        row.addArrangedSubview(label)

        let toggle = SettingSwitch()
        toggle.isOn = isOn
        toggle.onChange = { [weak self] value in
            onChange(value)
            self?.saveSettings()
        }
        toggle.addTarget(toggle, action: #selector(SettingSwitch.valueChanged), for: .valueChanged)
        row.addArrangedSubview(toggle)
        settingsPanel.addArrangedSubview(row)
    }

    private func makeButton(systemName: String, title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.tintColor = .white
        button.backgroundColor = UIColor(white: 0.06, alpha: 0.74)
        button.layer.cornerRadius = 8
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)
        if let image = UIImage(systemName: systemName) {
            button.setImage(image, for: .normal)
            button.accessibilityLabel = title
        } else {
            button.setTitle(title, for: .normal)
        }
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    private func saveSettings() {
        settings.save()
        starView.settings = settings
        viewModel.updateSettings(settings)
        magnitudeSlider.isEnabled = settings.starMap.showMagnitudeFilter
    }

    private func updatePositions() {
        let location = OsmAndApp.swiftInstance()?.locationServices?.lastKnownLocation
        viewModel.updatePositions(date: viewModel.state.date, location: location)
    }

    private func updateLabels() {
        timeLabel.text = AstroUtils.formattedTime(viewModel.state.date)
        if let object = viewModel.state.selectedObject {
            let altitude = object.altitude.map { String(format: "%.1f", $0) } ?? "-"
            let azimuth = object.azimuth.map { String(format: "%.1f", $0) } ?? "-"
            infoLabel.text = "\(object.displayName)  alt \(altitude) deg, az \(azimuth) deg"
            infoLabel.isHidden = false
        } else if viewModel.state.dataSnapshot?.usedFallback == true {
            infoLabel.text = localizedString("astro_using_solar_system_fallback")
            infoLabel.isHidden = false
        } else {
            infoLabel.isHidden = true
        }
    }

    private func showMessage(_ message: String) {
        let alert = UIAlertController(title: localizedString("astronomy_plugin_name"), message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: localizedString("shared_string_ok"), style: .default))
        present(alert, animated: true)
    }

    func starView(_ starView: StarView, didSelect object: SkyObject?) {
        updateLabels()
    }

    @objc private func close() {
        dismiss(animated: true)
    }

    @objc private func toggleSettingsPanel() {
        isSettingsVisible.toggle()
        settingsPanel.isHidden = !isSettingsVisible
    }

    @objc private func toggleARMode() {
        if arModeHelper.isRunning {
            arModeHelper.stop()
            starView.isCameraMode = cameraHelper.isRunning
        } else {
            starView.isCameraMode = true
            arModeHelper.start()
        }
    }

    @objc private func toggleCamera() {
        if cameraHelper.isRunning {
            cameraHelper.stopPreview()
            starView.isCameraMode = false
        } else {
            starView.isCameraMode = true
            cameraHelper.startPreview(in: view, below: starView)
        }
    }

    @objc private func resetView() {
        starView.resetView()
    }

    @objc private func stepBackward() {
        viewModel.state.date = viewModel.state.date.addingTimeInterval(-15 * 60)
        updatePositions()
    }

    @objc private func stepForward() {
        viewModel.state.date = viewModel.state.date.addingTimeInterval(15 * 60)
        updatePositions()
    }

    @objc private func togglePlay() {
        isPlaying.toggle()
        timer?.invalidate()
        guard isPlaying else {
            timer = nil
            return
        }
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else {
                return
            }
            self.viewModel.state.date = self.viewModel.state.date.addingTimeInterval(60)
            self.updatePositions()
        }
    }

    @objc private func toggle2DMode() {
        settings.starMap.is2DMode.toggle()
        saveSettings()
    }

    @objc private func toggleMapOverlay() {
        settings.common.showRegularMap.toggle()
        saveSettings()
    }

    @objc private func magnitudeChanged() {
        settings.starMap.magnitudeFilter = Double(magnitudeSlider.value)
        saveSettings()
    }
}

private final class SettingSwitch: UISwitch {
    var onChange: ((Bool) -> Void)?

    @objc func valueChanged() {
        onChange?(isOn)
    }
}
