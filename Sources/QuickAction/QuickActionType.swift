//
//  QuickActionType.swift
//  OsmAnd Maps
//
//  Created by Skalii on 20.05.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

@objc(EOAQuickActionTypeCategory)
enum QuickActionTypeCategory: Int {
    case unsupported = -1
    case createCategory
    case configureMap
    case navigation
    case configureScreen
    case settings
    case open
}

@objc(OAQuickActionType)
@objcMembers
final class QuickActionType: NSObject {
    let id: Int
    let stringId: String
    private var _actionEditable = false
    private var _name: String?
    private var _iconName: String?
    private var _secondaryIconName: String?
    private var cl: OAQuickAction.Type?
    private var _category: Int?

    init(id: Int, stringId: String) {
        self.id = id
        self.stringId = stringId
    }

    init(id: Int, stringId: String, cl: OAQuickAction.Type?) {
        self.id = id
        self.stringId = stringId
        self.cl = cl
        _actionEditable = cl != nil
    }

    func name(_ name: String) -> QuickActionType {
        _name = name
        return self
    }

    func category(_ category: Int) -> QuickActionType {
        _category = category
        return self
    }

    func iconName(_ iconName: String) -> QuickActionType {
        _iconName = iconName
        return self
    }

    func secondaryIconName(_ secondaryIconName: String) -> QuickActionType {
        _secondaryIconName = secondaryIconName
        return self
    }

    func nonEditable() -> QuickActionType {
        _actionEditable = false
        return self
    }

    func createNew() -> OAQuickAction {
        if let cl = cl {
            return cl.init()
        } else {
            fatalError("Class not defined")
        }
    }
        
    func createNew(_ action: OAQuickAction) -> OAQuickAction {
        if let cl = cl {
            return cl.init(action: action)
        } else {
            return OAQuickAction(action: action)
        }
    }

    var actionEditable: Bool {
        return _actionEditable
    }

    var name: String? {
        return _name
    }

    var iconName: String? {
        return _iconName
    }

    var secondaryIconName: String? {
        return _secondaryIconName
    }

    var category: Int {
        return _category ?? QuickActionTypeCategory.unsupported.rawValue
    }
}
