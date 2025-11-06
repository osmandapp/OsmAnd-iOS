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
    
    private let locationServices = OsmAndApp.swiftInstance().locationServices
    private let mapViewController = OARootViewController.instance().mapPanel.mapViewController
    private let iconSizeArrayValueKey = "iconSizeArrayValueKey"
    private let iconSizeSelectedValueKey = "iconSizeSelectedValueKey"
    private let iconSizeArrayValues: [Double] = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0, 2.5, 3.0]
    private var baseAppMode: OAApplicationMode?
    
    private lazy var currentIconSize: ProfileAppearanceIconSize? = baseIconSize?.clone()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateCurrentLocation()
        switchAppMode(toChoosenAppMode: true)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        switchAppMode(toChoosenAppMode: false)
        locationServices?.resume()
    }
    
    override func updateModeUI() {
        updateModeUI(isValueChanged: baseIconSize != currentIconSize)
    }
    
    override func registerCells() {
        tableView.register(UINib(nibName: OAValueTableViewCell.reuseIdentifier, bundle: nil),
                           forCellReuseIdentifier: OAValueTableViewCell.reuseIdentifier)
        tableView.register(UINib(nibName: OASegmentSliderTableViewCell.reuseIdentifier, bundle: nil),
                           forCellReuseIdentifier: OASegmentSliderTableViewCell.reuseIdentifier)
    }
    
    override func generateData() {
        super.generateData()
        guard let currentIconSize else { return }

        let section = createSectionWithName()
        
        section.addRow(from: [
            kCellKeyKey: "name",
            kCellTypeKey: OAValueTableViewCell.reuseIdentifier
        ])
        
        section.addRow(from: [
            kCellKeyKey: "slider",
            kCellTypeKey: OASegmentSliderTableViewCell.reuseIdentifier,
            iconSizeSelectedValueKey: String(currentIconSize.size(isNavigation: isNavigationIconSize)),
            iconSizeArrayValueKey: iconSizeArrayValues.map { String($0) }
        ])
    }
    
    override func headerName() -> String {
        localizedString("icon_size")
    }
    
    override func hide() {
        hide(true, duration: hideDuration) { [weak self] in
            guard let self, let currentIconSize, let settingsVC = OAMainSettingsViewController(targetAppMode: appMode, targetScreenKey: kProfileAppearanceSettings, profileAppearanceIconSize: currentIconSize) else { return }

            if baseIconSize != currentIconSize {
                OsmAndApp.swiftInstance().mapSettingsChangeObservable.notifyEvent()
            }
            OARootViewController.instance().navigationController?.pushViewController(settingsVC, animated: false)
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = tableData.item(for: indexPath)

        if item.cellType == OASegmentSliderTableViewCell.reuseIdentifier {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: OASegmentSliderTableViewCell.reuseIdentifier) as? OASegmentSliderTableViewCell else {
                return UITableViewCell()
            }
            let arrayValue = item.obj(forKey: iconSizeArrayValueKey) as? [String] ?? []
            cell.showAllLabels(false)
            cell.delegate = self
            cell.sliderView.setNumberOfMarks(arrayValue.count)
            if let customString = item.obj(forKey: iconSizeSelectedValueKey) as? String, let index = arrayValue.firstIndex(of: customString) {
                cell.sliderView.selectedMark = index
                cell.setupButtonsEnabling()
            }
            cell.showButtons(true)
            cell.sliderView.tag = (indexPath.section << 10) | indexPath.row
            cell.sliderView.removeTarget(self, action: nil, for: [.touchUpInside, .touchUpOutside])
            cell.sliderView.addTarget(self, action: #selector(sliderChanged(sender:)), for: [.touchUpInside, .touchUpOutside])
            return cell
        } else if item.cellType == OAValueTableViewCell.reuseIdentifier {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: OAValueTableViewCell.reuseIdentifier) as? OAValueTableViewCell, let currentIconSize else {
                return UITableViewCell()
            }
            cell.selectionStyle = .none
            cell.setCustomLeftSeparatorInset(true)
            cell.separatorInset = UIEdgeInsets(top: 0, left: CGFLOAT_MAX, bottom: 0, right: 0)
            cell.descriptionVisibility(false)
            cell.leftIconVisibility(false)
            cell.titleLabel.text = localizedString("shared_string_size")
            cell.titleLabel.accessibilityLabel = cell.titleLabel.text
            cell.valueLabel.text = OAUtilities.getPercentString(currentIconSize.size(isNavigation: isNavigationIconSize))
            cell.valueLabel.accessibilityLabel = cell.valueLabel.text
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
        currentIconSize = baseIconSize?.clone()
        refreshMarkerIconSize()
        updateModeUI()
        super.resetButtonPressed()
    }
    
    private func setCurrentIconSize(_ selectedIndex: Int) {
        currentIconSize?.setSize(iconSizeArrayValues[selectedIndex], isNavigation: isNavigationIconSize)
        refreshMarkerIconSize()
        generateData()
        updateModeUI()
    }
    
    private func refreshMarkerIconSize() {
        guard let currentIconSize else { return }
        if isNavigationIconSize {
            mapViewController.refreshMarkersCollection(withCourseFactor: Float(currentIconSize.courseIconSize))
        } else {
            mapViewController.refreshMarkersCollection(withLocationFactor: Float(currentIconSize.locationIconSize))
        }
    }
    
    private func updateCurrentLocation() {
        let scale = mapViewController.view.contentScaleFactor
        let viewSize = view.bounds.size
        let location = mapViewController.getLatLon(fromElevatedPixel: viewSize.width / 2 * scale,
                                                   y: viewSize.height * 0.3 * scale)
        
        let azimuth = -mapViewController.azimuth()
        let direction: Float
        
        if isNavigationIconSize {
            direction = azimuth < 0 ? -azimuth : 360 - azimuth
        } else {
            direction = -(azimuth > 0 ? azimuth : 360 + azimuth)
        }
        
        let newLocation = CLLocation(coordinate: location.coordinate,
                                     altitude: location.altitude,
                                     horizontalAccuracy: location.horizontalAccuracy,
                                     verticalAccuracy: location.verticalAccuracy,
                                     course: CLLocationDirection(direction),
                                     speed: location.speed,
                                     timestamp: location.timestamp)
        locationServices?.setLocationFromSimulation(newLocation)
        locationServices?.suspend()
    }
    
    private func switchAppMode(toChoosenAppMode: Bool) {
        if toChoosenAppMode {
            baseAppMode = settings.applicationMode.get()
            appMode.flatMap(settings.applicationMode.set)
        } else {
            baseAppMode.flatMap(settings.applicationMode.set)
        }
        refreshMarkerIconSize()
    }
    
    @objc private func sliderChanged(sender: UISlider) {
        let indexPath = IndexPath(row: sender.tag & 0x3FF, section: sender.tag >> 10)
        guard let cell = tableView.cellForRow(at: indexPath) as? OASegmentSliderTableViewCell else { return }
        let selectedIndex = Int(cell.sliderView.selectedMark)
        guard selectedIndex >= 0, selectedIndex < iconSizeArrayValues.count else { return }
        setCurrentIconSize(selectedIndex)
    }
}

// MARK: - OASegmentSliderTableViewCellDelegate
extension ProfileAppearanceIconSizeViewController: OASegmentSliderTableViewCellDelegate {
    func onPlusTapped(_ selectedMark: Int) {
        setCurrentIconSize(selectedMark)
    }
    
    func onMinusTapped(_ selectedMark: Int) {
        setCurrentIconSize(selectedMark)
    }
}
