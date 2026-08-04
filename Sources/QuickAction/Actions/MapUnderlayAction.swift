//
//  MapUnderlayAction.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 18.02.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

final class MapUnderlayAction: OASwitchableAction {
    private static let type = QuickActionType(id: QuickActionIds.mapUnderlayActionId.rawValue,
                                              stringId: "mapunderlay.change",
                                              cl: MapUnderlayAction.self)
        .name(localizedString("quick_action_map_underlay"))
        .nameAction(localizedString("shared_string_change"))
        .iconName("ic_custom_underlay_map")
        .secondaryIconName("ic_custom_compound_action_change")
        .category(QuickActionTypeCategory.configureMap.rawValue)
    
    private let keyUnderlays = "underlays"
    private let noUnderlay = "no_underlay"
    
    private var onlineMapSources: [OAMapSourceResourceSwiftItem] = []
    
    override init() {
        super.init(actionType: Self.getType())
    }
    
    override init(action: OAQuickAction) {
        super.init(action: action)
    }
    
    override func commonInit() {
        onlineMapSources = OAResourcesUISwiftHelper.sortedRasterMapSources(false)
    }
    
    override class func getType() -> QuickActionType {
        type
    }
    
    override func loadListFromParams() -> [Any] {
        getParams()[getListKey()] as? [[String]] ?? []
    }
    
    override func getAddBtnText() -> String {
        localizedString("quick_action_map_underlay_action")
    }
    
    override func getDescrHint() -> String {
        localizedString("quick_action_list_descr")
    }
    
    override func getDescrTitle() -> String {
        localizedString("quick_action_map_underlay_title")
    }
    
    override func getListKey() -> String {
        keyUnderlays
    }
    
    override func getTranslatedItemName(_ item: String) -> String {
        item == noUnderlay ? localizedString("no_underlay") : item
    }
    
    override func disabledItem() -> String {
        noUnderlay
    }
    
    override func selectedItem() -> String {
        guard let mapUnderlay = OsmAndApp.swiftInstance().data.underlayMapSource?.name else {
            return noUnderlay
        }
        return mapUnderlay
    }
    
    override func nextSelectedItem() -> String {
        guard let sources = loadListFromParams() as? [[String]],
              let nextSource = next(fromSource: sources) else { return "" }
        return nextSource.first == noUnderlay ? noUnderlay : nextSource.last ?? ""
    }
    
    override func fillParams(_ model: [AnyHashable: Any]) -> Bool {
        var params = getParams()
        var sources: [[Any]] = []
        for value in model.values {
            guard let arr = value as? [[AnyHashable: Any]] else { continue }
            
            for item in arr {
                if let key = item["key"] as? String,
                   key == kDialog {
                    params[kDialog] = item["value"]
                } else if let type = item["type"] as? String,
                          type == OATitleDescrDraggableCell.reuseIdentifier,
                          let value = item["value"],
                          let title = item["title"] {
                    sources.append([value, title])
                }
            }
        }
        params[getListKey()] = sources
        setParams(params)
        return !sources.isEmpty
    }
    
    override func execute() {
        guard let sources: [[String]] = loadListFromParams() as? [[String]], !sources.isEmpty else { return }
        let showBottomSheetStyles = (getParams()[kDialog] as? Bool) ?? false
        
        if showBottomSheetStyles {
            let bottomSheet = OAQuickActionSelectionBottomSheetViewController(
                action: self,
                type: .underlay
            )
            bottomSheet?.show()
            return
        }
        
        guard let nextSource = next(fromSource: sources) else { return }
        execute(withParams: nextSource)
    }
    
    override func execute(withParams params: [String]) {
        let app = OsmAndApp.swiftInstance()
        guard let variant = params.first, let name = params.last else { return }
        let hasUnderlay = variant != noUnderlay
        OAAppSettings.sharedManager().setUnderlayOpacitySliderVisibility(hasUnderlay)
        if hasUnderlay {
            var newMapSource: OAMapSource?
            for resource in onlineMapSources where resource.mapSource().variant == variant && resource.mapSource().name == name {
                newMapSource = resource.mapSource()
                break
            }
            app?.data.underlayMapSource = newMapSource
        } else {
            app?.data.underlayMapSource = nil
        }
        OsmAndApp.swiftInstance().mapSettingsChangeObservable.notifyEvent()
    }

    private func next(fromSource sources: [[String]]) -> [String]? {
        guard let firstSource = sources.first else { return nil }

        let currentSource = OsmAndApp.swiftInstance().data.underlayMapSource
        let currentIndex = sources.firstIndex { source in
            if let currentSource {
                return source.first == currentSource.variant && source.last == currentSource.name
            }
            return source.first == noUnderlay
        }
        if sources.count == 1, currentIndex == 0 {
            return [noUnderlay, localizedString("no_underlay")]
        } else if let currentIndex, currentIndex < sources.count - 1 {
            return sources[currentIndex + 1]
        }
        return firstSource
    }
    
    override func getUIModel() -> OrderedDictionary<AnyObject, AnyObject> {
        let data = MutableOrderedDictionary<AnyObject, AnyObject>()
        
        data.setObject([
            [
                "type": OASwitchTableViewCell.reuseIdentifier,
                "key": kDialog,
                "title": localizedString("quick_action_interim_dialog"),
                "value": NSNumber(value: getParams()[kDialog] as? Bool ?? false)
            ],
            [
                "footer": localizedString("quick_action_dialog_descr")
            ]
        ] as AnyObject, forKey: localizedString("quick_action_dialog") as AnyObject)
        
        let sources = (getParams()[getListKey()] as? [[String]]) ?? []
        var arr: [[String: Any]] = []
        
        for source in sources {
            arr.append([
                "type": OATitleDescrDraggableCell.reuseIdentifier,
                "title": source.last as Any,
                "value": source.first as Any,
                "img": "ic_custom_map_style"
            ])
        }
        
        arr.append([
            "title": localizedString("quick_action_map_underlay_action"),
            "type": OAButtonTableViewCell.reuseIdentifier,
            "target": "addMapUnderlay"
        ])
        
        data.setObject(arr as AnyObject, forKey: localizedString("quick_action_map_underlay_title") as AnyObject)
        
        return data
    }
    
    override func getStateName() -> String? {
        let name = getName()
        let nextSource = nextSelectedItem()
        if !nextSource.isEmpty {
            return nextSource == disabledItem() ? localizedString("no_underlay") : nextSource
        } else {
            return name
        }
    }
}
