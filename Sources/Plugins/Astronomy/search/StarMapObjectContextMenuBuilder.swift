//
//  StarMapObjectContextMenuBuilder.swift
//  OsmAnd Maps
//
//  Created by Vitaliy Sova on 11.07.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import Foundation

enum StarMapObjectContextMenuBuilder {
    static func makeConfiguration(for object: SkyObject,
                                  handler: StarMapObjectActionHandler,
                                  onLocate: @escaping () -> Void,
                                  onStateChanged: @escaping () -> Void) -> UIContextMenuConfiguration {
        UIContextMenuConfiguration(identifier: object.id as NSString, actionProvider: { _ in
            makeMenu(for: object, onLocate: onLocate, handler: handler, onStateChanged: onStateChanged)
        })
    }

    private static func makeMenu(for object: SkyObject,
                                 onLocate: @escaping () -> Void,
                                 handler: StarMapObjectActionHandler,
                                 onStateChanged: @escaping () -> Void) -> UIMenu {
        let save = UIAction(
            title: localizedString("shared_string_save"),
            image: object.isFavorite ? .icCustomBookmark : .icCustomBookmarkOutlined
        ) { _ in
            object.isFavorite.toggle()
            handler.onFavoriteChanged(object, object.isFavorite)
            onStateChanged()
        }
        
        let locate = UIAction(
            title: localizedString("astro_locate"),
            image: .icCustomLocationMarkerOutlined
        ) { _ in
            onLocate()
        }

        let direction = UIAction(
            title: localizedString("astro_direction"),
            image: object.showDirection ? .icCustomTargetDirectionOn : .icCustomTargetDirectionOff
        ) { _ in
            object.showDirection.toggle()
            if object.showDirection {
                object.colorIndex = handler.onDirectionChanged(object, true)
            } else {
                handler.directionChanged(object, enabled: false)
            }
            onStateChanged()
        }

        let path = UIAction(
            title: localizedString("astro_path"),
            image: object.showCelestialPath ? .icCustomTargetPathOn : .icCustomTargetPathOff
        ) { _ in
            object.showCelestialPath.toggle()
            handler.onCelestialPathChanged(object, object.showCelestialPath)
            handler.onSetObjectPinned(object, object.showCelestialPath, true)
            onStateChanged()
        }

        return UIMenu(title: "", children: [save, locate, direction, path])
    }
}

struct StarMapObjectActionHandler {
    let onFavoriteChanged: (SkyObject, Bool) -> Void
    let onDirectionChanged: (SkyObject, Bool) -> Int
    let onCelestialPathChanged: (SkyObject, Bool) -> Void
    let onSetObjectPinned: (SkyObject, Bool, Bool) -> Void
    
    @discardableResult func directionChanged(_ object: SkyObject, enabled: Bool) -> Int {
        onDirectionChanged(object, enabled)
    }
}
