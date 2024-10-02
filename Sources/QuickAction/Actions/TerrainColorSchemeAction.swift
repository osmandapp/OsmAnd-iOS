//
//  TerrainColorSchemeAction.swift
//  OsmAnd Maps
//
//  Created by Skalii on 25.09.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

@objcMembers
final class TerrainColorSchemeAction: OASwitchableAction {

    static let type = QuickActionType(id: QuickActionIds.terrainColorSchemeActionId.rawValue,
                                      stringId: "terrain.colorscheme.change",
                                      cl: TerrainColorSchemeAction.self)
        .name(getName())
        .nameAction(localizedString("shared_string_change"))
        .iconName("ic_custom_terrain")
        .category(QuickActionTypeCategory.configureMap.rawValue)

    private static let keyTerrainModes = "terrain_modes"

    override init() {
        super.init(actionType: Self.type)
    }

    override init(actionType type: QuickActionType) {
        super.init(actionType: type)
    }

    override init(action: OAQuickAction) {
        super.init(action: action)
    }

    class func getName() -> String {
        localizedString("quick_action_terrain_color_scheme")
    }

    override func getDescrTitle() -> String {
        localizedString("srtm_color_scheme")
    }

    override func getListKey() -> String {
        Self.keyTerrainModes
    }

    override func execute() {
        if let mapStyles = loadListFromParams() as? [String],
           !mapStyles.isEmpty {
            if let showBottomSheetStyles = getParams()[kDialog] as? Bool,
               showBottomSheetStyles {
                OAQuickActionSelectionBottomSheetViewController(action: self,
                                                                type: .terrainScheme)
                    .show()
                return
            }
            if let nextStyle = getNextSelectedItem() {
                execute(withParams: [nextStyle])
            }
        } else {
            OAUtilities.showToast(localizedString("quick_action_need_to_add_item_to_list"),
                                  details: "",
                                  duration: 4,
                                  in: OARootViewController.instance().view)
        }
    }

    override func execute(withParams params: [String]) {
        if let plugin = getSrtmPlugin(),
           let nextStyle = params.first,
           let newMode = TerrainMode.getByKey(nextStyle) {
            plugin.setTerrainMode(newMode)
            plugin.updateLayers()
        }
    }

    override func loadListFromParams () -> [Any] {
        guard let filterIds = getParams()[getListKey()] as? [String],
              !filterIds.isEmpty else {
            return []
        }
        return filterIds.filter { TerrainMode.isModeExist(String($0)) }
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
        ] as AnyObject,
                       forKey: localizedString("quick_action_dialog") as AnyObject)

        var arr = [[String: Any]]()
        if let palettes = getParams()[getListKey()] as? [String] {
            for paletteKey in palettes {
                var title = ""
                var desc = ""
                if let mode = TerrainMode.getByKey(paletteKey) {
                    title = mode.getDefaultDescription()
                    if let colorPalette = ColorPaletteHelper.shared.getGradientColorPalette(mode.getMainFile()) {
                        desc = PaletteCollectionHandler.createDescriptionForPalette(colorPalette)
                        arr.append([
                            "type": OATitleDescrDraggableCell.reuseIdentifier,
                            "title": title,
                            "desc": desc,
                            "colorPalette": colorPalette,
                            "palette": paletteKey
                        ])
                    }
                }
            }
        }
        arr.append([
            "type": OAButtonTableViewCell.reuseIdentifier,
            "title": localizedString("shared_string_add"),
            "target": "addTerrain"
        ])
        data.setObject(arr as AnyObject,
                       forKey: localizedString("srtm_color_scheme") as AnyObject)

        return data
    }

    override func fillParams(_ model: [AnyHashable: Any]) -> Bool {
        var params = getParams()
        var palettes = [String]()
        for value in model.values {
            guard let arr = value as? [[AnyHashable: Any]] else { continue }
            for item in arr {
                if let key = item["key"] as? String,
                   key == kDialog {
                    params[kDialog] = item["value"]
                } else if let type = item["type"] as? String,
                          type == OATitleDescrDraggableCell.reuseIdentifier,
                          let palette = item["palette"] as? String {
                    palettes.append(palette)
                }
            }
        }
        params[getListKey()] = palettes
        setParams(params)
        return !palettes.isEmpty
    }

    override func getTitle(_ filters: [Any]) -> String {
        guard !filters.isEmpty, let filtersStr = filters as? [String] else { return "" }

        if let firstItem = filtersStr.first,
           let translatedFirstItem = TerrainMode.getByKey(firstItem)?.getDescription() {
            return filtersStr.count > 1
                ? (translatedFirstItem + " +" + "\(filtersStr.count - 1)")
                : translatedFirstItem
        }
        return ""
    }

    private func getSrtmPlugin() -> OASRTMPlugin? {
        OAPluginsHelper.getPlugin(OASRTMPlugin.self) as? OASRTMPlugin
    }

    private func getSelectedItem() -> String {
        guard let srtmPlugin = getSrtmPlugin() else { return "" }
        return srtmPlugin.getTerrainMode().getKeyName()
    }

    private func getNextSelectedItem() -> String? {
        if let mapStyles = loadListFromParams() as? [String],
           !mapStyles.isEmpty {
            let curStyle = getSelectedItem()
            var nextStyle = mapStyles.first
            if let index = mapStyles.firstIndex(of: curStyle),
               index >= 0,
               index + 1 < mapStyles.count {
                nextStyle = mapStyles[index + 1]
            }
            return nextStyle
        }
        return nil
    }
}
