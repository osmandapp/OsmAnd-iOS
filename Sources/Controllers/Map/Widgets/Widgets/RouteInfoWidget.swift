//
//  RouteInfoWidget.swift
//  OsmAnd
//
//  Created by Vladyslav Lysenko on 07.05.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

final class RouteInfoWidget: OABaseWidgetView {
    private var customId: String?
    
    convenience init(customId: String?) {
        self.init(frame: .zero)
        self.customId = customId
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
        self.widgetType = .routeInfo
    }
}
