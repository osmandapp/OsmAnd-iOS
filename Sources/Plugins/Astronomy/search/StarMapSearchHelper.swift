//
//  StarMapSearchHelper.swift
//  OsmAnd Maps
//
//  Created by Codex on 06.06.2026.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

import Foundation
import OsmAndShared
import UIKit

final class StarMapSearchHelper {
    private struct RiseSetCacheEntry {
        let nextRise: Date?
        let nextSet: Date?
    }

    private var riseSetCache: [String: RiseSetCacheEntry] = [:]
    private var visibleTonightCache: [String: Bool] = [:]
    private let cacheLock = NSLock()
    private var computationContext = StarMapSearchComputationContext(observer: Observer(latitude: 0.0, longitude: 0.0, height: 0.0),
                                                                     now: Date(),
                                                                     dusk: Date(),
                                                                     dawn: Date().addingTimeInterval(12 * 60 * 60))

    func updateComputationContext(_ computationContext: StarMapSearchComputationContext) {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        self.computationContext = computationContext
        riseSetCache.removeAll()
        visibleTonightCache.removeAll()
    }

    func getVisibleTonight(_ entry: StarMapSearchEntry) -> Bool {
        cacheLock.lock()
        if entry.visibleTonightCalculated {
            cacheLock.unlock()
            return entry.isVisibleTonight
        }
        if let cachedVisibleTonight = visibleTonightCache[entry.objectRef.id] {
            entry.isVisibleTonight = cachedVisibleTonight
            entry.visibleTonightCalculated = true
            cacheLock.unlock()
            return cachedVisibleTonight
        }
        let context = computationContext
        cacheLock.unlock()

        let riseSet = AstroUtils.nextRiseSet(object: entry.objectRef,
                                             startSearch: context.dusk,
                                             observer: context.observer,
                                             windowStart: context.dusk,
                                             windowEnd: context.dawn)
        let visibleAtDusk = AstroUtils.altitude(entry.objectRef, at: context.dusk, observer: context.observer) > 0
        let isVisibleTonight = visibleAtDusk || riseSet.rise != nil || riseSet.set != nil

        cacheLock.lock()
        defer { cacheLock.unlock() }
        if let cachedVisibleTonight = visibleTonightCache[entry.objectRef.id] {
            entry.isVisibleTonight = cachedVisibleTonight
            entry.visibleTonightCalculated = true
            return cachedVisibleTonight
        }
        entry.isVisibleTonight = isVisibleTonight
        entry.visibleTonightCalculated = true
        visibleTonightCache[entry.objectRef.id] = isVisibleTonight
        return isVisibleTonight
    }

    func getRiseSortValue(_ entry: StarMapSearchEntry) -> Int64 {
        ensureRiseSet(entry)
        return entry.nextRise.map(millisecondsSince1970) ?? Int64.max
    }

    func getSetSortValue(_ entry: StarMapSearchEntry) -> Int64 {
        ensureRiseSet(entry)
        return entry.nextSet.map(millisecondsSince1970) ?? Int64.max
    }

    func resolveEventText(_ entry: StarMapSearchEntry) -> NSAttributedString {
        ensureRiseSet(entry)
        let rise = entry.nextRise
        let set = entry.nextSet
        let eventText: String
        if let rise, let set {
            if rise < set {
                eventText = formatEvent(rise, isRise: true)
            } else {
                eventText = formatEvent(set, isRise: false)
            }
        } else if let rise {
            eventText = formatEvent(rise, isRise: true)
        } else if let set {
            eventText = formatEvent(set, isRise: false)
        } else if entry.objectRef.altitude > 0 {
            eventText = localizedString("astro_search_always_up")
        } else {
            eventText = localizedString("astro_search_never_rises")
        }
        return replaceEventArrowWithIcon(eventText)
    }

    func preloadRiseSet(_ entries: ArraySlice<StarMapSearchEntry>) {
        for entry in entries {
            ensureRiseSet(entry)
        }
    }

    private func ensureRiseSet(_ entry: StarMapSearchEntry) {
        cacheLock.lock()
        if entry.riseSetCalculated {
            cacheLock.unlock()
            return
        }
        if let cachedRiseSet = riseSetCache[entry.objectRef.id] {
            entry.nextRise = cachedRiseSet.nextRise
            entry.nextSet = cachedRiseSet.nextSet
            entry.riseSetCalculated = true
            cacheLock.unlock()
            return
        }
        let context = computationContext
        cacheLock.unlock()

        let riseSet = AstroUtils.nextRiseSet(object: entry.objectRef,
                                             startSearch: context.now,
                                             observer: context.observer)

        cacheLock.lock()
        defer { cacheLock.unlock() }
        if entry.riseSetCalculated {
            return
        }
        if let cachedRiseSet = riseSetCache[entry.objectRef.id] {
            entry.nextRise = cachedRiseSet.nextRise
            entry.nextSet = cachedRiseSet.nextSet
            entry.riseSetCalculated = true
            return
        }
        entry.nextRise = riseSet.rise
        entry.nextSet = riseSet.set
        entry.riseSetCalculated = true
        riseSetCache[entry.objectRef.id] = RiseSetCacheEntry(nextRise: riseSet.rise, nextSet: riseSet.set)
    }

    private func formatEvent(_ time: Date, isRise: Bool) -> String {
        let formattedTime = AstroUtils.formatLocalTime(time)
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: computationContext.now)
        let eventDate = calendar.startOfDay(for: time)
        let daysBetween = calendar.dateComponents([.day], from: startDate, to: eventDate).day ?? 0
        if daysBetween == 1 {
            let tomorrow = localizedString("tomorrow")
            if isRise {
                return String(format: localizedString("astro_search_rises_tomorrow"), tomorrow, formattedTime)
            }
            return String(format: localizedString("astro_search_sets_tomorrow"), tomorrow, formattedTime)
        } else if isRise {
            return String(format: localizedString("astro_search_rises_at"), formattedTime)
        } else {
            return String(format: localizedString("astro_search_sets_at"), formattedTime)
        }
    }

    private func replaceEventArrowWithIcon(_ text: String) -> NSAttributedString {
        let iconName: String
        let arrow: String
        if text.contains(Self.RISE_ARROW) {
            arrow = Self.RISE_ARROW
            iconName = "ic_action_arrow_top_right_16"
        } else if text.contains(Self.SET_ARROW) {
            arrow = Self.SET_ARROW
            iconName = "ic_action_arrow_bottom_right_16"
        } else if text.contains(Self.UP_ARROW) {
            arrow = Self.UP_ARROW
            iconName = "ic_action_arrow_up2_16"
        } else if text.contains(Self.DOWN_ARROW) {
            arrow = Self.DOWN_ARROW
            iconName = "ic_action_arrow_down_16"
        } else {
            return NSAttributedString(string: text)
        }

        guard let image = AstroIcon.template(iconName)?.withTintColor(.iconColorSecondary, renderingMode: .alwaysOriginal) else {
            return NSAttributedString(string: text)
        }
        let attachment = NSTextAttachment()
        attachment.image = image
        attachment.bounds = CGRect(x: 0, y: -3, width: 16, height: 16)
        let result = NSMutableAttributedString(string: text)
        let nsText = text as NSString
        let range = nsText.range(of: arrow)
        if range.location != NSNotFound {
            result.replaceCharacters(in: range, with: NSAttributedString(attachment: attachment))
        }
        return result
    }

    private func millisecondsSince1970(_ date: Date) -> Int64 {
        Int64((date.timeIntervalSince1970 * 1000.0).rounded())
    }

    private static let RISE_ARROW = "↗"
    private static let SET_ARROW = "↘"
    private static let UP_ARROW = "↑"
    private static let DOWN_ARROW = "↓"
}
