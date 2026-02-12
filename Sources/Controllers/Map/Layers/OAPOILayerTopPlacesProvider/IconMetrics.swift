//
//  IconMetrics.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 12.02.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

struct IconMetrics {
    let textScale: CGFloat
    
    // MARK: - Design contract (textScale = 1)
    private let baseImageArea: CGFloat = 50   // full image area, includes border
    private let baseBorder: CGFloat    = 4    // drawn inside imageArea
    private let baseShadow: CGFloat    = 66   // canvas with shadow
    
    // MARK: - Scaled values
    var imageArea: CGFloat {
        baseImageArea * textScale
    }
    
    var border: CGFloat {
        baseBorder * textScale
    }
    
    var shadow: CGFloat {
        baseShadow * textScale
    }
    
    var imageTargetSize: CGSize {
        CGSize(width: imageArea, height: imageArea)
    }
    
    var placeholderTargetSize: CGSize {
        CGSize(width: imageArea, height: imageArea)
    }
    
    // MARK: - Geometry inside shadow canvas
    
    /// Top-left origin of imageArea inside shadow canvas
    /// Centers imageArea (50x50) inside shadow canvas (66x66)
    var imageOriginInShadow: CGPoint {
        CGPoint(
            x: (shadow - imageArea) / 2,
            y: (shadow - imageArea) / 2
        )
    }
    
    /// Rect of visible icon (image + borders) inside shadow canvas
    var imageRectInShadow: CGRect {
        CGRect(
            origin: imageOriginInShadow,
            size: imageTargetSize
        )
    }
}
