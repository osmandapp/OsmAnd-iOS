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
class MapillaryWidget: OASimpleWidget {
    
    init() {
        super.init(type: .mapillary)
        setText(localizedString("mapillary"), subtext: "")
        setIcon("widget_mapillary")
        onClickFunction = { _ in
            OAMapillaryPlugin.installOrOpenMapillary()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
