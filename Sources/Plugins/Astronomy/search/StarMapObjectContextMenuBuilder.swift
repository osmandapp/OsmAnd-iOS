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
                                  onStateChanged: @escaping () -> Void) -> UIContextMenuConfiguration {
        UIContextMenuConfiguration(identifier: object.id as NSString) { _ in
            makeMenu(for: object, handler: handler, onStateChanged: onStateChanged)
        }
    }

    private static func makeMenu(for object: SkyObject,
                                 handler: StarMapObjectActionHandler,
                                 onStateChanged: @escaping () -> Void) -> UIMenu {
        let save = UIAction(
            title: localizedString("shared_string_save"),
            image: AstroIcon.template(object.isFavorite ? "ic_custom_bookmark" : "ic_custom_bookmark_outlined")
        ) { _ in
            object.isFavorite.toggle()
            handler.onFavoriteChanged(object, object.isFavorite)
            onStateChanged()
        }

        let direction = UIAction(
            title: localizedString("astro_direction"),
            image: AstroIcon.template(object.showDirection ? "ic_custom_target_direction_on" : "ic_custom_target_direction_off")
        ) { _ in
            object.showDirection.toggle()
            if object.showDirection {
                object.colorIndex = handler.onDirectionChanged(object, true)
            } else {
                _ = handler.onDirectionChanged(object, false)
            }
            onStateChanged()
        }

        let path = UIAction(
            title: localizedString("astro_path"),
            image: AstroIcon.template(object.showCelestialPath ? "ic_custom_target_path_on" : "ic_custom_target_path_off")
        ) { _ in
            object.showCelestialPath.toggle()
            handler.onCelestialPathChanged(object, object.showCelestialPath)
            handler.onSetObjectPinned(object, object.showCelestialPath, true)
            onStateChanged()
        }

        return UIMenu(title: "", children: [save, direction, path])
    }
}

struct StarMapObjectActionHandler {
    let onFavoriteChanged: (SkyObject, Bool) -> Void
    let onDirectionChanged: (SkyObject, Bool) -> Int
    let onCelestialPathChanged: (SkyObject, Bool) -> Void
    let onSetObjectPinned: (SkyObject, Bool, Bool) -> Void
}
