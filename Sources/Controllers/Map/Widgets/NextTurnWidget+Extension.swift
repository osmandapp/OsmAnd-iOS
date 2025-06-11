//
//  NextTurnWidget+Extension.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 11.06.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

extension OANextTurnWidget {
    @objc var distanceFont: CGFloat {
        switch self.widgetSizeStyle {
        case .small: 22
        case .medium: 30
        case .large: 37
        @unknown default: fatalError("Unknown EOAWidgetSizeStyle enum value")
        }
    }
    
    @objc var exitFont: CGFloat {
        switch self.widgetSizeStyle {
        case .small, .medium: 18
        case .large: 22
        @unknown default: fatalError("Unknown EOAWidgetSizeStyle enum value")
        }
    }
    
    @objc var streetFont: CGFloat {
        switch self.widgetSizeStyle {
        case .small: 22
        case .medium: 24
        case .large: 30
        @unknown default: fatalError("Unknown EOAWidgetSizeStyle enum value")
        }
    }
    
    @objc var arrowSize: CGFloat {
        switch self.widgetSizeStyle {
        case .small:  36
        case .medium: 48
        case .large: 72
        @unknown default: fatalError("Unknown EOAWidgetSizeStyle enum value")
        }
    }
    
    @objc var halfScreenArrowSize: CGFloat {
        switch self.widgetSizeStyle {
        case .small, .medium: 36
        case .large: 48
        @unknown default: fatalError("Unknown EOAWidgetSizeStyle enum value")
        }
    }
    
    @objc var firstLineHeight: CGFloat {
        switch self.widgetSizeStyle {
        case .small, .medium: 36
        case .large: 45
        @unknown default: fatalError("Unknown EOAWidgetSizeStyle enum value")
        }
    }
    
    @objc var secondLineHeight: CGFloat {
        switch self.widgetSizeStyle {
        case .small, .medium: 32
        case .large: 36
        @unknown default: fatalError("Unknown EOAWidgetSizeStyle enum value")
        }
    }
    
    @objc var exitLabelViewHeight: CGFloat {
        switch self.widgetSizeStyle {
        case .small, .medium: 30
        case .large: 36
        @unknown default: fatalError("Unknown EOAWidgetSizeStyle enum value")
        }
    }

    @objc var halfScreenExitLabelViewHeight: CGFloat {
        switch self.widgetSizeStyle {
        case .small, .large: 30
        case .medium: 26
        @unknown default: fatalError("Unknown EOAWidgetSizeStyle enum value")
        }
    }
}
