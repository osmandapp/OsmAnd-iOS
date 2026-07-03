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

private struct GeoBBox {
    var minLat: Double
    var maxLat: Double
    var minLon: Double
    var maxLon: Double

    static func from(_ points: [IndexedTrackPoint], indices: ArraySlice<Int>) -> GeoBBox {
        var minLat = Double.greatestFiniteMagnitude
        var maxLat = -Double.greatestFiniteMagnitude
        var minLon = Double.greatestFiniteMagnitude
        var maxLon = -Double.greatestFiniteMagnitude
        for i in indices {
            let p = points[i]
            minLat = min(minLat, p.lat)
            maxLat = max(maxLat, p.lat)
            minLon = min(minLon, p.lon)
            maxLon = max(maxLon, p.lon)
        }
        return GeoBBox(minLat: minLat, maxLat: maxLat, minLon: minLon, maxLon: maxLon)
    }

    func minHaversineDistance(lat: Double, lon: Double) -> Double {
        let clampedLat = min(max(lat, minLat), maxLat)
        let clampedLon = min(max(lon, minLon), maxLon)
        return OAMapUtils.getDistance(lat, lon1: lon, lat2: clampedLat, lon2: clampedLon)
    }
}

private final class KDNode {
    let pointIndex: Int
    let axis: Int // 0 = lat, 1 = lon
    let bbox: GeoBBox
    var left: KDNode?
    var right: KDNode?

    init(pointIndex: Int, axis: Int, bbox: GeoBBox) {
        self.pointIndex = pointIndex
        self.axis = axis
        self.bbox = bbox
    }
}

final class TrackPointsKDIndex {
    private let points: [IndexedTrackPoint]
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
        self.root = Self.build(points: flat, indices: Array(flat.indices), depth: 0)
    }
    
    func nearestTrackIndex(lat: Double, lon: Double) -> Int? {
        guard let root else { return nil }

        var bestDist = Double.greatestFiniteMagnitude
        var bestTrackIndex = -1
        var bestPointIndex = Int.max

        @inline(__always)
        func isBetter(_ d: Double, _ t: Int, _ p: Int) -> Bool {
            if d < bestDist { return true }
            if d > bestDist { return false }
            if t < bestTrackIndex { return true }
            if t > bestTrackIndex { return false }
            return p < bestPointIndex
        }

        @inline(__always)
        func consider(_ p: IndexedTrackPoint) {
            let d = OAMapUtils.getDistance(lat, lon1: lon,
                                           lat2: p.lat, lon2: p.lon)
            if isBetter(d, p.trackIndex, p.pointIndex) {
                bestDist = d
                bestTrackIndex = p.trackIndex
                bestPointIndex = p.pointIndex
            }
        }

        struct StackItem {
            let node: KDNode
        }

        var stack: [KDNode] = [root]

        while let node = stack.popLast() {

            consider(points[node.pointIndex])

            let left = node.left
            let right = node.right

            let leftMin = left?.bbox.minHaversineDistance(lat: lat, lon: lon) ?? .infinity
            let rightMin = right?.bbox.minHaversineDistance(lat: lat, lon: lon) ?? .infinity

            if leftMin < rightMin {
                if rightMin <= bestDist, let r = right { stack.append(r) }
                if leftMin <= bestDist, let l = left { stack.append(l) }
            } else {
                if leftMin <= bestDist, let l = left { stack.append(l) }
                if rightMin <= bestDist, let r = right { stack.append(r) }
            }
        }

        return bestTrackIndex >= 0 ? bestTrackIndex : nil
    }

    private static func build(points: [IndexedTrackPoint], indices: [Int], depth: Int) -> KDNode? {
        guard !indices.isEmpty else { return nil }

        let axis = depth & 1
        let bbox = GeoBBox.from(points, indices: indices[indices.startIndex..<indices.endIndex])

        var sorted = indices
        sorted.sort { a, b in
            let pa = points[a]
            let pb = points[b]
            if axis == 0 {
                if pa.lat != pb.lat { return pa.lat < pb.lat }
                if pa.lon != pb.lon { return pa.lon < pb.lon }
            } else {
                if pa.lon != pb.lon { return pa.lon < pb.lon }
                if pa.lat != pb.lat { return pa.lat < pb.lat }
            }
            if pa.trackIndex != pb.trackIndex { return pa.trackIndex < pb.trackIndex }
            return pa.pointIndex < pb.pointIndex
        }

        let mid = sorted.count / 2
        let node = KDNode(pointIndex: sorted[mid], axis: axis, bbox: bbox)

        let leftIndices = Array(sorted[..<mid])
        let rightIndices = Array(sorted[(mid + 1)...])

        node.left = build(points: points, indices: leftIndices, depth: depth + 1)
        node.right = build(points: points, indices: rightIndices, depth: depth + 1)
        return node
    }
}
