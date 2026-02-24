//
//  CircularShadowProcessor.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 12.02.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import Kingfisher

// Processor that adds a circular shadow to an image
struct CircularShadowProcessor: ImageProcessor {
    // Required by ImageProcessor
    let identifier: String
    
    // Parameters
    let shadowOffset: CGSize
    let shadowBlur: CGFloat
    let shadowColor: UIColor
    let shadowPadding: CGFloat
    
    init(shadowOffset: CGSize,
         shadowBlur: CGFloat,
         shadowColor: UIColor,
         shadowPadding: CGFloat) {
        self.shadowOffset = shadowOffset
        self.shadowBlur = shadowBlur
        self.shadowColor = shadowColor
        self.shadowPadding = shadowPadding
        self.identifier =
        "com.osmand.CircularShadowProcessor." +
        "\(shadowOffset.width)x\(shadowOffset.height)." +
        "\(shadowBlur)." +
        "\(shadowPadding)." +
        "\(shadowColor.hashValue)"
    }
    
    func process(item: ImageProcessItem, options: KingfisherParsedOptionsInfo) -> KFCrossPlatformImage? {
        switch item {
        case .image(let image):
            let canvasSize = CGSize(
                width: image.size.width + 2 * shadowPadding,
                height: image.size.height + 2 * shadowPadding
            )
            
            let format = UIGraphicsImageRendererFormat.default()
            format.opaque = false
            format.scale = image.scale
            
            let renderer = UIGraphicsImageRenderer(size: canvasSize, format: format)
            return renderer.image { ctx in
                let cgContext = ctx.cgContext
                
                let imageOrigin = CGPoint(x: shadowPadding, y: shadowPadding)
                let imageRect = CGRect(origin: imageOrigin, size: image.size)
                
                cgContext.addEllipse(in: imageRect)
                cgContext.setShadow(
                    offset: shadowOffset,
                    blur: shadowBlur,
                    color: shadowColor.cgColor
                )
                cgContext.setFillColor(UIColor.white.cgColor)
                cgContext.fillPath()
                
                image.draw(in: imageRect)
            }
        case .data:
            return (DefaultImageProcessor.default |> self).process(item: item, options: options)
        }
    }
}
