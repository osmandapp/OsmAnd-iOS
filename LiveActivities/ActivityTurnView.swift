// Copyright © 2026 OsmAnd. All rights reserved.

import OsmAndShared
import SwiftUI

struct ActivityTurnView: View {
    private enum Constants {
        static let aspectRatio: CGFloat = 1
        static let noRoundaboutExit = 0
        static let exitNumberFontSize: CGFloat = 20
        static let exitNumberWidth: CGFloat = 20
        static let exitNumberMinimumScaleFactor: CGFloat = 0.5
        static let exitNumberLineLimit = 1
    }

    private let arrowPath: Path
    private let roundaboutPath: Path
    private let roundaboutCenter: CGPoint
    private let exitNumber: Int

    var body: some View {
        ZStack {
            roundaboutView
            arrowView
            if exitNumber > Constants.noRoundaboutExit {
                exitNumberView
            }
        }
        .aspectRatio(Constants.aspectRatio, contentMode: .fit)
    }

    private var roundaboutView: some View {
        ActivityTurnShape(turnPath: roundaboutPath).fill(Color.navArrowCircle)
    }

    private var arrowView: some View {
        ActivityTurnShape(turnPath: arrowPath).fill()
    }

    private var exitNumberView: some View {
        GeometryReader { geometry in
            let scale = geometry.size.width / ActivityTurnShape.coordinateSize
            exitNumberText
                .font(.system(size: Constants.exitNumberFontSize * scale, weight: .bold))
                .frame(width: Constants.exitNumberWidth * scale)
                .position(x: roundaboutCenter.x * scale, y: roundaboutCenter.y * scale)
        }
    }

    private var exitNumberText: some View {
        Text("\(exitNumber)")
            .foregroundStyle(Color.widgetValue)
            .lineLimit(Constants.exitNumberLineLimit)
            .minimumScaleFactor(Constants.exitNumberMinimumScaleFactor)
    }

    init(turnType: TurnType) {
        let paths = turnType.makePaths()
        arrowPath = Path(paths.arrow)
        roundaboutPath = Path(paths.roundabout)
        roundaboutCenter = paths.roundaboutCenter
        exitNumber = turnType.isRoundAbout() ? Int(turnType.exitOut) : Constants.noRoundaboutExit
    }
}
