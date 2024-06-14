//
//  QuickActionButtonState.swift
//  OsmAnd Maps
//
//  Created by Skalii on 24.05.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

@objcMembers
final class QuickActionButtonState: MapButtonState {

    static let defaultButtonId = "quick_actions"

    let statePref: OACommonBoolean
    let namePref: OACommonString
    let quickActionsPref: OACommonString
    let fabMarginPref: FabMarginPreference

    private let app = OsmAndApp.swiftInstance()
    private let settings = OAAppSettings.sharedManager()!
    private(set) var quickActions = [OAQuickAction]()

    override init(withId id: String) {
        statePref = settings.registerBooleanPreference(id + "_state", defValue: false).makeProfile()
        namePref = settings.registerStringPreference(id + "_name", defValue: nil).makeGlobal().makeShared()
        quickActionsPref = settings.registerStringPreference(id + "_list", defValue: nil).makeGlobal().makeShared().storeLastModifiedTime()
        fabMarginPref = FabMarginPreference(id + "_fab_margin")
        super.init(withId: id)
    }
    
    override func isEnabled() -> Bool {
        statePref.get()
    }

    override func getName() -> String {
        let defaultName = localizedString("configure_screen_quick_action")
        let name = namePref.get() ?? defaultName
        return name.isEmpty ? defaultName : name
    }

    func setEnabled(_ enabled: Bool) {
        statePref.set(enabled)
    }

    func hasCustomName() -> Bool {
        if let name = namePref.get() {
            return !name.isEmpty
        }
        return false
    }

    func setName(_ name: String) {
        namePref.set(name)
    }

    func getQuickAction(_ id: Int64) -> OAQuickAction? {
        for action in quickActions where action.id == id {
            return action
        }
        return nil
    }

    func getQuickAction(_ type: Int, name: String, params: [AnyHashable: Any]) -> OAQuickAction? {
        for action in quickActions {
            if action.getType() == type,
               ((action.hasCustomName() && action.getName() == name) || !action.hasCustomName()),
               NSDictionary(dictionary: action.getParams()).isEqual(to: params) {
                return action
            }
        }
        return nil
    }

    func add(_ quickAction: OAQuickAction) {
        quickActions.append(quickAction)
    }

    func remove(_ quickAction: OAQuickAction) {
        if let index = quickActions.firstIndex(of: quickAction) {
            quickActions.remove(at: index)
        }
    }

    func set(_ quickAction: OAQuickAction) {
        if let index = quickActions.firstIndex(of: quickAction) {
            quickActions[index] = quickAction
        }
    }

    func set(quickActions: [OAQuickAction]) {
        self.quickActions.removeAll()
        self.quickActions.append(contentsOf: quickActions)
    }

    func getLastModifiedTime() -> Int {
        quickActionsPref.lastModifiedTime
    }

    func setLastModifiedTime(_ lastModifiedTime: Int) {
        quickActionsPref.lastModifiedTime = lastModifiedTime
    }

    func isSingleAction() -> Bool {
        quickActions.count == 1
    }

    override func getIcon() -> UIImage? {
        if isSingleAction() {
            let action = quickActions.first
            return action?.getIcon()
        }
        return super.getIcon()
    }

    func resetForMode(_ appMode: OAApplicationMode) {
        statePref.resetMode(toDefault: appMode)
        fabMarginPref.resetMode(toDefault: appMode)
    }

    func copyForMode(fromMode: OAApplicationMode, toMode: OAApplicationMode) {
        statePref.set(statePref.get(fromMode), mode: toMode)
        fabMarginPref.copyForMode(fromMode: fromMode, toMode: toMode)
    }

    func saveActions(_ serializer: QuickActionSerializer) {
        do {
            let jsonString = String(data: try serializer.serialize(quickActions), encoding: .utf8)
            quickActionsPref.set(jsonString)
        } catch {
            print("Error encoding quickActions: \(error)")
        }
    }

    func parseQuickActions(_ serializer: QuickActionSerializer) throws {
        if let json = quickActionsPref.get(), let data = json.data(using: .utf8) {
            quickActions = try serializer.deserialize(data)
        }
    }

    func isDefaultButton() -> Bool {
        Self.defaultButtonId == id
    }
}
