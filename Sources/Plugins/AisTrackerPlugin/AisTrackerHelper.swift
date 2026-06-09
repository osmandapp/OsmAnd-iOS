import CoreLocation
import Foundation

@objcMembers
final class AisCpa: NSObject {
    private(set) var tcpa = AisObjectConstants.invalidTcpa
    private(set) var cpaDistance = AisObjectConstants.invalidCpa
    private(set) var cpaPosition1: CLLocation?
    private(set) var cpaPosition2: CLLocation?
    private(set) var crossingTime1 = 0.0
    private(set) var crossingTime2 = 0.0
    private(set) var valid = false

    func reset() {
        tcpa = AisObjectConstants.invalidTcpa
        cpaDistance = AisObjectConstants.invalidCpa
        cpaPosition1 = nil
        cpaPosition2 = nil
        crossingTime1 = 0
        crossingTime2 = 0
        valid = false
    }

    fileprivate func update(tcpa: Double,
                            cpaDistance: Float,
                            cpaPosition1: CLLocation?,
                            cpaPosition2: CLLocation?,
                            crossingTimes: (Double, Double)?) {
        self.tcpa = tcpa
        self.cpaDistance = cpaDistance
        self.cpaPosition1 = cpaPosition1
        self.cpaPosition2 = cpaPosition2
        if let crossingTimes {
            crossingTime1 = crossingTimes.0
            crossingTime2 = crossingTimes.1
        }
        valid = cpaDistance != AisObjectConstants.invalidCpa
    }
}

enum AisTrackerHelper {
    private struct Vector {
        let x: Double
        let y: Double

        func sub(_ other: Vector) -> Vector {
            Vector(x: x - other.x, y: y - other.y)
        }

        func dot(_ other: Vector) -> Double {
            x * other.x + y * other.y
        }
    }

    private static var lastCorrectionUpdate = Date.distantPast
    private static var correctionFactor = 1.0
    private static let maxCorrectionUpdateAge: TimeInterval = 60 * 60

    static func knotsToMeterPerSecond(_ speed: Float) -> Float {
        speed * 1852 / 3600
    }

    static func meterPerSecondToKnots(_ speed: Float) -> Float {
        speed * 3600 / 1852
    }

    static func meterToMiles(_ distance: Float) -> Float {
        distance / 1852
    }

    static func getTcpa(_ ownLocation: CLLocation, _ otherLocation: CLLocation) -> Double {
        getTcpa(ownLocation, otherLocation, lonCorrection: getLonCorrection(ownLocation))
    }

    static func getCpa1(_ ownLocation: CLLocation, _ otherLocation: CLLocation) -> CLLocation? {
        getCpa(ownLocation, otherLocation, useFirstAsReference: true)
    }

    static func getCpa2(_ ownLocation: CLLocation, _ otherLocation: CLLocation) -> CLLocation? {
        getCpa(ownLocation, otherLocation, useFirstAsReference: false)
    }

    static func getCpaDistance(_ ownLocation: CLLocation, _ otherLocation: CLLocation) -> Float {
        guard let cpa1 = getCpa1(ownLocation, otherLocation),
              let cpa2 = getCpa2(ownLocation, otherLocation) else {
            return AisObjectConstants.invalidCpa
        }
        return meterToMiles(Float(cpa1.distance(from: cpa2)))
    }

    static func getCpa(_ ownLocation: CLLocation, _ otherLocation: CLLocation, result: AisCpa) {
        result.reset()
        guard !missingSpeedOrCourse(ownLocation, otherLocation) else { return }
        let tcpa = getTcpa(ownLocation, otherLocation)
        guard tcpa != AisObjectConstants.invalidTcpa else { return }
        let cpa1 = newPosition(from: ownLocation, ageHours: tcpa)
        let cpa2 = newPosition(from: otherLocation, ageHours: tcpa)
        let cpaDistance: Float
        if let cpa1, let cpa2 {
            cpaDistance = meterToMiles(Float(cpa1.distance(from: cpa2)))
        } else {
            cpaDistance = AisObjectConstants.invalidCpa
        }
        result.update(tcpa: tcpa,
                      cpaDistance: cpaDistance,
                      cpaPosition1: cpa1,
                      cpaPosition2: cpa2,
                      crossingTimes: getCrossingTimes(ownLocation, otherLocation))
    }

    static func newPosition(from location: CLLocation?, ageHours: Double) -> CLLocation? {
        guard let location, location.course >= 0, location.speed >= 0 else { return nil }
        let distance = location.speed * ageHours * 3600.0
        let bearing = bearingInRad(location.course)
        let angularDistance = distance / 6_371_000.0
        let lat1 = location.coordinate.latitude * .pi / 180.0
        let lon1 = location.coordinate.longitude * .pi / 180.0
        let lat2 = asin(sin(lat1) * cos(angularDistance) + cos(lat1) * sin(angularDistance) * cos(bearing))
        let lon2 = lon1 + atan2(sin(bearing) * sin(angularDistance) * cos(lat1),
                                cos(angularDistance) - sin(lat1) * sin(lat2))
        return CLLocation(coordinate: CLLocationCoordinate2D(latitude: lat2 * 180.0 / .pi,
                                                             longitude: lon2 * 180.0 / .pi),
                          altitude: location.altitude,
                          horizontalAccuracy: location.horizontalAccuracy,
                          verticalAccuracy: location.verticalAccuracy,
                          course: location.course,
                          speed: location.speed,
                          timestamp: Date())
    }

    private static func getCpa(_ ownLocation: CLLocation,
                               _ otherLocation: CLLocation,
                               useFirstAsReference: Bool) -> CLLocation? {
        guard !missingSpeedOrCourse(ownLocation, otherLocation) else { return nil }
        let tcpa = getTcpa(ownLocation, otherLocation)
        guard tcpa != AisObjectConstants.invalidTcpa else { return nil }
        return newPosition(from: useFirstAsReference ? ownLocation : otherLocation, ageHours: tcpa)
    }

    private static func getTcpa(_ x: CLLocation, _ y: CLLocation, lonCorrection: Double) -> Double {
        guard !missingSpeedOrCourse(x, y) else { return AisObjectConstants.invalidTcpa }
        return getTcpa(locationToVector(x),
                       locationToVector(y),
                       courseToVector(cog: x.course, sog: Double(meterPerSecondToKnots(Float(x.speed)))),
                       courseToVector(cog: y.course, sog: Double(meterPerSecondToKnots(Float(y.speed)))),
                       lonCorrection: lonCorrection)
    }

    private static func getTcpa(_ x: Vector,
                                _ y: Vector,
                                _ vx: Vector,
                                _ vy: Vector,
                                lonCorrection: Double) -> Double {
        let dx = y.sub(x)
        let dv = vy.sub(vx)
        let divisor = dv.dot(dv)
        guard abs(divisor) >= 1.0E-10, lonCorrection >= 1.0E-10 else {
            return AisObjectConstants.invalidTcpa
        }
        return -(((dx.x * dv.x / lonCorrection) + (dx.y * dv.y)) / divisor)
    }

    private static func getCrossingTimes(_ x: CLLocation, _ y: CLLocation) -> (Double, Double)? {
        let lonCorrection = getLonCorrection(x)
        let vX = locationToVector(x, lonCorrection: lonCorrection)
        let vY = locationToVector(y, lonCorrection: lonCorrection)
        let vVX = courseToVector(cog: x.course, sog: Double(meterPerSecondToKnots(Float(x.speed))))
        let vVY = courseToVector(cog: y.course, sog: Double(meterPerSecondToKnots(Float(y.speed))))
        let vDXY = vX.sub(vY)
        let divisor = vVX.x * vVY.y - vVX.y * vVY.x
        guard abs(divisor) >= 1.0E-10, lonCorrection >= 1.0E-10 else { return nil }
        return ((vVY.x * vDXY.y - vVY.y * vDXY.x) / divisor,
                (vVX.x * vDXY.y - vVX.y * vDXY.x) / divisor)
    }

    private static func bearingInRad(_ bearingInDegrees: Double) -> Double {
        var result = bearingInDegrees * 2 * .pi / 360.0
        while result >= .pi { result -= 2 * .pi }
        return result
    }

    private static func calculateLonCorrection(_ location: CLLocation?) -> Double {
        guard let location else { return 1.0 }
        let east = CLLocation(coordinate: location.coordinate,
                              altitude: location.altitude,
                              horizontalAccuracy: location.horizontalAccuracy,
                              verticalAccuracy: location.verticalAccuracy,
                              course: 90,
                              speed: CLLocationSpeed(knotsToMeterPerSecond(1)),
                              timestamp: location.timestamp)
        guard let afterHour = newPosition(from: east, ageHours: 1.0) else { return 1.0 }
        return (afterHour.coordinate.longitude - east.coordinate.longitude) * 60.0
    }

    private static func getLonCorrection(_ location: CLLocation?) -> Double {
        if Date().timeIntervalSince(lastCorrectionUpdate) > maxCorrectionUpdateAge {
            correctionFactor = calculateLonCorrection(location)
            lastCorrectionUpdate = Date()
        }
        return correctionFactor
    }

    private static func courseToVector(cog: Double, sog: Double) -> Vector {
        var alpha = 450.0 - cog
        while alpha < 0 { alpha += 360.0 }
        while alpha >= 360.0 { alpha -= 360.0 }
        alpha = alpha * .pi / 180.0
        return Vector(x: cos(alpha) * sog, y: sin(alpha) * sog)
    }

    private static func locationToVector(_ location: CLLocation) -> Vector {
        Vector(x: location.coordinate.longitude * 60.0, y: location.coordinate.latitude * 60.0)
    }

    private static func locationToVector(_ location: CLLocation, lonCorrection: Double) -> Vector {
        Vector(x: location.coordinate.longitude * 60.0 / lonCorrection,
               y: location.coordinate.latitude * 60.0)
    }

    private static func missingSpeedOrCourse(_ x: CLLocation, _ y: CLLocation) -> Bool {
        x.course < 0 || y.course < 0 || x.speed < 0 || y.speed < 0
    }
}
