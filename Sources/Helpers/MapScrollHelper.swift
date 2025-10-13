//
//  MapScrollHelper.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 09.10.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

final class MapScrollHelper {
    static let shared = MapScrollHelper()
    
    private let mapVC: OAMapViewController = OARootViewController.instance().mapPanel.mapViewController
    private let panInterval: TimeInterval = 0.2
    
    private var scrollTimer: Timer?
    private var currentDirection: EOAMapPanDirection?
    
    func startScrolling(direction: EOAMapPanDirection) {
        guard currentDirection != direction else { return }
        currentDirection = direction
        
        performPan(for: direction)
        
        if scrollTimer == nil {
            let timer = Timer.scheduledTimer(withTimeInterval: panInterval, repeats: true) { [weak self] _ in
                guard let self, let dir = self.currentDirection else { return }
                self.performPan(for: dir)
            }
            RunLoop.main.add(timer, forMode: .common)
            scrollTimer = timer
        }
    }
    
    func stopScrolling(direction: EOAMapPanDirection) {
        guard currentDirection == direction else { return }
        
        currentDirection = nil
        scrollTimer?.invalidate()
        scrollTimer = nil
    }
    
    func performPan(for direction: EOAMapPanDirection) {
        switch direction {
        case .up:    mapVC.animatedPanUp()
        case .down:  mapVC.animatedPanDown()
        case .left:  mapVC.animatedPanLeft()
        case .right: mapVC.animatedPanRight()
        @unknown default: break
        }
    }
}
