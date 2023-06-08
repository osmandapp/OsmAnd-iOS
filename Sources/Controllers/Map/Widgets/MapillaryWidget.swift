//
//  MapillaryWidget.swift
//  OsmAnd Maps
//
//  Created by Paul on 07.06.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

@objc(OAMapillaryWidget)
@objcMembers
class MapillaryWidget: OATextInfoWidget {
    
    convenience init() {
        self.init()
        self.widgetType = .mapillary
        setText(localizedString("mapillary"), subtext: "")
        onClickFunction = { _ in
            OAMapillaryPlugin.installOrOpenMapillary()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
