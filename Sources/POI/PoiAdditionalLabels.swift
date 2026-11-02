//
//  PoiAdditionalLabels.swift
//  OsmAnd
//
//  Copyright © 2026 OsmAnd. All rights reserved.
//

// analog in android PoiAdditionalLabels.java
// Labels of additional property values written as "Name: value" in phrases.xml ("Fridge: yes",
// "Smoking: not allowed", "Kayaks: yes"). A translation without the separator is shown as it is.

@objcMembers
final class PoiAdditionalLabels: NSObject {

    private static let yes = "yes"
    // OSM values of a property state ("smoking=no"); a value outside it is an option ("diesel", "gynaecology")
    private static let stateValues: Set<String> = [yes, "no", "only", "designated", "limited", "permissive",
                                                   "private", "customers", "destination", "unknown", "outside",
                                                   "separated", "isolated", "dedicated"]
    // states that mean the property is there
    private static let acceptedValues: Set<String> = [yes, "only", "designated"]
    private static let separator = " • "

    // [name, value] or nil if the translation is not "Name: value"
    static func splitNameValue(_ translation: String?) -> [String]? {
        guard let translation, let index = translation.firstIndex(of: ":") else { return nil }
        let name = translation[..<index].trimmingCharacters(in: .whitespacesAndNewlines)
        let value = translation[translation.index(after: index)...].trimmingCharacters(in: .whitespacesAndNewlines)
        // a name has letters: "1:25 fuel" is a value, not "1" + "25 fuel"
        return !name.contains(where: \.isLetter) || value.isEmpty ? nil : [name, value]
    }

    // Search shows and indexes an additional value unless it is a state that does not mean the property is there:
    // yes, only, designated and every option ("diesel", "gynaecology", station=subway) are taken; no, limited,
    // outside... are not.
    static func isAcceptedValue(osmValue: String?) -> Bool {
        guard let osmValue else { return true }
        return !stateValues.contains(osmValue) || acceptedValues.contains(osmValue)
    }

    static func isAcceptedValue(_ poiType: OAPOIType) -> Bool {
        isAcceptedValue(osmValue: poiType.getOsmValue())
    }

    // Name of an additional value in search, the part before ":" ("Subway station: yes" -> "Subway station").
    // The older "Yes;Subway station" gives the first synonym, a translation without a name stays as it is.
    static func getSearchName(translation: String?, enTranslation: String?, synonyms: String?, groupName: String?) -> String? {
        if let nameValue = splitNameValue(translation) {
            return nameValue[0]
        }
        if yes.caseInsensitiveCompare(enTranslation ?? "") == .orderedSame {
            if let first = synonyms?.components(separatedBy: ";").first?.trimWhitespaces(), !first.isEmpty {
                return first
            }
            if let groupName, !groupName.isEmpty {
                return groupName
            }
        }
        return translation
    }

    static func getSearchName(_ poiType: OAPOIBaseType) -> String? {
        guard let type = poiType as? OAPOIType, type.isAdditional() else { return poiType.nameLocalized }
        return getSearchName(translation: type.nameLocalized, enTranslation: type.nameLocalizedEN,
                             synonyms: OAPOIHelper.sharedInstance().getSynonymsByName(type.name), groupName: type.poiAdditionalCategoryLocalized)
    }

    static func getEnSearchName(_ poiType: OAPOIBaseType) -> String? {
        let enTranslation = poiType.nameLocalizedEN
        guard let type = poiType as? OAPOIType, type.isAdditional() else { return enTranslation }
        if let nameValue = splitNameValue(enTranslation) {
            return nameValue[0]
        }
        // the older "Yes;Name" has no English name, only the value
        return yes.caseInsensitiveCompare(enTranslation ?? "") == .orderedSame ? nil : enTranslation
    }

    // A group of one "yes" value is a single switch, not a list.
    static func isSingleYes(_ osmValues: [String]) -> Bool {
        osmValues.count == 1 && osmValues[0] == yes
    }

    // Label of the switch for a group of one "yes" value: the name, else the group name.
    static func getSwitchLabel(_ translation: String?, groupName: String?) -> String? {
        if let nameValue = splitNameValue(translation) {
            return nameValue[0]
        }
        guard let groupName, !groupName.isEmpty else { return translation }
        return groupName
    }

    // Labels of the values of one group, in the same order:
    // - all values have the same name ("Smoking: allowed", "Smoking: not allowed"): the value, "Allowed";
    // - otherwise ("Kayaks: yes", "Canoe: yes"): the name for a "yes" value whose name is not repeated in the group,
    // "Kayaks", and the whole translation for the others, "Adoption: no".
    static func getGroupLabels(_ translations: [String], osmValues: [String]) -> [String] {
        let nameValues = translations.map { splitNameValue($0) }
        var nameCounts = [String: Int]()
        for nameValue in nameValues {
            if let name = nameValue?[0].lowercased() {
                nameCounts[name, default: 0] += 1
            }
        }
        let sameName = !nameValues.isEmpty && !nameValues.contains { $0 == nil } && nameCounts.count == 1
        return translations.indices.map { i in
            guard let nameValue = nameValues[i] else { return translations[i] }
            if sameName {
                return OAUtilities.capitalizeFirstLetter(nameValue[1]) ?? nameValue[1]
            }
            if i < osmValues.count, osmValues[i] == yes, nameCounts[nameValue[0].lowercased()] == 1 {
                return nameValue[0]
            }
            return translations[i]
        }
    }

    // POI card: values of one group. Values of one property: "Smoking" over "No" or "Allowed • Outside only";
    // options of a list keep the group name (nil prefix) over "Kayaks • Canoe: limited • Cash".
    static func getCardGroupLabel(_ types: [OAPOIType]) -> (prefix: String?, text: String) {
        let nameValues = types.map { splitNameValue($0.nameLocalized) }
        if let first = types.first, let propertyName = nameValues[0]?[0], isOneTagGroup(first),
           nameValues.allSatisfy({ $0?[0].caseInsensitiveCompare(propertyName) == .orderedSame }) {
            let values = nameValues.compactMap { $0.map { OAUtilities.capitalizeFirstLetter($0[1]) ?? $0[1] } }
            return (propertyName, values.joined(separator: separator))
        }
        return (nil, types.map { getGroupValueLabel($0) }.joined(separator: separator))
    }

    // A value inside a group of several values: "Kayaks" for yes, "Kayaks: limited" otherwise, "Cash" as it is.
    static func getGroupValueLabel(_ type: OAPOIType) -> String {
        let translation = type.nameLocalized ?? ""
        guard let nameValue = splitNameValue(translation) else { return translation }
        return isYesValue(type) ? nameValue[0] : translation
    }

    // all values of the group are one tag (smoking=yes/no/outside), not a list of options (boat:kayak:rental, ...)
    private static func isOneTagGroup(_ type: OAPOIType) -> Bool {
        guard let category = type.poiAdditionalCategory, let parent = type.parentType else { return true }
        let additionals = (parent.poiAdditionals ?? []) + (parent.poiAdditionalsCategorized ?? [])
        let tags = Set(additionals.filter { $0.poiAdditionalCategory == category }.compactMap { $0.getOsmTag() })
        return tags.count <= 1
    }

    private static func isYesValue(_ type: OAPOIType) -> Bool {
        if type.getOsmValue() == yes {
            return true
        }
        let enTranslation = type.nameLocalizedEN ?? ""
        let value = splitNameValue(enTranslation)?[1] ?? enTranslation
        return yes.caseInsensitiveCompare(value) == .orderedSame
    }
}
