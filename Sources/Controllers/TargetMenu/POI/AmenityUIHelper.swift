//
//  AmenityUIHelper.swift
//  OsmAnd
//
//  Created by Max Kojin on 02/10/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import OsmAndShared

// analog in android AmenityUIHelper.java

@objcMembers
final class AmenityUIHelper: NSObject {

    static let defaultAmenityIconName = "ic_custom_info_outlined"

    private static let NAMES_ROW_KEY = "names_row_key"

    var latLon: CLLocationCoordinate2D = CLLocationCoordinate2DMake(0, 0)

    // values from parent class MenuBuilder - base ContextMenuVC class
    var matchWidthDivider = false // show separator to full screen with
    var genericRowKeys: Set<String> = []

    private let helper: OAPOIHelper

    private var additionalInfo: AdditionalInfoBundle

    private var poiCategory: OAPOICategory?
    private var sharedPoiCategory: PoiCategory?
    private var subtype: String?

    private var osmEditingEnabled = OAPluginsHelper.isEnabled(OAOsmEditingPlugin.self)

    init(infoBundle: AdditionalInfoBundle) {
        self.additionalInfo = infoBundle
        self.helper = OAPOIHelper.sharedInstance()
        super.init()
    }

    func initVariables() {
        sharedPoiCategory = additionalInfo.getCategory()
        poiCategory = sharedPoiCategory.flatMap { helper.getPoiCategory(byName: $0.getKeyName()) } ?? helper.otherPoiCategory
        subtype = additionalInfo.get(key: SUBTYPE)
        osmEditingEnabled = OAPluginsHelper.isEnabled(OAOsmEditingPlugin.self)
    }

    func buildInternal() -> [OAAmenityInfoRow] {
        initVariables()
        var infoRows = [OAAmenityInfoRow]()
        var descriptions = [OAAmenityInfoRow]()

        let entries = additionalInfo.getVisibleTags(allowNoteTag: osmEditingEnabled,
                                                    preferredLangs: LocaleHelper.getPreferredLangCandidates(),
                                                    genericRowKeys: genericRowKeys)
        for case let entry as AmenityTagEntry in entries {
            guard let row = buildRow(entry) else { continue }
            if entry.isDescription {
                descriptions.append(row)
            } else {
                infoRows.append(row)
            }
        }

        sortInfoRows(&infoRows)
        sortDescriptionRows(&descriptions)
        var resultRows = infoRows + descriptions

        if let osmPlugin = OAPluginsHelper.getPlugin(OAOsmEditingPlugin.self) as? OAOsmEditingPlugin, osmPlugin.isEnabled() {
            if let info = buildWikiDataRow() {
                resultRows.append(info)
            }
        }

        return resultRows
    }

    private func buildRow(_ entry: AmenityTagEntry) -> OAAmenityInfoRow? {
        if entry.collapsableEntryType == AmenityTagEntry.CollapsableEntryType.poiTypeGroup {
            return buildPoiTypeGroupRow(entry)
        }
        // names are shown by buildNamesRow
        let baseKey = entry.key.components(separatedBy: ":")[0]
        guard baseKey != POI_NAME && !kNameTagPrefixes.contains(baseKey), let value = entry.value else { return nil }
        if let localizations = entry.collapsableEntries, !localizations.isEmpty {
            return buildLocalizedRow(entry, value: value, localizations: localizations)
        }
        return createPoiAdditionalInfoRow(key: entry.key, value: value, resolvedType: entry.resolvedType, collapsableView: nil)
    }

    private func buildPoiTypeGroupRow(_ entry: AmenityTagEntry) -> OAAmenityInfoRow? {
        let categoryTypes: [OAPOIType] = (entry.collapsablePoiTypes ?? []).compactMap { type in
            entry.poiAdditional
                ? helper.getAnyPoiAdditionalType(byKey: type.getKeyName()) as? OAPOIType
                : helper.getAnyPoiType(byKey: type.getKeyName())
        }
        guard let pType = categoryTypes.first else { return nil }
        let text = categoryTypes.map { $0.nameLocalized }.joined(separator: " • ")
        let collapsableView = getPoiTypeCollapsableView(collapsed: true, categoryTypes: categoryTypes, poiAdditional: entry.poiAdditional, type: poiCategory)

        if entry.poiAdditional {
            var icon: UIImage?
            let poiAdditionalCategoryName = pType.poiAdditionalCategory
            if let poiAdditionalIconName = helper.getPoiAdditionalCategoryIcon(poiAdditionalCategoryName) {
                icon = getRowIcon(poiAdditionalIconName)
            }
            if icon == nil, let poiAdditionalCategoryName {
                icon = getRowIcon(poiAdditionalCategoryName)
            }
            if icon == nil, let typeIconKeyName = pType.iconName() {
                icon = getRowIcon(typeIconKeyName)
            }
            if icon == nil {
                icon = .icDescription
            }
            let row = OAAmenityInfoRow(key: entry.key, icon: icon, textPrefix: pType.poiAdditionalCategoryLocalized, text: text, hiddenUrl: nil, collapsableView: collapsableView, textColor: nil, isWiki: false, isText: true, needLinks: true, isPhoneNumber: false, isUrl: false, order: Int(entry.order), name: pType.name, matchWidthDivider: false, textLinesLimit: 1)
            row.collapsed = collapsableView?.collapsed ?? true
            return row
        }

        guard let category = pType.category else { return nil }
        let row = OAAmenityInfoRow(key: category.name, icon: getRowIcon(category.iconName()), textPrefix: category.nameLocalized, text: text, hiddenUrl: nil, collapsableView: collapsableView, textColor: nil, isWiki: false, isText: true, needLinks: true, isPhoneNumber: false, isUrl: false, order: Int(entry.order), name: category.name, matchWidthDivider: false, textLinesLimit: 1)
        row.collapsed = true
        return row
    }

    private func buildLocalizedRow(_ entry: AmenityTagEntry, value: String, localizations: [AmenityTagEntry]) -> OAAmenityInfoRow? {
        var infoRows = [OAAmenityInfoRow]()
        for localization in localizations {
            guard let localizedValue = localization.value, !localizedValue.isEmpty else { continue }
            let resolvedType = additionalInfo.resolvePoiType(category: sharedPoiCategory, key: localization.key, vl: localizedValue)
            if let infoRow = createPoiAdditionalInfoRow(key: localization.key, value: localizedValue, resolvedType: resolvedType, collapsableView: nil) {
                infoRows.append(infoRow)
            }
        }
        sortInfoRows(&infoRows)
        let collapsableContent = infoRows.map { $0.textPrefix + ": " + $0.text }.joined(separator: "\n\n")
        let collapsableView = OACollapsableLabelView(text: collapsableContent, collapsed: true)
        return createPoiAdditionalInfoRow(key: entry.key, value: value, resolvedType: entry.resolvedType, collapsableView: collapsableView)
    }

    func buildWikiDataRow() -> OAAmenityInfoRow? {
        if let value = additionalInfo.get(key: WIKIDATA_TAG) {
            let url = Self.getSocialMediaUrl(key: WIKIDATA_TAG, value: value)
            if let pType = OAPOIHelper.sharedInstance().getAnyPoiAdditionalType(byKey: WIKIDATA_TAG) as? OAPOIType {
                let rowInfo = OAAmenityInfoRow(key: WIKIDATA_TAG, icon: UIImage.templateImageNamed("ic_custom_wikipedia"), textPrefix: pType.nameLocalized, text: value, hiddenUrl: url, collapsableView: nil, textColor: nil, isWiki: false, isText: true, needLinks: true, isPhoneNumber: false, isUrl: true, order: Int(pType.order), name: pType.name, matchWidthDivider: matchWidthDivider, textLinesLimit: 1)
                return rowInfo
            }
        }
        return nil
    }

    private func sortInfoRows(_ infoRows: inout [OAAmenityInfoRow]) {
        infoRows.sort { (row1: OAAmenityInfoRow, row2: OAAmenityInfoRow) -> Bool in
            if row1.order != row2.order {
                return row1.order < row2.order
            }
            return row1.typeName.localizedCompare(row2.typeName) == .orderedAscending
        }
    }

    private func sortDescriptionRows(_ descriptions: inout [OAAmenityInfoRow]) {
        let langSuffix = ":" + getPreferredMapAppLang()
        var descInPrefLang: OAAmenityInfoRow?
        for desc in descriptions {
            if desc.key.length > langSuffix.length && desc.key.hasSuffix(langSuffix) {
                descInPrefLang = desc
                break
            }
        }

        if let descInPrefLang {
            if let index = descriptions.firstIndex(of: descInPrefLang) {
                descriptions.remove(at: index)
                descriptions.insert(descInPrefLang, at: 0)
            }
        }
    }

    func getPreferredMapAppLang() -> String {
        let lang = OAAppSettings.sharedManager().settingPrefMapLanguage.get()
        return lang.isEmpty ? "en" : lang
    }

    static func getSocialMediaUrl(key: String, value: String) -> String? {
        // Remove leading and closing slashes
        let value = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.isEmpty {
            return nil
        }

        var sb = value
        if sb.first == "/" {
            sb.removeFirst()
        }
        if sb.last == "/" {
            sb.removeLast()
        }

        // It cannot be username
        if isWebUrlLike(sb) {
            return "https://\(sb)"
        }

        var urls: [String: String] = [:]
        urls["facebook"] = "https://facebook.com/%@"
        urls["vk"] = "https://vk.com/%@"
        urls["instagram"] = "https://instagram.com/%@"
        urls["twitter"] = "https://x.com/%@"
        urls["ok"] = "https://ok.ru/%@"
        urls["telegram"] = "https://t.me/%@"
        urls["flickr"] = "https://flickr.com/%@"
        urls["wikidata"] = WikiAlgorithms.wikidataBaseUrl + "%@"

        if let url = urls[key] {
            return String(format: url, value)
        }
        return nil
    }

    private static func isWebUrlLike(_ value: String) -> Bool {
        // java: PatternsCompat.AUTOLINK_WEB_URL()
        OAUtilities.isValidURL(value)
    }

    private func createPoiAdditionalInfoRow(key: String, value: String, resolvedType: AdditionalInfoBundle.ResolvedPoiType?,
                                            collapsableView: OACollapsableView?) -> OAAmenityInfoRow? {
        let cleanValue = value.replacingNbsp()
        let rowParamsBuilder = AmenityInfoRowParams.Builder(key: key)
        rowParamsBuilder.collapsableView = collapsableView
        let poiAdditionalUiRule = PoiAdditionalUiRules.shared.findRule(key: key)

        if let additionalType = resolvedType?.additionalType,
           let pType = helper.getAnyPoiAdditionalType(byKey: additionalType.getKeyName()) as? OAPOIType {
            poiAdditionalUiRule.apply(builder: rowParamsBuilder, poiType: pType, key: key, value: cleanValue, subtype: subtype)
        } else {
            let useGenericFallback = genericRowKeys.contains(key)
            let displayKey = useGenericFallback ? Self.genericFallbackDisplayKey(key) : key
            let fallbackType: OAPOIType? = OAPOIType(name: displayKey, category: poiCategory)
            guard let fallbackType else { return nil }
            fallbackType.isText = true
            fallbackType.order = 90 // the order OAPOIParser gives a type without one
            fallbackType.nameLocalized = helper.getPhraseByName(displayKey, withDefatultValue: false)
                ?? OAUtilities.capitalizeFirstLetter(displayKey.replacingOccurrences(of: "_", with: " "))
            // a custom GPX value is user data: show it as stored, do not translate it as a POI key
            let displayValue = useGenericFallback ? cleanValue : helper.translation(cleanValue, withDefault: false) ?? cleanValue
            poiAdditionalUiRule.apply(builder: rowParamsBuilder, poiType: fallbackType, key: key, value: displayValue, subtype: subtype)
            if useGenericFallback {
                rowParamsBuilder.iconName = Self.defaultAmenityIconName
            }
        }
        rowParamsBuilder.matchWidthDivider = !rowParamsBuilder.isDescription() && rowParamsBuilder.isWiki

        let param = rowParamsBuilder.build()
        let iconName = param.iconName ?? "ic_custom_info_outlined"
        let icon = OAUtilities.getMxIcon(iconName) ?? UIImage.templateImageNamed(iconName)

        let result = OAAmenityInfoRow(key: param.key, icon: icon, textPrefix: param.textPrefix, text: param.text, hiddenUrl: param.hiddenUrl, collapsableView: param.collapsableView, textColor: param.textColor, isWiki: param.isWiki, isText: param.isText, needLinks: param.needLinks, isPhoneNumber: param.isPhoneNumber, isUrl: param.isUrl, order: param.order, name: param.name, matchWidthDivider: param.matchWidthDivider, textLinesLimit: Int32(param.textLinesLimit))
        result.collapsed = true

        return result
    }

    private static func genericFallbackDisplayKey(_ key: String) -> String {
        guard let colon = key.firstIndex(of: ":"), colon > key.startIndex else { return key }
        return String(key[key.index(after: colon)...])
    }

    func buildNamesRow(name: String) -> OAAmenityInfoRow? {
        // android here creates collapsable view with all translations. ios opens a new screen with translations instead.
        // implementaion: OAPOIViewContoller.buildNamesRow() and OATargetInfoViewController.showPOITagsDetails()

        return OAAmenityInfoRow(key: Self.NAMES_ROW_KEY, icon: UIImage.templateImageNamed("ic_custom_map_languge"), textPrefix:  localizedString("shared_string_name"), text: name, hiddenUrl: nil, collapsableView: nil, textColor: nil, isWiki: false, isText: true, needLinks: false, isPhoneNumber: false, isUrl: false, order: 18000, name: "names", matchWidthDivider: matchWidthDivider, textLinesLimit: 1)
    }

    private func getPoiTypeCollapsableView(collapsed: Bool, categoryTypes: [OAPOIType], poiAdditional: Bool, type: OAPOICategory?) -> OACollapsableView? {
        let collapsableView = OACollapsableNearestPoiTypeView(defaultParameters: true)
        collapsableView?.setData(categoryTypes, amenityPoiCategory: type, lat: latLon.latitude, lon: latLon.longitude, isPoiAdditional: poiAdditional, textRow: nil)
        return collapsableView
    }

    static func collectAvailableLocalesFromTags(_ tags: [String]) -> Set<String> {
        var result: Set<String> = []
        for tag in tags {
            let parts = tag.split(separator: ":")
            let locale = parts.count > 1 ? String(parts[1]) : "en"
            if !locale.isEmpty {
                result.insert(locale)
            }
        }
        return result
    }

    static func getDescriptionWithPreferredLang(amenity: OAPOI, key: String, map: [String: Any]) -> NullablePair? {
        if let descriptions = map[key] as? [String: Any] {
            if let localizations = descriptions["localizations"] as? [String: String] {
                let locales = AmenityUIHelper.collectAvailableLocalesFromTags(Array(localizations.keys))

                let locale = LocaleHelper.getPreferredNameLocale(Array(locales))
                var localeKey = key
                if let locale {
                    localeKey = "\(key):\(locale)"
                }

                var description = localizations[localeKey]
                if description == nil && locale != nil && locale == "en" {
                    description = localizations[key]
                }

                return description != nil ? NullablePair(description, locale) : nil
            }
        }

        if let description = amenity.getAdditionalInfo(key), !description.isEmpty {
            return NullablePair(description, nil)
        }

        return nil
    }

    private func getRowIcon(_ name: String) -> UIImage? {
        let iconName = name.hasPrefix("mx_") ? name : "mx_" + name
        return OATargetInfoViewController.getIcon(iconName, size: CGSize(width: 20, height: 20))
    }
}

private extension String {
    func replacingNbsp() -> String {
        replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "\u{00a0}", with: " ")
    }
}
