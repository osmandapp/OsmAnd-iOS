//
//  GPXInterpolator.swift
//  OsmAnd Maps
//
//  Created by Alexey K on 09.08.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

class GPXInterpolator {

    private let pointsCount: Int
    private let totalLength: Double
    private var step: Double

    private var calculatedX: [Double] = []
    private var calculatedY: [Double] = []
    private var calculatedPointsCount: Int = 0
    private var minY: Double = Double.greatestFiniteMagnitude
    private var maxY: Double = -Double.greatestFiniteMagnitude

    private let getX: (Int) -> Double
    private let getY: (Int) -> Double

    init(pointsCount: Int, totalLength: Double, step: Double, getX: @escaping (Int) -> Double, getY: @escaping (Int) -> Double) {
        self.pointsCount = pointsCount
        self.totalLength = totalLength
        self.step = step
        self.getX = getX
        self.getY = getY
    }

    func getPointsCount() -> Int {
        return pointsCount
    }

    func getTotalLength() -> Double {
        return totalLength
    }

    func getStep() -> Double {
        return step
    }

    func getCalculatedX() -> [Double] {
        return calculatedX
    }

    func getCalculatedY() -> [Double] {
        return calculatedY
    }

    func getCalculatedPointsCount() -> Int {
        return calculatedPointsCount
    }

    func getMinY() -> Double {
        return minY
    }

    func getMaxY() -> Double {
        return maxY
    }

    func interpolate() {
        calculatedPointsCount = Int(totalLength / step) + 1
        calculatedX = Array(repeating: 0.0, count: calculatedPointsCount)
        calculatedY = Array(repeating: 0.0, count: calculatedPointsCount)
        let lastIndex = pointsCount - 1
        var nextW = 0

        for k in 0..<calculatedX.count {
            if k > 0 {
                calculatedX[k] = calculatedX[k - 1] + step
            } else {
                calculatedY[k] = getY(0)
                takeMinMax(value: calculatedY[k])
                continue
            }

            while nextW < lastIndex && calculatedX[k] > getX(nextW) {
                nextW += 1
            }

            let px = nextW == 0 ? 0 : getX(nextW - 1)
            let py = nextW == 0 ? getY(0) : getY(nextW - 1)

            calculatedY[k] = py + (getY(nextW) - py) / (getX(nextW) - px) * (calculatedX[k] - px)
            takeMinMax(value: calculatedY[k])
        }
    }

    private func takeMinMax(value: Double) {
        if minY > value {
            minY = value
        }
        if maxY < value {
            maxY = value
        }
    }
}
