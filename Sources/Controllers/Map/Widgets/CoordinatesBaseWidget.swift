//
//  CoordinatesBaseWidget.swift
//  OsmAnd Maps
//
//  Created by Skalii on 23.07.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

@objc(OACoordinatesBaseWidget)
@objcMembers
class CoordinatesBaseWidget: OABaseWidgetView {
    private static let widgetHeight: CGFloat = 44
    private static let formatPrefId = "coordinates_widget_format"
    
    @IBOutlet private var divider: UIView!
    @IBOutlet private var firstContainer: UIStackView!
    @IBOutlet private var secondContainer: UIStackView!
    @IBOutlet private var firstCoordinate: UILabel! {
        didSet {
            firstCoordinate.textAlignment = isDirectionRTL() ? .right : .left
        }
    }
    @IBOutlet private var secondCoordinate: UILabel! {
        didSet {
            secondCoordinate.textAlignment = isDirectionRTL() ? .right : .left
        }
    }

    @IBOutlet private var firstIcon: UIImageView!
    
    var lastLocation: CLLocation?
    var coloredUnit = false
    
    private var customId: String?
    
    private weak var configViewController: WidgetConfigurationViewController?
    
    private lazy var coordinateFormatPref: OACommonString = {
        Self.registerFormatPref(
            widgetType: widgetType ?? .coordinatesCurrentLocation,
            customId: customId
        )
    }()

    // MARK: Init

    init(type: WidgetType, customId: String?, appMode: OAApplicationMode, widgetParams: [String: Any]? = nil) {
        super.init(frame: .zero)
        self.widgetType = type
        self.customId = customId

        if let widgetValue = widgetParams?[Self.formatPrefId] as? String {
            coordinateFormatPref.set(widgetValue, mode: appMode)
        }
        commonInit()
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(copyCoordinates)))
        updateVisibility(visible: false)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private static func registerFormatPref(widgetType: WidgetType, customId: String?) -> OACommonString {
        var key = "\(formatPrefId)_\(widgetType.id)"
        if let customId, !customId.isEmpty {
            key += "_\(customId)"
        }
        
        return OAAppSettings.sharedManager()
            .registerStringPreference(key, defValue: "")
            .makeProfile()
    }
    
    // MARK: Base override
    
    override func getSettingsData(_ appMode: OAApplicationMode, widgetConfigurationParams: [String: Any]?, isCreate: Bool) -> OATableDataModel? {
        let data = OATableDataModel()
        let section = data.createNewSection()
        section.headerText = localizedString("shared_string_settings")

        let storedId: String
        if isCreate,
           let value = widgetConfigurationParams?[Self.formatPrefId] as? String {
            storedId = value
        } else {
            storedId = coordinateFormatPref.get(appMode)
        }

        let format = resolveFormat(storedId, appMode: appMode)

        let row = section.createNewRow()
        row.cellType = OAValueTableViewCell.getIdentifier()
        row.key = "coordinate_format"
        row.title = localizedString("coords_format")
        row.setObj(format.title, forKey: "value")

        return data
    }
    
    override func handleRowSelected(_ item: OATableRowData, viewController: WidgetConfigurationViewController) -> Bool {
        guard item.key == "coordinate_format" else { return false }

        configViewController = viewController

        let storedId: String
        if viewController.createNew,
           let value = viewController.widgetConfigurationParams?[Self.formatPrefId] as? String {
            storedId = value
        } else {
            storedId = coordinateFormatPref.get(viewController.selectedAppMode)
        }
        let selectedId = storedId.isEmpty
            ? OAAppSettings.sharedManager().coordinateFormatSettingsStorage.getPrimaryId(viewController.selectedAppMode)
            : storedId

        CoordinateFormatSelectorViewController.present(
            from: viewController,
            selectedFormatId: selectedId,
            appMode: viewController.selectedAppMode,
            delegate: self
        )
        return true
    }
    
    override func getWidgetSettingsPref(toReset appMode: OAApplicationMode) -> OACommonPreference? {
        coordinateFormatPref
    }

    override func copySettings(_ appMode: OAApplicationMode, customId: String?) {
        guard let widgetType else { return }
        Self.registerFormatPref(widgetType: widgetType, customId: customId)
            .set(coordinateFormatPref.get(appMode), mode: appMode)
    }
    
    override func updateColors(_ textState: OATextState) {
        super.updateColors(textState)

        backgroundColor = isNightMode() ? .widgetBg.dark : .widgetBg.light

        divider.backgroundColor = isNightMode() ? .widgetSeparator.dark : .widgetSeparator.light

        let textColor: UIColor = isNightMode() ? .white : .black
        firstCoordinate.textColor = textColor
        secondCoordinate.textColor = textColor

        let typefaceStyle: UIFont.Weight = textState.textBold ? .bold : .semibold
        firstCoordinate.font = UIFont.scaledSystemFont(ofSize: firstCoordinate.font.pointSize, weight: typefaceStyle)
        secondCoordinate.font = UIFont.scaledSystemFont(ofSize: secondCoordinate.font.pointSize, weight: typefaceStyle)

        let lastLocation = lastLocation
        if let lastLocation, coloredUnit {
            showFormattedCoordinates(lat: lastLocation.coordinate.latitude, lon: lastLocation.coordinate.longitude)
        }
    }

    override func adjustSize() {
        var selfFrame: CGRect = frame
        selfFrame.size.width = OAUtilities.calculateScreenWidth()
        selfFrame.size.height = Self.widgetHeight
        frame = selfFrame
    }
    
    // MARK: Public func's
    
    func coordinateFormat(_ appMode: OAApplicationMode) -> CoordinateFormat {
        resolveFormat(coordinateFormatPref.get(appMode), appMode: appMode)
    }
    
    func getCoordinateIcon() -> UIImage? {
        nil // override it
    }

    func showFormattedCoordinates(lat: Double, lon: Double) {
        let appMode = OAAppSettings.sharedManager().applicationMode.get()
        let coordFormat = coordinateFormat(appMode)
        lastLocation = CLLocation(latitude: lat, longitude: lon)

        guard let legacy = coordFormat.legacyFormat else {
            showGenericCoordinates(CoordinateFormatHelper.format(coordFormat, lat: lat, lon: lon))
            return
        }

        switch Int32(legacy) {
        case FORMAT_UTM:
            showUtmCoordinates(lat: lat, lon: lon)
        case FORMAT_MGRS:
            showMgrsCoordinates(lat: lat, lon: lon)
        case FORMAT_OLC:
            showOlcCoordinates(lat: lat, lon: lon)
        case SWISS_GRID_FORMAT, SWISS_GRID_PLUS_FORMAT, MAIDENHEAD_FORMAT:
            showGenericCoordinates(CoordinateFormatHelper.format(coordFormat, lat: lat, lon: lon))
        default:
            showStandardCoordinates(lat: lat, lon: lon, format: legacy)
        }
    }
    
    func updateVisibility(visible: Bool) {
        if visible == isHidden {
            isHidden = !visible
            delegate?.widgetVisibilityChanged(self, visible: visible)
        }
    }
    
    // MARK: Private func's
    
    private func commonInit() {
        // swiftlint:disable force_unwrapping
        let widgetView = Bundle.main.loadNibNamed("OACoordinatesBaseWidget", owner: self, options: nil)![0] as! UIView
        // swiftlint:enable force_unwrapping

        widgetView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(widgetView)
       
        NSLayoutConstraint.activate([
            widgetView.leadingAnchor.constraint(equalTo: leadingAnchor),
            widgetView.trailingAnchor.constraint(equalTo: trailingAnchor),
            widgetView.topAnchor.constraint(equalTo: topAnchor),
            widgetView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    private func showGenericCoordinates(_ text: String) {
        setupForNonStandardFormat()
        firstCoordinate.text = text
    }
    
    private func applySelectedFormat(_ formatId: String) {
        guard let vc = configViewController else { return }

        if vc.createNew {
            vc.widgetConfigurationParams?[Self.formatPrefId] = formatId
        } else {
            coordinateFormatPref.set(formatId, mode: vc.selectedAppMode)
            _ = updateInfo()
            OARootViewController.instance().mapPanel.recreateControls()
        }
        vc.onWidgetStateChanged()
    }
    
    private func resolveFormat(_ id: String, appMode: OAApplicationMode) -> CoordinateFormat {
        let resolvedId = id.isEmpty
            ? OAAppSettings.sharedManager().coordinateFormatSettingsStorage.getPrimaryId(appMode)
            : id
        return CoordinateFormatHelper.resolve([resolvedId]).first ?? BuiltInCoordinateFormat.ddd.toCoordinateFormat()
    }

    private func showUtmCoordinates(lat: Double, lon: Double) {
        setupForNonStandardFormat()
        let utmPoint = OALocationConvert.getUTMCoordinateString(lat, lon: lon)
        firstCoordinate.text = utmPoint
    }

    private func showMgrsCoordinates(lat: Double, lon: Double) {
        setupForNonStandardFormat()
        let mgrsPoint = OALocationConvert.getMgrsCoordinateString(lat, lon: lon)
        firstCoordinate.text = mgrsPoint
    }

    private func showOlcCoordinates(lat: Double, lon: Double) {
        setupForNonStandardFormat()
        let olcCoordinates = OALocationConvert.getLocationOlcName(lat, lon: lon)
        firstCoordinate.text = olcCoordinates
    }

    private func setupForNonStandardFormat() {
        firstIcon.isHidden = false
        divider.isHidden = true
        secondContainer.isHidden = true
        firstIcon.image = getCoordinateIcon()
        coloredUnit = false
        secondCoordinate.attributedText = nil
        secondCoordinate.text = nil
        
        firstContainer.semanticContentAttribute = isDirectionRTL() ? .forceRightToLeft : .forceLeftToRight
    }

    private func showStandardCoordinates(lat: Double, lon: Double, format: Int) {
        firstIcon.isHidden = false
        divider.isHidden = false
        secondContainer.isHidden = false
        coloredUnit = true

        firstIcon.image = getCoordinateIcon()
        
        if isDirectionRTL() {
            secondContainer.addArrangedSubview(firstIcon)
        }

        var latitude = OALocationConvert.convertLatitude(lat, outputType: format, addCardinalDirection: true)
        var longitude = OALocationConvert.convertLongitude(lon, outputType: format, addCardinalDirection: true)

        if latitude == nil {
            latitude = ""
        }
        if longitude == nil {
            longitude = ""
        }

        let coordColor: UIColor = isNightMode() ? .white : .black
        let unitColor = UIColor(rgb: 0x7D738C)
        
        if let latitude {
            let attributedLat = NSMutableAttributedString(string: latitude)
            if latitude.length > 2 {
                attributedLat.addAttribute(.foregroundColor, value: coordColor, range: NSRange(location: 0, length: latitude.length - 2))
                attributedLat.addAttribute(.foregroundColor, value: unitColor, range: NSRange(location: latitude.length - 1, length: 1))
            }
            firstCoordinate.attributedText = attributedLat
        }
        
        if let longitude {
            let attributedLon = NSMutableAttributedString(string: longitude)
            if longitude.length > 2 {
                attributedLon.addAttribute(.foregroundColor, value: coordColor, range: NSRange(location: 0, length: longitude.length - 2))
                attributedLon.addAttribute(.foregroundColor, value: unitColor, range: NSRange(location: longitude.length - 1, length: 1))
            }
            secondCoordinate.attributedText = attributedLon
        }
    }
    
    @objc private func copyCoordinates() {
        guard lastLocation != nil else {
            return
        }

        var coordinates = firstCoordinate.text ?? ""
        if !secondContainer.isHidden {
            coordinates += ", \(secondCoordinate.text ?? "")"
        }

        let pasteboard = UIPasteboard.general
        pasteboard.string = coordinates

        let toastMessage = isDirectionRTL() ? "\(coordinates) :\(localizedString("copied_to_clipboard"))" : String(format: localizedString("ltr_or_rtl_combine_via_colon"), localizedString("copied_to_clipboard"), coordinates)

        OAUtilities.showToast(toastMessage, details: nil, duration: 4, in: OARootViewController.instance().view)
    }
}

extension CoordinatesBaseWidget: CoordinateFormatSelectorDelegate {

    func coordinateFormatSelector(_ selector: CoordinateFormatSelectorViewController, didSelectFormatId formatId: String) {
        applySelectedFormat(formatId)
    }

    func coordinateFormatSelectorDidRequestOtherFormat(_ selector: CoordinateFormatSelectorViewController) {
        guard let vc = configViewController else { return }
        
        let excluded = OAAppSettings.sharedManager().coordinateFormatSettingsStorage.preferredIds(vc.selectedAppMode)
        
        CoordinateFormatSelectorRouter.presentAdd(from: vc, appMode: vc.selectedAppMode, excludedIds: excluded) { [weak self] id in
            self?.applySelectedFormat(id)
        }
    }
}
