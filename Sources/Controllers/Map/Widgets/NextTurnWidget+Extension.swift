//
//  NextTurnWidget+Extension.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 11.06.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

extension OANextTurnWidget {
    @objc var distanceFont: CGFloat {
        sizeValue(small: 22, medium: 30, large: 37)
    }
    
    @objc var exitFont: CGFloat {
        sizeValue(small: 18, medium: 18, large: 22)
    }
    
    @objc var streetFont: CGFloat {
        sizeValue(small: 22, medium: 24, large: 30)
    }
    
    @objc var arrowSize: CGFloat {
        sizeValue(small: 36, medium: 48, large: 72)
    }
    
    @objc var halfScreenArrowSize: CGFloat {
        sizeValue(small: 36, medium: 36, large: 48)
    }
    
    @objc var firstLineHeight: CGFloat {
        sizeValue(small: 36, medium: 36, large: 45)
    }
    
    @objc var secondLineHeight: CGFloat {
        sizeValue(small: 32, medium: 32, large: 36)
    }
    
    @objc var exitLabelViewHeight: CGFloat {
        sizeValue(small: 30, medium: 30, large: 36)
    }

    @objc var halfScreenExitLabelViewHeight: CGFloat {
        sizeValue(small: 30, medium: 30, large: 26)
    }
    
    private func sizeValue(small: CGFloat,
                           medium: CGFloat,
                           large: CGFloat) -> CGFloat {
        switch widgetSizeStyle {
        case .small: small
        case .medium: medium
        case .large: large
        @unknown default:
            fatalError("Unknown EOAWidgetSizeStyle enum value: \(widgetSizeStyle)")
        }
    }
}
