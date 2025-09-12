//
//  ChangeMapOrientationAction.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 10.09.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
final class ChangeMapOrientationAction: OASwitchableAction {
    private static let keyModes = "compass_modes"
    
    static let type = QuickActionType(id: QuickActionIds.changeMapOrientationAction.rawValue,
                                      stringId: "change.map.orientation",
                                      cl: ChangeMapOrientationAction.self)
        .name(localizedString("rotate_map_to"))
        .nameAction(localizedString("shared_string_change"))
        .iconName("ic_custom_compass_rotated")
        .category(QuickActionTypeCategory.settings.rawValue)
        .nonEditable()
    
    override init() {
        super.init(actionType: Self.type)
    }

    override init(actionType type: QuickActionType) {
        super.init(actionType: type)
    }

    override init(action: OAQuickAction) {
        super.init(action: action)
    }
    
    override func getDescrTitle() -> String {
        localizedString("map_orientations")
    }
    
    override func getListKey() -> String {
        Self.keyModes
    }
    
    override func execute() {
        guard let sources = loadListFromParams() as? [String] else { return }
        if !sources.isEmpty {
            let showBottomSheetStyles = getParams()[kDialog] as? Bool ?? ((getParams()[kDialog] as? String) == "true")
            if showBottomSheetStyles {
                let bottomSheet = OAQuickActionSelectionBottomSheetViewController(action: self, type: .orientation)
                bottomSheet?.show()
                return
            }
            
            if let nextSource = nextOrientationFrom(sources: sources) {
                execute(withParams: [nextSource])
            }
        }
    }
    
    override func execute(withParams params: [String]) {
        guard let param = params.first, let compassMode = CompassMode.getMode(forKey: param) else {
            return
        }
        
        OAMapViewTrackingUtilities.instance().switchRotateMapMode(to: Int32(compassMode.value))
        OAMapButtonsHelper.sharedInstance().refreshQuickActionButtons()
    }
    
    override func getUIModel() -> OrderedDictionary<AnyObject, AnyObject> {
        let data = MutableOrderedDictionary<AnyObject, AnyObject>()

        data.setObject([
            [
                "type": OASwitchTableViewCell.reuseIdentifier,
                "key": kDialog,
                "title": localizedString("quick_action_interim_dialog"),
                "value": NSNumber(value: getParams()[kDialog] as? Bool ?? ((getParams()[kDialog] as? String) == "true"))
            ],
            [
                "footer": localizedString("quick_action_dialog_descr")
            ]
        ] as AnyObject,
                       forKey: localizedString("quick_action_dialog") as AnyObject)

        var arr = [[String: Any]]()
        if let keys = getParams()[getListKey()] as? [String] {
            for key in keys {
                guard let compassMode = CompassMode.getMode(forKey: key) else { continue }
                let title = compassMode.title
                let img = compassMode.iconName
                arr.append([
                    "type": OATitleDescrDraggableCell.reuseIdentifier,
                    "title": title,
                    "value": key,
                    "img": img
                ])
            }
        }
        arr.append([
            "type": OAButtonTableViewCell.reuseIdentifier,
            "title": localizedString("shared_string_add"),
            "target": "addMapOrientation"
        ])
        arr.append(["footer": localizedString("map_orientations_choose_description")])
        data.setObject(arr as AnyObject,
                       forKey: localizedString("map_orientations") as AnyObject)

        return data
    }
    
    override func fillParams(_ model: [AnyHashable : Any]) -> Bool {
        var params = getParams()
        var sources: [String] = []
        
        for value in model.values {
            guard let arr = value as? [[AnyHashable: Any]] else { continue }
            for item in arr {
                if let key = item["key"] as? String, key == kDialog {
                    params[kDialog] = item["value"]
                } else if let type = item["type"] as? String,
                          type == OATitleDescrDraggableCell.reuseIdentifier,
                          let value = item["value"] as? String {
                    sources.append(value)
                }
            }
        }
        
        params[getListKey()] = sources
        setParams(params)
        return !sources.isEmpty
    }
    
    override func loadListFromParams() -> [Any]? {
        var list = getParams()[getListKey()] as? [String]
        list?.removeAll(where: { CompassMode.getMode(forKey: $0) == nil })
        return list
    }
    
    override func getStateName() -> String? {
        guard let title = CompassMode.getMode(forKey: getOrientation())?.title else { return getName() }
        return title
    }
    
    override func getIcon() -> UIImage? {
        guard let iconName = CompassMode.getMode(forKey: getOrientation())?.iconName else { return super.getIcon() }
        return UIImage.templateImageNamed(iconName)
    }
    
    override func getIconResName() -> String? {
        guard let iconName = CompassMode.getMode(forKey: getOrientation())?.iconName else { return super.getIconResName() }
        return iconName
    }
    
    private func getOrientation() -> String {
        let settings = OAAppSettings.sharedManager()
        return CompassMode.getByValue(Int(settings.rotateMap.get())).key
    }
    
    private func nextOrientationFrom(sources: [String]) -> String? {
        if !sources.isEmpty {
            let curStyle = getOrientation()
            var nextStyle = sources.first
            if let index = sources.firstIndex(of: curStyle),
               index >= 0,
               index + 1 < sources.count {
                nextStyle = sources[index + 1]
            }
            return nextStyle
        }
        return nil
    }
}
