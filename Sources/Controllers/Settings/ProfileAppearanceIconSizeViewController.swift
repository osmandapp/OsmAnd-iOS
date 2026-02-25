//
//  ProfileAppearanceIconSizeViewController.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 28.10.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
final class ProfileAppearanceIconSize: NSObject, ProfileAppearanceConfig {
    var locationIconSize: Double
    var courseIconSize: Double
    
    init(locationIconSize: Double, courseIconSize: Double) {
        self.locationIconSize = locationIconSize
        self.courseIconSize = courseIconSize
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? ProfileAppearanceIconSize else {
            return false
        }
        return locationIconSize == other.locationIconSize && courseIconSize == other.courseIconSize
    }
    
    func clone() -> ProfileAppearanceIconSize {
        ProfileAppearanceIconSize(locationIconSize: locationIconSize, courseIconSize: courseIconSize)
    }
    
    func size(isNavigation: Bool) -> Double {
        isNavigation ? courseIconSize : locationIconSize
    }
    
    func setSize(_ size: Double, isNavigation: Bool) {
        if isNavigation {
            courseIconSize = size
        } else {
            locationIconSize = size
        }
    }
}

@objcMembers
final class ProfileAppearanceIconSizeViewController: BaseSettingsParametersViewController {
    var appMode: OAApplicationMode?
    var isNavigationIconSize: Bool = false
    var baseIconSize: ProfileAppearanceIconSize?
    var navControllerHistory: [UIViewController] = []
    
    private let locationServices = OsmAndApp.swiftInstance().locationServices
    private let mapViewController = OARootViewController.instance().mapPanel.mapViewController
    private let iconSizeArrayValueKey = "iconSizeArrayValueKey"
    private let iconSizeSelectedValueKey = "iconSizeSelectedValueKey"
    private let iconSizeArrayValues: [Double] = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0, 2.5, 3.0]
    private var baseAppMode: OAApplicationMode?
    private var markerLocation: CLLocation?
    
    private lazy var currentIconSize: ProfileAppearanceIconSize? = baseIconSize?.clone()
    private lazy var defaultIconSize = isNavigationIconSize ? settings.courseIconSize.defValue : settings.locationIconSize.defValue
    
    override func viewDidLoad() {
        super.viewDidLoad()
        (view as? OAUserInteractionPassThroughView)?.isScreenClickable = false
        mapViewController.cancelAllAnimations()
        OsmAndApp.swiftInstance().mapMode = .free
        updateCurrentLocation()
        switchAppMode(toChoosenAppMode: true)
        refreshMarkerIconSize()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        switchAppMode(toChoosenAppMode: false)
        mapViewController.hidePreviewMarker()
    }
    
    override func updateModeUI() {
        let isValueChangedForApply = baseIconSize != currentIconSize
        updateApplyButton(isValueChanged: isValueChangedForApply)
        resetButton.isEnabled = isNavigationIconSize ? currentIconSize?.courseIconSize != defaultIconSize : currentIconSize?.locationIconSize != defaultIconSize

        tableView.reloadSections(IndexSet(integer: 0), with: .none)
    }
    
    override func registerCells() {
        tableView.register(UINib(nibName: SegmentButtonsSliderTableViewCell.reuseIdentifier, bundle: nil),
                           forCellReuseIdentifier: SegmentButtonsSliderTableViewCell.reuseIdentifier)
    }
    
    override func generateData() {
        super.generateData()
        guard let currentIconSize else { return }

        let section = createSectionWithName()
        
        section.addRow(from: [
            kCellKeyKey: "slider",
            kCellTypeKey: SegmentButtonsSliderTableViewCell.reuseIdentifier,
            iconSizeSelectedValueKey: String(currentIconSize.size(isNavigation: isNavigationIconSize)),
            iconSizeArrayValueKey: iconSizeArrayValues.map { String($0) }
        ])
    }
    
    override func headerName() -> String {
        localizedString("icon_size")
    }
    
    override func hide() {
        hide(true, duration: hideDuration) { [weak self] in
            guard let self, let currentIconSize else { return }
            
            if baseIconSize != currentIconSize {
                OsmAndApp.swiftInstance().mapSettingsChangeObservable.notifyEvent()
            }
            
            if let profileAppearanceViewController = navControllerHistory.last as? ProfileAppearanceUpdateSize {
                profileAppearanceViewController.updateIconSize(currentIconSize)
            }
            OARootViewController.instance().navigationController?.setViewControllers(navControllerHistory, animated: true)
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = tableData.item(for: indexPath)

        if item.cellType == SegmentButtonsSliderTableViewCell.reuseIdentifier {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: SegmentButtonsSliderTableViewCell.reuseIdentifier) as? SegmentButtonsSliderTableViewCell,
                  let currentIconSize else {
                return UITableViewCell()
            }
            let arrayValue = item.obj(forKey: iconSizeArrayValueKey) as? [String] ?? []
            cell.delegate = self
            cell.sliderView.setNumberOfMarks(arrayValue.count)
            if let customString = item.obj(forKey: iconSizeSelectedValueKey) as? String, let index = arrayValue.firstIndex(of: customString) {
                cell.sliderView.selectedMark = index
                cell.setupButtonsEnabling()
            }
            cell.sliderView.tag = (indexPath.section << 10) | indexPath.row
            cell.sliderView.removeTarget(self, action: nil, for: [.touchUpInside, .touchUpOutside])
            cell.sliderView.addTarget(self, action: #selector(sliderChanged(sender:)), for: [.touchUpInside, .touchUpOutside])
            cell.topLeftLabel.text = localizedString("shared_string_size")
            cell.topLeftLabel.accessibilityLabel = cell.topLeftLabel.text
            cell.topRightLabel.text = NumberFormatter.percentFormatter.string(from: currentIconSize.size(isNavigation: isNavigationIconSize) as NSNumber)
            cell.topRightLabel.accessibilityLabel = cell.topRightLabel.text
            return cell
        }
        return UITableViewCell()
    }
    
    override func cancelButtonPressed() {
        currentIconSize = baseIconSize?.clone()
        refreshMarkerIconSize()
        super.cancelButtonPressed()
    }
    
    override func resetButtonPressed() {
        if isNavigationIconSize {
            currentIconSize?.courseIconSize = defaultIconSize
        } else {
            currentIconSize?.locationIconSize = defaultIconSize
        }
        refreshMarkerIconSize()
        updateModeUI()
        super.resetButtonPressed()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate { [weak self] _ in
            guard let landscape = self?.isLandscape(), !landscape else { return }
            self?.goMinimized()
        } completion: { [weak self] _ in
            self?.updateCurrentLocation()
            self?.refreshMarkerIconSize()
        }
    }
    
    private func setCurrentIconSize(_ selectedIndex: Int) {
        currentIconSize?.setSize(iconSizeArrayValues[selectedIndex], isNavigation: isNavigationIconSize)
        refreshMarkerIconSize()
        generateData()
        updateModeUI()
    }
    
    private func refreshMarkerIconSize() {
        guard let currentIconSize, let markerLocation else { return }
        mapViewController.updatePreviewMarker(markerLocation, locationFactor: Float(currentIconSize.locationIconSize), courseFactor: Float(currentIconSize.courseIconSize), showBearing: isNavigationIconSize)
    }
    
    private func updateCurrentLocation() {
        let scale = mapViewController.view.contentScaleFactor
        let viewSize = view.bounds.size
        let isLandscaped = isLandscape()
        let location: CLLocation
        
        if isLandscaped {
            location = mapViewController.getLatLon(fromElevatedPixel: viewSize.width * 0.6 * scale,
                                                   y: viewSize.height / 2 * scale)
        } else {
            location = mapViewController.getLatLon(fromElevatedPixel: viewSize.width / 2 * scale,
                                                   y: viewSize.height * 0.3 * scale)
        }
        
        let azimuth = -mapViewController.azimuth()
        let direction: Float
        
        if isNavigationIconSize {
            direction = azimuth < 0 ? -azimuth : 360 - azimuth
        } else {
            direction = -(azimuth > 0 ? azimuth : 360 + azimuth)
        }
        
        markerLocation = CLLocation(coordinate: location.coordinate,
                                    altitude: location.altitude,
                                    horizontalAccuracy: location.horizontalAccuracy,
                                    verticalAccuracy: location.verticalAccuracy,
                                    course: CLLocationDirection(direction),
                                    speed: location.speed,
                                    timestamp: location.timestamp)
    }
    
    private func switchAppMode(toChoosenAppMode: Bool) {
        if toChoosenAppMode {
            baseAppMode = settings.applicationMode.get()
            appMode.flatMap(settings.applicationMode.set)
        } else {
            baseAppMode.flatMap(settings.applicationMode.set)
        }
    }
    
    private func suspendLocationService() {
        guard !OARoutingHelper.sharedInstance().isFollowingMode() else { return }
        locationServices?.suspend()
    }
    
    private func resumeLocationService() {
        guard !OARoutingHelper.sharedInstance().isFollowingMode() else { return }
        locationServices?.resume()
    }
    
    @objc private func sliderChanged(sender: UISlider) {
        let indexPath = IndexPath(row: sender.tag & 0x3FF, section: sender.tag >> 10)
        guard let cell = tableView.cellForRow(at: indexPath) as? SegmentButtonsSliderTableViewCell else { return }
        let selectedIndex = Int(cell.sliderView.selectedMark)
        guard selectedIndex >= 0, selectedIndex < iconSizeArrayValues.count else { return }
        setCurrentIconSize(selectedIndex)
    }
}

// MARK: - SegmentButtonsSliderTableViewCellDelegate
extension ProfileAppearanceIconSizeViewController: SegmentButtonsSliderTableViewCellDelegate {
    func onPlusTapped(_ selectedMark: Int, sender: UISlider) {
        setCurrentIconSize(selectedMark)
    }
    
    func onMinusTapped(_ selectedMark: Int, sender: UISlider) {
        setCurrentIconSize(selectedMark)
    }
    
    func onSliderValueChanged(_ selectedMark: Int, sender: UISlider) {}
}
