//
//  AppStartupMonitor.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 07.07.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

/// A lightweight singleton class for monitoring and logging app startup events.
/// Logs time intervals between startup milestones to help diagnose performance bottlenecks.
/// Supports both Swift and Objective-C.

@objcMembers
final class AppStartupMonitor: NSObject {
    /// Shared singleton instance of the startup monitor.
    static let shared = AppStartupMonitor()
    
    /// The timestamp when the monitoring started.
    private var startTime: CFTimeInterval
    
    /// The list of recorded events and their elapsed time since the start.
    private var events: [(name: String, time: CFTimeInterval)] = []
    
    /// A flag indicating whether the startup logging has been completed.
    private var didFinishStartupLogging = false
    
    /// A lock to ensure thread-safe access to shared state.
    private let lock = NSLock()
    
    /// Private initializer to enforce singleton usage.
    private override init() {
        startTime = CACurrentMediaTime()
        super.init()
    }
    
    /// Records an event with the provided event name and originating class name.
    ///
    /// - Parameters:
    ///   - eventName: The name of the event to log.
    ///   - className: The name of the class or object where the event occurred.
    private func record(_ eventName: String, from className: String) {
        let fullEventName = "[\(className)] \(eventName)"
        recordFullEvent(fullEventName)
    }
    
    /// Records an event with the fully constructed event name.
    ///
    /// - Parameter fullEventName: The full event name including optional class context.
    private func recordFullEvent(_ fullEventName: String) {
        let currentTime = CACurrentMediaTime()
        let elapsed = currentTime - startTime
        
        lock.lock()
        events.append((name: fullEventName, time: elapsed))
        lock.unlock()
        
        NSLog("[Startup] \(fullEventName): \(String(format: "%.3f", elapsed))s")
    }
    
    /// Logs all recorded startup events to the console along with total startup duration,
    /// and resets the monitor for potential future use.
    private func logAllEvents() {
        lock.lock()
        let capturedEvents = events
        let totalTime = capturedEvents.last?.time ?? 0
        lock.unlock()
        
        NSLog("\n=== App Startup Timeline ===")
        for event in capturedEvents {
            NSLog("\(event.name): \(String(format: "%.3f", event.time))s")
        }
        NSLog("Total startup time: \(String(format: "%.3f", totalTime))s")
        NSLog("============================\n")
        
        reset()
    }
    
    /// Resets the monitor by clearing all recorded events and resetting the start time.
    private func reset() {
        lock.lock()
        startTime = CACurrentMediaTime()
        events.removeAll()
        lock.unlock()
    }
}

extension AppStartupMonitor {
    
    /// Records a startup event if startup logging has not yet been marked as finished.
    /// The event can optionally include the class name of the object that triggered the log.
    ///
    /// - Parameters:
    ///   - eventName: The name of the event to log.
    ///   - object: The object or class from which the log is triggered (optional).
    @objc func log(_ eventName: String, from object: AnyObject?) {
        lock.lock()
        let wasFinished = didFinishStartupLogging
        lock.unlock()
        guard !wasFinished else { return }
        
        if let object {
            let className = String(describing: type(of: object))
            record(eventName, from: className)
        } else {
            recordFullEvent(eventName)
        }
    }
    
    /// Marks the startup logging as finished and prints all recorded events.
    /// This method ensures that the events are only logged once.
    @objc func markStartupFinishedIfNeeded() {
        lock.lock()
        let wasFinished = didFinishStartupLogging
        didFinishStartupLogging = true
        lock.unlock()
        
        guard !wasFinished else { return }
        logAllEvents()
    }
}
