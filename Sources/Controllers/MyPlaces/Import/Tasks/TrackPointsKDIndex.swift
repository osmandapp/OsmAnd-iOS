//
//  TrackPointsKDIndex.swift
//  OsmAnd Maps
//
//  Created by Vitaliy Sova on 02.07.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import Foundation

struct IndexedTrackPoint {
    let lat: Double
    let lon: Double
    let trackIndex: Int
    let pointIndex: Int
}

// MARK: - 3D unit-sphere coordinates

private struct Vector3 {
    let x: Double
    let y: Double
    let z: Double

    static func from(lat: Double, lon: Double) -> Vector3 {
        let latRad = lat * .pi / 180.0
        let lonRad = lon * .pi / 180.0
        let cosLat = cos(latRad)
        return Vector3(
            x: cosLat * cos(lonRad),
            y: cosLat * sin(lonRad),
            z: sin(latRad)
        )
    }

    func distance(to other: Vector3) -> Double {
        let dx = x - other.x
        let dy = y - other.y
        let dz = z - other.z
        return (dx * dx + dy * dy + dz * dz).squareRoot()
    }
}

private struct BBox3 {
    var minX: Double
    var maxX: Double
    var minY: Double
    var maxY: Double
    var minZ: Double
    var maxZ: Double

    static func from(_ vectors: [Vector3], indices: ArraySlice<Int>) -> BBox3 {
        var minX = Double.greatestFiniteMagnitude
        var maxX = -Double.greatestFiniteMagnitude
        var minY = Double.greatestFiniteMagnitude
        var maxY = -Double.greatestFiniteMagnitude
        var minZ = Double.greatestFiniteMagnitude
        var maxZ = -Double.greatestFiniteMagnitude

        for i in indices {
            let v = vectors[i]
            minX = min(minX, v.x); maxX = max(maxX, v.x)
            minY = min(minY, v.y); maxY = max(maxY, v.y)
            minZ = min(minZ, v.z); maxZ = max(maxZ, v.z)
        }
        return BBox3(minX: minX, maxX: maxX, minY: minY, maxY: maxY, minZ: minZ, maxZ: maxZ)
    }

    /// Valid lower bound for Euclidean distance to any point inside the box.
    func minDistance(to query: Vector3) -> Double {
        let cx = clamp(query.x, minX, maxX)
        let cy = clamp(query.y, minY, maxY)
        let cz = clamp(query.z, minZ, maxZ)
        return query.distance(to: Vector3(x: cx, y: cy, z: cz))
    }

    private func clamp(_ value: Double, _ minValue: Double, _ maxValue: Double) -> Double {
        max(minValue, min(value, maxValue))
    }
}

private final class KDNode {
    let pointIndex: Int
    let bbox: BBox3
    var left: KDNode?
    var right: KDNode?

    init(pointIndex: Int, bbox: BBox3) {
        self.pointIndex = pointIndex
        self.bbox = bbox
    }
}

// MARK: - Index

final class TrackPointsKDIndex {
    private let points: [IndexedTrackPoint]
    private let vectors: [Vector3]
    private let root: KDNode?

    init(itemsWaypoints: [[WptPt]]) {
        var flat: [IndexedTrackPoint] = []
        flat.reserveCapacity(itemsWaypoints.reduce(0) { $0 + $1.count })

        for (trackIndex, waypoints) in itemsWaypoints.enumerated() {
            for (pointIndex, wpt) in waypoints.enumerated() {
                flat.append(IndexedTrackPoint(
                    lat: wpt.lat,
                    lon: wpt.lon,
                    trackIndex: trackIndex,
                    pointIndex: pointIndex
                ))
            }
        }

        self.points = flat
        self.vectors = flat.map { Vector3.from(lat: $0.lat, lon: $0.lon) }
        self.root = Self.build(vectors: vectors, indices: Array(flat.indices), depth: 0)
    }

    private static func build(vectors: [Vector3], indices: [Int], depth: Int) -> KDNode? {
        guard !indices.isEmpty else { return nil }

        let axis = depth % 3
        let bbox = BBox3.from(vectors, indices: indices[indices.startIndex..<indices.endIndex])

        var sorted = indices
        sorted.sort { a, b in
            let va = vectors[a]
            let vb = vectors[b]
            let cmp: Double
            switch axis {
            case 0: cmp = va.x - vb.x
            case 1: cmp = va.y - vb.y
            default: cmp = va.z - vb.z
            }
            if cmp != 0 { return cmp < 0 }
            if va.x != vb.x { return va.x < vb.x }
            if va.y != vb.y { return va.y < vb.y }
            if va.z != vb.z { return va.z < vb.z }
            return a < b
        }

        let mid = sorted.count / 2
        let node = KDNode(pointIndex: sorted[mid], bbox: bbox)

        node.left = build(vectors: vectors, indices: Array(sorted[..<mid]), depth: depth + 1)
        node.right = build(vectors: vectors, indices: Array(sorted[(mid + 1)...]), depth: depth + 1)
        return node
    }

    func nearestTrackIndex(lat: Double, lon: Double, isCancelled: (() -> Bool)? = nil) -> Int? {
        guard let root else { return nil }

        let query = Vector3.from(lat: lat, lon: lon)

        var bestDist = Double.greatestFiniteMagnitude
        var bestTrackIndex = -1
        var bestPointIndex = Int.max

        func isBetter(_ d: Double, _ t: Int, _ p: Int) -> Bool {
            if d < bestDist { return true }
            if d > bestDist { return false }
            if t < bestTrackIndex { return true }
            if t > bestTrackIndex { return false }
            return p < bestPointIndex
        }

        func consider(_ index: Int) {
            let p = points[index]
            let d = OAMapUtils.getDistance(lat, lon1: lon, lat2: p.lat, lon2: p.lon)
            if isBetter(d, p.trackIndex, p.pointIndex) {
                bestDist = d
                bestTrackIndex = p.trackIndex
                bestPointIndex = p.pointIndex
            }
        }

        var stack: [KDNode] = [root]
        while let node = stack.popLast() {
            if isCancelled?() == true { return nil }
            consider(node.pointIndex)

            let left = node.left
            let right = node.right

            let maxChord = maxChord(forHaversineMeters: bestDist)
            let leftChord = left?.bbox.minDistance(to: query) ?? .infinity
            let rightChord = right?.bbox.minDistance(to: query) ?? .infinity
            
            let slack = 1e-6
            if leftChord < rightChord {
                if rightChord <= maxChord + slack, let r = right { stack.append(r) }
                if leftChord <= maxChord + slack, let l = left { stack.append(l) }
            } else {
                if leftChord <= maxChord + slack, let l = left { stack.append(l) }
                if rightChord <= maxChord + slack, let r = right { stack.append(r) }
            }
        }

        return bestTrackIndex >= 0 ? bestTrackIndex : nil
    }

    private func maxChord(forHaversineMeters meters: Double) -> Double {
        guard meters.isFinite else { return .infinity }

        let angular = meters / 6_372_800.0
        return 2.0 * sin(min(.pi / 2.0, angular / 2.0))
    }
}
