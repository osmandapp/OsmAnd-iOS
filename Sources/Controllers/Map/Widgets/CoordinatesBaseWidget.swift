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
    
    private static let widgetHeight: CGFloat = 44

    var lastLocation: CLLocation?
    var coloredUnit = false
    
    // MARK: Init

    override init(type: WidgetType) {
        super.init(frame: .zero)
        self.widgetType = type
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
    
//    private func configureRTLState() {
//        if isDirectionRTL() {
//            secondContainer.addArrangedSubview(firstIcon)
//        }
//    }
    
    // MARK: Base override
    
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
    
    func getCoordinateIcon() -> UIImage? {
        nil // override it
    }

    func showFormattedCoordinates(lat: Double, lon: Double) {
        let format = Int(OAAppSettings.sharedManager().settingGeoFormat.get())
        lastLocation = CLLocation(latitude: lat, longitude: lon)

        switch format {
        case MAP_GEO_UTM_FORMAT:
            showUtmCoordinates(lat: lat, lon: lon)
        case MAP_GEO_MGRS_FORMAT:
            showMgrsCoordinates(lat: lat, lon: lon)
        case MAP_GEO_OLC_FORMAT:
            showOlcCoordinates(lat: lat, lon: lon)
        default:
            showStandardCoordinates(lat: lat, lon: lon, format: Int(format))
        }
    }
    
    func updateVisibility(visible: Bool) {
        if visible == isHidden {
            isHidden = !visible
            delegate?.widgetVisibilityChanged(self, visible: visible)
        }
    }
    
    // MARK: Private func's

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
        
       // firstContainer
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

        let firstCoordText = firstCoordinate.text ?? ""
        let secondCoordText = secondCoordinate.text ?? ""
        let coordinates = "\(firstCoordText), \(secondCoordText)"

        let pasteboard = UIPasteboard.general
        pasteboard.string = coordinates

        let toastMessage = isDirectionRTL() ? "\(coordinates) :\(localizedString("copied_to_clipboard"))" : String(format: localizedString("ltr_or_rtl_combine_via_colon"), localizedString("copied_to_clipboard"), coordinates)

        OAUtilities.showToast(toastMessage, details: nil, duration: 4, in: OARootViewController.instance().view)
    }
}
