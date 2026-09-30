// Copyright © 2026 OsmAnd. All rights reserved.

import SwiftUI

struct ActivityTurnShape: Shape {
    // OATurnPathHelper builds every maneuver in a 72 × 72 coordinate space.
    static let coordinateSize: CGFloat = 72

    let turnPath: Path

    func path(in rect: CGRect) -> Path {
        let scale = min(rect.width, rect.height) / Self.coordinateSize
        let offsetX = rect.midX - Self.coordinateSize * scale / 2
        let offsetY = rect.midY - Self.coordinateSize * scale / 2
        let transform = CGAffineTransform(translationX: offsetX, y: offsetY).scaledBy(x: scale, y: scale)
        return turnPath.applying(transform)
    }
}
