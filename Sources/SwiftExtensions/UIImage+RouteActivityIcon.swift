//
//  UIImage+RouteActivityIcon.swift
//  OsmAnd Maps
//

import UIKit

private enum RouteActivityIconStyle {
    static let padding: CGFloat = 3
}

extension UIImage {

    @objc static func routeActivityIcon(_ iconName: String?, fallback: UIImage?) -> UIImage? {
        guard let iconName, let mapIcon = mapSvgImageNamed("mx_\(iconName)") else { return fallback }
        return mapIcon.withPadding(RouteActivityIconStyle.padding)
    }

    private func withPadding(_ padding: CGFloat) -> UIImage {
        guard padding > 0 else { return self }
        let paddedSize = CGSize(width: size.width + padding * 2, height: size.height + padding * 2)
        let renderer = UIGraphicsImageRenderer(size: paddedSize)
        let padded = renderer.image { _ in
            draw(in: CGRect(x: padding, y: padding, width: size.width, height: size.height))
        }
        return padded.withRenderingMode(renderingMode)
    }
}
