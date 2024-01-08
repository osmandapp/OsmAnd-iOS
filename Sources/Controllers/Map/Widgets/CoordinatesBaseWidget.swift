//
//  CoordinatesBaseWidget.swift
//  OsmAnd Maps
//
//  Created by Skalii on 23.07.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

@objc(OACoordinatesBaseWidget)
@objcMembers
class CoordinatesBaseWidget: OABaseWidgetView {

    private static let widgetHeight: CGFloat = 44

    @IBOutlet var divider: UIView!
    @IBOutlet var secondContainer: UIStackView!
    @IBOutlet var firstCoordinate: UILabel! {
        didSet {
            firstCoordinate.adjustsFontForContentSizeCategory = true
            firstCoordinate.textAlignment = isDirectionRTL() ? .right : .left
        }
    }
    @IBOutlet var secondCoordinate: UILabel! {
        didSet {
            secondCoordinate.adjustsFontForContentSizeCategory = true
            secondCoordinate.textAlignment = isDirectionRTL() ? .right : .left
        }
    }

    @IBOutlet var firstIcon: UIImageView!

    var lastLocation: CLLocation?
    var coloredUnit = false

    override init(type: WidgetType) {
        super.init(frame: CGRect(x: 0, y: 0, width: 360, height: Self.widgetHeight))
        self.widgetType = type
        commonInit()

        let gesture = UITapGestureRecognizer(target: self, action: #selector(copyCoordinates))
        self.addGestureRecognizer(gesture)

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
        let view = Bundle.main.loadNibNamed("OACoordinatesBaseWidget", owner: self, options: nil)![0] as! UIView
        self.addSubview(view)
        view.frame = self.bounds
    }

    func copyCoordinates() {
        guard let lastLocation = lastLocation else {
            return
        }

        let firstCoordText = firstCoordinate.text ?? ""
        let secondCoordText = secondCoordinate.text ?? ""
        var coordinates = ""

        if isDirectionRTL() {
            coordinates = "\(secondCoordText), \(firstCoordText)"
        } else {
            coordinates = "\(firstCoordText), \(secondCoordText)"
        }

        let pasteboard: UIPasteboard = UIPasteboard.general
        pasteboard.string = coordinates

        let toastMessage = isDirectionRTL() ? "\(coordinates) :\(localizedString("copied_to_clipboard"))" : String(format: localizedString("ltr_or_rtl_combine_via_colon"), localizedString("copied_to_clipboard"), coordinates)

        OAUtilities.showToast(toastMessage, details: nil, duration: 4, in: OARootViewController.instance().view)
    }

    func showFormattedCoordinates(lat: Double, lon: Double) {
        let format = OAAppSettings.sharedManager().settingGeoFormat.get()
        lastLocation = CLLocation(latitude: lat, longitude: lon)

        switch format {
        case MAP_GEO_UTM_FORMAT:
            showUtmCoordinates(lat: lat, lon: lon)
        case MAP_GEO_MGRS_FORMAT:
            showMgrsCoordinates(lat: lat, lon: lon)
        case MAP_GEO_OLC_FORMAT:
            showOlcCoordinates(lat: lat, lon: lon)
//        case SWISS_GRID_FORMAT:
//            showSwissGrid(lat: lat, lon: lon, swissGridPlus: false)
//        case SWISS_GRID_PLUS_FORMAT:
//            showSwissGrid(lat: lat, lon: lon, swissGridPlus: true)
        default:
            showStandardCoordinates(lat: lat, lon: lon, format: Int(format))
        }
    }

    private func showUtmCoordinates(lat: Double, lon: Double) {
        setupForNonStandardFormat()
        let utmPoint = OALocationConvert.getUTMCoordinateString(lat, lon: lon)
        firstCoordinate.text = utmPoint
    }

    private func showMgrsCoordinates(lat: Double, lon: Double) {
        setupForNonStandardFormat()
        let mgrsPoint = OALocationConvert.getMgrsCoordinateString(lat, lon:lon)
        firstCoordinate.text = mgrsPoint
    }

    private func showOlcCoordinates(lat: Double, lon: Double) {
        setupForNonStandardFormat()
        let olcCoordinates = OALocationConvert.getLocationOlcName(lat, lon:lon)
        firstCoordinate.text = olcCoordinates
    }

//    private func showSwissGrid(lat: Double, lon: Double, swissGridPlus: Bool) {
//        let latLon = LatLon(lat: lat, lon: lon)
//        let swissGrid = swissGridPlus
//            ? SwissGridApproximation.convertWGS84ToLV95(latLon)
//            : SwissGridApproximation.convertWGS84ToLV03(latLon)
//        let swissGridFormat = getSwissGridFormat()
//
//        firstIcon.image = getLatitudeIcon(lat: lat)
//        secondIcon.image = getLongitudeIcon(lon: lon)
//
//        firstCoordinate.text = swissGridFormat.string(from: NSNumber(value: swissGrid[0])) ?? ""
//        secondCoordinate.text = swissGridFormat.string(from: NSNumber(value: swissGrid[1])) ?? ""
//    }
//
//    private func getSwissGridFormat() -> NumberFormatter {
//        let swissGridFormat = NumberFormatter()
//        swissGridFormat.locale = Locale(identifier: "en_US")
//        swissGridFormat.numberStyle = .decimal
//        swissGridFormat.groupingSeparator = " "
//        swissGridFormat.maximumFractionDigits = 2
//        return swissGridFormat
//    }

    private func setupForNonStandardFormat() {
        firstIcon.isHidden = false
        divider.isHidden = true
        secondContainer.isHidden = true
        firstIcon.image = getCoordinateIcon()
        coloredUnit = false
    }

    private func showStandardCoordinates(lat: Double, lon: Double, format: Int) {
        self.firstIcon.isHidden = false
        self.divider.isHidden = false
        self.secondContainer.isHidden = false
        coloredUnit = true

        firstIcon.image = getCoordinateIcon()

        var latitude = OALocationConvert.convertLatitude(lat, outputType: format, addCardinalDirection: true)
        var longitude = OALocationConvert.convertLongitude(lon, outputType: format, addCardinalDirection: true)

        if (latitude == nil) {
            latitude = ""
        }
        if (longitude == nil) {
            longitude = ""
        }

        let coordColor: UIColor = isNightMode() ? .white : .black
        let unitColor = UIColor(rgb: 0x7D738C)

            let attributedLat = NSMutableAttributedString(string: latitude!)
        if (latitude!.length > 2) {
            attributedLat.addAttribute(.foregroundColor, value: coordColor, range: NSRange(location: 0, length: latitude!.length - 2))
            attributedLat.addAttribute(.foregroundColor, value: unitColor, range: NSRange(location: latitude!.length - 1, length: 1))
        }

        let attributedLon = NSMutableAttributedString(string: longitude!)
        if (longitude!.length > 2) {
            attributedLon.addAttribute(.foregroundColor, value: coordColor, range: NSRange(location: 0, length: longitude!.length - 2))
            attributedLon.addAttribute(.foregroundColor, value: unitColor, range: NSRange(location: longitude!.length - 1, length: 1))
        }

        firstCoordinate.attributedText = attributedLat
        secondCoordinate.attributedText = attributedLon
    }

    func getCoordinateIcon() -> UIImage? {
        return nil // override it
    }

    func updateVisibility(visible: Bool) -> Bool {
        if (visible == self.isHidden)
        {
            self.isHidden = !visible;
            if self.delegate != nil {
                self.delegate!.widgetVisibilityChanged(self, visible: visible)
            }
            return true
        }
        return false
    }

    override func updateColors(_ textState: OATextState) {
        super.updateColors(textState)

        backgroundColor = isNightMode() ? colorFromRGB(Int(nav_bar_night)) : .white

        divider.backgroundColor = isNightMode() ? colorFromRGB(Int(divider_color_dark)) : colorFromRGB(Int(divider_color_light))

        let textColor: UIColor = isNightMode() ? .white : .black
        firstCoordinate.textColor = textColor
        secondCoordinate.textColor = textColor

        let typefaceStyle: UIFont.Weight = textState.textBold ? .bold : .semibold
        firstCoordinate.font = UIFont.scaledSystemFont(ofSize: firstCoordinate.font.pointSize, weight: typefaceStyle)
        secondCoordinate.font = UIFont.scaledSystemFont(ofSize: secondCoordinate.font.pointSize, weight: typefaceStyle)

        let lastLocation = lastLocation
        if (coloredUnit && lastLocation != nil) {
            showFormattedCoordinates(lat: lastLocation!.coordinate.latitude, lon: lastLocation!.coordinate.longitude)
        }
    }

    override func adjustSize() {
        var selfFrame: CGRect = frame
        selfFrame.size.width = OAUtilities.calculateScreenWidth()
        selfFrame.size.height = Self.widgetHeight
        frame = selfFrame
    }
}
