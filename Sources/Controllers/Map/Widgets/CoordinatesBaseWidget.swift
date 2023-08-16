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

    @IBOutlet var divider: UIView!
    @IBOutlet var secondContainer: UIStackView!

    @IBOutlet var firstCoordinate: UILabel!
    @IBOutlet var secondCoordinate: UILabel!

    @IBOutlet var firstIcon: UIImageView!
    @IBOutlet var secondIcon: UIImageView!

    var lastLocation: CLLocation?

    override init(type: WidgetType) {
        super.init(frame: CGRect(x: 0, y: 0, width: 414, height: 50))
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

        var coordinates = firstCoordinate.text ?? ""
        if secondContainer.isHidden == false {
            coordinates += ", \(secondCoordinate.text ?? "")"
        }

        let pasteboard: UIPasteboard  = UIPasteboard.general
        pasteboard.string = coordinates

        OAUtilities.showToast(String(format: localizedString("ltr_or_rtl_combine_via_colon"),
                                     arguments: [localizedString("copied_to_clipboard"), coordinates]),
                              details: nil,
                              duration: 4,
                              in: OARootViewController.instance().view)
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
        firstIcon.image = getUtmIcon()
    }

    private func showStandardCoordinates(lat: Double, lon: Double, format: Int) {
        self.firstIcon.isHidden = false
        self.divider.isHidden = false
        self.secondContainer.isHidden = false

        let latitude = OALocationConvert.convertLatitude(lat, outputType: format, addCardinalDirection: true)
        let longitude = OALocationConvert.convertLongitude(lon, outputType: format, addCardinalDirection: true)

        firstIcon.image = getLatitudeIcon(lat: lat)
        secondIcon.image = getLongitudeIcon(lon: lon)

        firstCoordinate.text = latitude
        secondCoordinate.text = longitude
    }

    func getUtmIcon() -> UIImage {
        let utmIconId = OAAppSettings.sharedManager().nightMode
            ? "widget_coordinates_utm_night"
            : "widget_coordinates_utm_day"
        return UIImage.init(named: utmIconId)!
    }

    func getLatitudeIcon(lat: Double) -> UIImage {
        let latDayIconId = lat >= 0
            ? "widget_coordinates_latitude_north_day"
            : "widget_coordinates_latitude_south_day"
        let latNightIconId = lat >= 0
            ? "widget_coordinates_latitude_north_night"
            : "widget_coordinates_latitude_south_night"
        let latIconId = OAAppSettings.sharedManager().nightMode ? latNightIconId : latDayIconId
        return UIImage.init(named: latIconId)!
    }

    func getLongitudeIcon(lon: Double) -> UIImage {
        let lonDayIconId = lon >= 0
            ? "widget_coordinates_longitude_east_day"
            : "widget_coordinates_longitude_west_day"
        let lonNightIconId = lon >= 0
            ? "widget_coordinates_longitude_east_night"
            : "widget_coordinates_longitude_west_night"
        let lonIconId = OAAppSettings.sharedManager().nightMode ? lonNightIconId : lonDayIconId
        return UIImage.init(named: lonIconId)!
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

        let typefaceStyle: UIFont.Weight = textState.textBold ? .bold : .regular
        firstCoordinate.font = UIFont.systemFont(ofSize: UIFont.labelFontSize, weight: typefaceStyle)
        secondCoordinate.font = UIFont.systemFont(ofSize: UIFont.labelFontSize, weight: typefaceStyle)
    }

    override func adjustSize() {
        
        var selfFrame: CGRect = frame
        selfFrame.size.width = OAUtilities.calculateScreenWidth()
        selfFrame.size.height = 52
        frame = selfFrame
    }

}
