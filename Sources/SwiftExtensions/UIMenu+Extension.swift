//
//  UIMenu+Extension.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 30.05.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objc
extension UIMenu {
    /* Example:
     UIMenu.composedMenu(from: [
        [connectionAction],
        [settings, rename],
        [forget]
    ]
     */
    
    /// Creates a composed menu from an array of menu element sections.
    ///
    /// - Parameter sections: A two-dimensional array where each inner array represents
    ///   a section of `UIMenuElement` items.
    /// - Returns: A `UIMenu` object containing the provided sections, each displayed as an inline submenu.
    static func composedMenu(from sections: [[UIMenuElement]]) -> UIMenu {
        UIMenu(title: "", children: sections.map(UIMenu.inlineSection))
    }

    /// Creates an inline menu section from a list of menu elements.
    ///
    /// - Parameter elements: An array of `UIMenuElement` items to be grouped into an inline section.
    /// - Returns: A `UIMenu` configured with the `.displayInline` option, containing the given elements.
    private static func inlineSection(with elements: [UIMenuElement]) -> UIMenu {
        UIMenu(title: "", options: .displayInline, children: elements)
    }
}
