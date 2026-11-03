import Foundation

enum PlanRouteHistoryFixture {
    private struct Coordinate {
        let latitude: Double
        let longitude: Double

        var attributes: String {
            String(format: "lat=\"%.7f\" lon=\"%.7f\"", locale: Locale(identifier: "en_US_POSIX"), latitude, longitude)
        }
    }

    static func gpx(withGeometry: Bool) -> String {
        let points = (0..<8).map { index in
            Coordinate(latitude: 52.230 + Double(index) * 0.001, longitude: index.isMultiple(of: 2) ? 21.010 : 21.012)
        }
        let route = points.enumerated().map { index, point in
            let trackIndex = withGeometry ? "<osmand:trkpt_idx>\(index * 4)</osmand:trkpt_idx>" : ""
            return "<rtept \(point.attributes)><name>P\(index + 1)</name><extensions><osmand:profile>default</osmand:profile>\(trackIndex)</extensions></rtept>"
        }.joined(separator: "\n")
        let track = withGeometry ? trackGeometry(points: points) : ""
        // swiftlint:disable force_https
        return """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1" creator="OsmAndRouterV2" xmlns="http://www.topografix.com/GPX/1/1" xmlns:osmand="https://osmand.net/docs/technical/osmand-file-formats/osmand-gpx">
          <rte>\(route)</rte>
          \(track)
        </gpx>
        """
        // swiftlint:enable force_https
    }

    private static func trackGeometry(points: [Coordinate]) -> String {
        var samples: [Coordinate] = []
        var segments: [String] = []
        for index in 0..<(points.count - 1) {
            let start = points[index]
            let end = points[index + 1]
            let bend = Coordinate(latitude: start.latitude + (end.latitude - start.latitude) / 3,
                                  longitude: start.longitude + (end.longitude - start.longitude) / 3 + 0.001)
            let next = Coordinate(latitude: start.latitude + (end.latitude - start.latitude) * 2 / 3,
                                  longitude: start.longitude + (end.longitude - start.longitude) * 2 / 3)
            segments.append("<segment id=\"\(index + 1)\" length=\"4\" startTrkptIdx=\"\(samples.count)\" segmentTime=\"60\" speed=\"5\" types=\"0\" names=\"\"/>")
            samples.append(contentsOf: [start, bend, next, end])
        }
        samples.append(contentsOf: points.suffix(1))
        let trackPoints = samples.map { "<trkpt \($0.attributes)><ele>100</ele></trkpt>" }.joined(separator: "\n")
        return """
        <trk><name>UITest 5782 geometry</name><trkseg>
          \(trackPoints)
          <extensions>
            <osmand:route>\(segments.joined(separator: "\n"))</osmand:route>
            <osmand:types><type t="highway" v="unmatched"/></osmand:types>
          </extensions>
        </trkseg></trk>
        """
    }
}

struct PlanRouteHistorySnapshot: Decodable {
    struct Point: Decodable {
        let position: [Int]
        let name: String
        let gap: Bool
        let screenPosition: [Double]?
    }

    struct Line: Decodable {
        private enum CodingKeys: String, CodingKey {
            case color
            case samples = "positions"
        }

        let color: [Double]
        let samples: [[Int]]

        var positions: [[Int]] {
            samples.enumerated().compactMap { index, position in
                index == 0 || samples[index - 1] != position ? position : nil
            }
        }
    }

    struct Viewport: Decodable {
        let target: [Int]
        let zoom: Double
    }

    let viewport: Viewport
    let points: [Point]
    let lines: [Line]
    let lastLines: [Line]
    let crosshair: [Int]
    let calculating: Bool
    let editing: Bool

    var positions: [[Int]] { points.map(\.position) }
    var gaps: [Int] { points.indices.filter { points[$0].gap } }
    var geometry: [[[Int]]] { lines.map(\.positions) }

    var hasCurrentLastLine: Bool {
        guard let endpoint = points.last, !endpoint.gap else { return lastLines.isEmpty }
        return lastLines.count == 1 && lastLines[0].samples == [endpoint.position, crosshair]
    }
}
