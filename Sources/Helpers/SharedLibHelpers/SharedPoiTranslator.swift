//
//  SharedPoiTranslator.swift
//  OsmAnd
//
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import Foundation
import OsmAndShared

/// The names of the poi types for the shared `MapPoiTypes`, out of the phrases `OAPOIHelper` reads:
/// `poi_<key>` holds the name, and the synonyms after a `;`.
///
/// As android's `MapPoiTypesTranslator`, a name that is not in the phrases is nil, and the registry
/// falls back to the key spelled out. It is built while `OAPOIHelper` itself is being made, so it is
/// handed the phrases rather than asking the helper for them.
@objcMembers
final class SharedPoiTranslator: NSObject, PoiTranslator {

    private let phrases: [String: String]
    private let enPhrases: [String: String]
    private weak var poiTypes: MapPoiTypes?

    init(phrases: [String: String]?, enPhrases: [String: String]?, poiTypes: MapPoiTypes) {
        self.phrases = phrases ?? [:]
        self.enPhrases = enPhrases ?? [:]
        self.poiTypes = poiTypes
        super.init()
    }

    func getTranslation(type: AbstractPoiType) -> String? {
        if let baseLangType = type.getBaseLangType() {
            let name = getTranslation(type: baseLangType) ?? poiTypes?.getBasePoiName(abstractPoiType: baseLangType)
            return name.map { $0 + langSuffix(type) }
        }
        return getTranslation(keyName: type.getFormattedKeyName())
    }

    func getTranslation(keyName: String) -> String? {
        Self.name(phrases["poi_" + keyName])
    }

    func getEnTranslation(type: AbstractPoiType) -> String? {
        if let baseLangType = type.getBaseLangType() {
            return getEnTranslation(type: baseLangType).map { $0 + langSuffix(type) }
        }
        return getEnTranslation(keyName: type.getFormattedKeyName())
    }

    func getEnTranslation(keyName: String) -> String? {
        Self.name(enPhrases["poi_" + keyName])
    }

    func getSynonyms(type: AbstractPoiType) -> String? {
        if let baseLangType = type.getBaseLangType() {
            return getSynonyms(type: baseLangType)
        }
        return getSynonyms(keyName: type.getFormattedKeyName())
    }

    func getSynonyms(keyName: String) -> String? {
        guard let phrase = phrases["poi_" + keyName],
              let separator = phrase.firstIndex(of: ";"),
              separator > phrase.startIndex else {
            return ""
        }
        return String(phrase[phrase.index(after: separator)...])
    }

    func getAllLanguagesTranslationSuffix() -> String? {
        localizedString("shared_string_all_languages").lowercased()
    }

    /// The names in another language, which a search adds to those of the app's language.
    func getTranslator(lang: String) -> PoiTranslator? {
        guard let langPhrases = OAPOIHelper.loadPhraseFile(forLanguage: lang), let poiTypes else {
            return nil
        }
        return SharedPoiTranslator(phrases: langPhrases, enPhrases: enPhrases, poiTypes: poiTypes)
    }

    private func langSuffix(_ type: AbstractPoiType) -> String {
        " (" + OAUtilities.translatedLangName(type.getLang() ?? "").lowercased() + ")"
    }

    // the name before the synonyms
    private static func name(_ phrase: String?) -> String? {
        guard let phrase else { return nil }
        if let separator = phrase.firstIndex(of: ";"), separator > phrase.startIndex {
            return String(phrase[..<separator])
        }
        return phrase
    }
}
