//
//  POITopPlaceImageDecorator.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 12.02.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

@objcMembers
final class POITopPlaceImageDecorator: NSObject {
    
    static func selectedImage(for image: UIImage) -> UIImage {
        let metrics = IconMetrics(textScale: OAAppSettings.sharedManager().textSize.get())
        return imageWithSelection(image, metrics: metrics)
    }
    
    static private func imageWithSelection(_ image: UIImage,
                                           metrics: IconMetrics) -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.opaque = false
        format.scale = image.scale
        
        return UIGraphicsImageRenderer(size: image.size, format: format).image { context in
            
            let ctx = context.cgContext
            
            image.draw(at: .zero)
            ctx.setShadow(offset: .zero, blur: 0, color: nil)
            ctx.setStrokeColor(UIColor.popularPlaceSelectedStroke.currentMapThemeColor.cgColor)
            
            let purpleLineWidth = 2 * metrics.textScale
            ctx.setLineWidth(purpleLineWidth)
            ctx.strokeEllipse(in: metrics.imageRectInShadow)
        }
    }
}
