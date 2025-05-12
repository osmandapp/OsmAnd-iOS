//
//  VehicleMetricsPlugin.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 09.05.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

final class VehicleMetricsPlugin: OAPlugin {
    
//    static let shared = VehicleMetricsPlugin()
//    
//    private override init() {
//    }
    
    override func getId() -> String? {
        "net.osmand.maps.inapp.addon.vehicle_metrics"
    }
    
    override func getDescription() -> String {
        localizedString("obd_plugin_description")
    }
    
    override func setEnabled(_ enabled: Bool) {
        super.setEnabled(enabled)
        // TODO:
    }
    
    override func disable() {
        super.disable()
        // TODO:
    }
    
    
//
//    override func getName(): String {
//        return app.getString(R.string.obd_plugin_name)
//    }
//
//    override fun getDescription(linksEnabled: Boolean): CharSequence {
//        return app.getString(R.string.obd_plugin_description)
//    }
//
//    override fun getLogoResourceId(): Int {
//        return R.drawable.ic_action_car_info
//    }
    
}
