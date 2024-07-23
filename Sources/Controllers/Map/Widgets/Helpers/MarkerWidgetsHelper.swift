//
//  MarkerWidgetsHelper.swift
//  OsmAnd Maps
//
//  Created by Paul on 11.05.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation
import CoreLocation

@objc(OAMarkerWidgetsHelper)
@objcMembers
class MarkerWidgetsHelper: NSObject {
    private let settings = OAAppSettings.sharedManager()!
    private let widgetRegistry = OARootViewController.instance().mapPanel.mapWidgetRegistry
    
    private var barWidgets: Set<OABaseWidgetView> = []
    private var sideFirstWidgets: Set<OABaseWidgetView> = []
    private var sideSecondWidgets: Set<OABaseWidgetView> = []
    
    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(onWidgetRegistered), name: NSNotification.Name(kWidgetRegisteredNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onWidgetVisibilityChanged), name: NSNotification.Name(kWidgetVisibilityChangedMotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onWidgetsCleared), name: NSNotification.Name(kWidgetsCleared), object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func setCustomLatLon(_ latLon: CLLocation?) {
        setCustomLatLon(barWidgets, latLon)
        setCustomLatLon(sideFirstWidgets, latLon)
        setCustomLatLon(sideSecondWidgets, latLon)
    }
    
    private func setCustomLatLon(_ widgets: Set<OABaseWidgetView>, _ latLon: CLLocation?) {
        for widget in widgets {
            if let listener = widget as? CustomLatLonListener {
                listener.setCustomLatLon(latLon)
            }
        }
    }
    
    func getMapMarkersBarWidgetHeight() -> CGFloat {
        var height: CGFloat = 0
        for widget in barWidgets {
            height += widget.frame.size.height
        }
        return height
    }
    
    func isMapMarkersBarWidgetVisible() -> Bool {
        let visible = isBarWidgetsVisible()
        return visible /*&& mapActivity.findViewById(R.id.MapHudButtonsOverlay).getVisibility() == View.VISIBLE*/
    }
    
    private func isBarWidgetsVisible() -> Bool {
        for widget in barWidgets {
            if !widget.isHidden {
                return true
            }
        }
        return false
    }
    
    // MARK: Callbacks
    
    func onWidgetRegistered(_ widgetInfo: MapWidgetInfo) {
        let widgetType = widgetInfo.getWidgetType()
        if isMarkerWidget(widgetType) && widgetInfo.isEnabledForAppMode(settings.applicationMode.get()) {
            addWidget(widgetInfo, widgetType)
        }
    }
    
    func onWidgetVisibilityChanged(_ widgetInfo: MapWidgetInfo) {
        let widgetType = widgetInfo.getWidgetType()
        if isMarkerWidget(widgetType) {
            if widgetInfo.isEnabledForAppMode(settings.applicationMode.get()) {
                addWidget(widgetInfo, widgetType)
            } else {
                removeWidget(widgetInfo, widgetType)
            }
        }
    }
    
    func onWidgetsCleared() {
        clearWidgets()
    }
    
    private func isMarkerWidget(_ widgetType: WidgetType?) -> Bool {
        return widgetType == .markersTopBar || widgetType == .sideMarker1 || widgetType == .sideMarker2
    }
    
    func clearWidgets() {
        barWidgets.removeAll()
        sideFirstWidgets.removeAll()
        sideSecondWidgets.removeAll()
    }
    
    private func addWidget(_ widgetInfo: MapWidgetInfo, _ widgetType: WidgetType?) {
        if widgetType == .markersTopBar {
            barWidgets.insert(widgetInfo.widget)
        } else if widgetType == .sideMarker1 {
            sideFirstWidgets.insert(widgetInfo.widget)
        } else if widgetType == .sideMarker2 {
            sideSecondWidgets.insert(widgetInfo.widget)
        }
    }
    
    private func removeWidget(_ widgetInfo: MapWidgetInfo, _ widgetType: WidgetType?) {
        if widgetType == .markersTopBar {
            barWidgets.remove(widgetInfo.widget)
        } else if widgetType == .sideMarker1 {
            sideFirstWidgets.remove(widgetInfo.widget)
        } else if widgetType == .sideMarker2 {
            sideSecondWidgets.remove(widgetInfo.widget)
        }
    }
    
    static func showMarkerOnMap(_ index: Int) {
        let markersHelper = OADestinationsHelper.instance()!
        if index < markersHelper.sortedDestinationsWithoutParking().count {
            let marker = markersHelper.sortedDestinationsWithoutParking()[index]
            let location = CLLocation(latitude: marker.latitude, longitude: marker.longitude)
            let mapViewHelper = OAMapViewHelper.sharedInstance()
            let fZoom: CGFloat = max(mapViewHelper.getMapZoom(), 15)
            mapViewHelper.go(to: location, zoom: fZoom, animated: true)
        }
    }
}

@objc(OACustomLatLonListener)
protocol CustomLatLonListener {
    func setCustomLatLon(_ customLatLon: CLLocation?)
}

