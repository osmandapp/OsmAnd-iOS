#!/usr/bin/env swift
//
//  main.swift
//  addTranslation
//
//  Created by igor on 13.01.2020.
//  Copyright © 2020 igor. All rights reserved.
//

import Foundation

///For debug set  true.
let DEBUG = false

///For logging translation list set  true.
let LOGGING = false

///For debug set here your Osmand repositories path
let DEBUG_OSMAND_REPOSITORIES_PATH = "/Users/nnngrach/Documents/OsmAnd"

///For quick debugging you can write interesting key only in this var.
let DEBUG_STOP_KEY = "empty_purchases_description"

///For turning off updating translations. In this mode scrip will only delete trash strings
let DEBUG_STOP_UPDATING_TRANSLATIONS = false

// same translation are guessed (lots of errors - false positives "stop" != "stop" in some translations!)
let IOS_GUESS_KEYS_FROM_ANDROID_VALUES = false

// do not remove english strings to not remove translators work on weblate
let ALLOW_TO_HAVE_ENGLISH_NAMES = true

///Start really slow finding process. Deletes all strings with equals keys and values.
///Usialy there are duplicates like "map_locale" = "Map Language";
///But sometimes it cal delete correct loalization like "shared_string_done" = "Готово"; for ru, bel, uk languages.
///So this is risky method. Use Git Diff for manually check and rever all non-english deleting.
let DEBUG_RUN_SLOW_DUPLICATES_DELETING = false   // Danger mode

// For non-latin languages (Korean, Arabic, etc) just remove every english-only string. It's usuallu just a duplicate like "GPX", "GPS", etc
// Upd: this cleaning is already done. Maybe we don't need to run it much more.
let DEBUG_DELETE_ALL_LATIN_ONLY_STRINGS_FROM_NONLATIN_LANGS = false

let iosEnglishKey = "en"

let androidEnglishKey = ""

var languageDict = [
    "af" : "af",                // Afrikaans
    "an" : "an",                // Dutch
    "ar" : "ar",                // Arabic
    "ars" : "ars",              // Arabic, Najdi
    "ast" : "ast",              // Asturian
    "az" : "az",                // Azerbaijani
    "be" : "be",                // Belarusian
    "bg" : "bg",                // Bulgarian
    "bn" : "bn",                // Bangla
    "br" : "br",                // Breton
    "bs" : "bs",                // Bosnian
    "ca" : "ca",                // Catalan
    "ckb" : "ckb",              // Kurdish, Sorani
    "cs" : "cs",                // Czech
    "cy" : "cy",                // Welsh
    "da" : "da",                // Danish
    "de" : "de",                // German
    "el" : "el",                // Greek
    "en-GB" : "en-rGB",         // English (United Kingdom)
    "eo" : "eo",                // Esperanto
    "es" : "es",                // Spanish
    "es-AR" : "es-rAR",         // Spanish (Argentina)
    "es-US" : "es-rUS",         // Spanish (United States)
    "et" : "et",                // Estonian
    "eu" : "eu",                // Basque
    "fa" : "fa",                // Persian
    "fi" : "fi",                // Finnish
    "fr" : "fr",                // French
    "gl" : "gl",                // Galician
    "he" : "iw",                // Hebrew
    "hi" : "hi",                // Hindi
    "hr" : "hr",                // Croatian
    "hsb" : "b+hsb",            // Upper Sorbian
    "hu" : "hu",                // Hungarian
    "hy" : "hy",                // Armenian
    "ia" : "ia",                // Interlingua
    "id" : "in",                // Indonesian
    "is" : "is",                // Icelandic
    "it" : "it",                // Italian
    "ja" : "ja",                // Japanese
    "ka" : "ka",                // Georgian
    "kab" : "b+kab",            // Kabyle
    "kn" : "kn",                // Kannada
    "ko" : "ko",                // Korean
    "ku" : "ku",                // Kurdish
    "lt" : "lt",                // Lithuanian
    "lv" : "lv",                // Latvian
    "mk" : "mk",                // Macedonian
    "ml" : "ml",                // Malayalam
    "mn" : "mn",                // Mongolian
    "mr" : "mr",                // Marathi
    "my" : "my",                // Burmese
    "nb" : "nb",                // Norwegian Bokmål
    "nl" : "nl",                // Dutch
    "nn" : "nn",                // Norwegian Nynorsk
    "oc" : "oc",                // Occitan
    "pa-Arab-PK" : "pa-rPK",    // Punjabi (Naskh, Pakistan)
    "pl" : "pl",                // Polish
    "pt" : "pt",                // Portuguese
    "pt-BR" : "pt-rBR",         // Portuguese (Brasil)
    "ro-RO" : "ro",             // Romanian (Romania)
    "ru" : "ru",                // Russian
    "sat" : "sat",              // Santali
    "sc" : "sc",                // Sardinian
    "sk" : "sk",                // Slovak
    "sl" : "sl",                // Slovenian
    "sq" : "sq",                // Albanian
    "sr" : "sr",                // Serbian
    "sr-Latn" : "b+sr+Latn",    // Serbian (Latin)
    "sv" : "sv",                // Swedish
    "ta" : "ta",                // Tamil
    "te" : "te",                // Telugu
    "tr" : "tr",                // Turkish
    "tt" : "tt",                // Tatar
    "tzm" : "tzm",              // Central Atlas Tamazingh
    "uk" : "uk",                // Ukrainian
    "ur" : "ur",                // Urdu
    "uz-Cyrl" : "uz",           // Uzbek (Cyrillic)
    "vi" : "vi",                // Vietnamese
    "zh-Hans" : "zh-rCN",       // Chinese Simplified
    "zh-Hant" : "zh-rTW",       // Chinese Traditional
]

// For quick debug just comment out all unnecessary languages. Like this
// languageDict = [
//     "ast" : "ast",
//     "uk" : "uk",
// ]

let removeLatinOnlyStringsForLanguages = [
    "ar",
    "ars",
    "be",
    "ckb",
    "fa",
    "he",
    "hi",
    "hy",
    "ja",
    "ka",
    "kn",
    "ko",
    "ml",
    "mr",
    "my",
    "ru",
    "sat",
    "ta",
    "te",
    "uk",
    "zh-Hans",
    "zh-Hant"
]


// MARK: - Main

class Main {
    
    static func run(_ arguments: [String]) {
        print("START: add_translations script \n")
        let path = getOsmandRepositoriesPath()
        if !DEBUG {
            // updateGitRepositories(path)
            copyPhrasesFiles(path)
        }
        System.changeDir(path.appendingPathComponent("ios/").path)
        IOSWriter.syncTranslations()
        print("DONE: add_translations script \n")
    }
    
    
    static func getOsmandRepositoriesPath() -> URL {
        var path: URL? = nil
        if (DEBUG) {
            path = URL(fileURLWithPath: DEBUG_OSMAND_REPOSITORIES_PATH, isDirectory: true)
            print("INFO: osmandRepositoriesFolder: ", path!, "\n")
        } else {
            // ..OsmAnd/ios/Scripts/add_translations.swift
            let scriptFilePath = URL(fileURLWithPath: CommandLine.arguments[0], isDirectory: false)
            // ..OsmAnd/
            path = scriptFilePath.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        }
        return path!
    }
    
    
    static private func updateGitRepositories(_ osmandRepositoriesFolder: URL) {
        //Updating repositories to avoid Weblate merge conflicts
        print("Update git repositores...")
        
        System.changeDir(osmandRepositoriesFolder.appendingPathComponent("android/").path)
        System.runShell("git pull")

        System.changeDir(osmandRepositoriesFolder.appendingPathComponent("ios/").path)
        System.runShell("git pull")

        System.changeDir(osmandRepositoriesFolder.appendingPathComponent("resources/").path)
        System.runShell("git pull")
    }
    
    
    static private func copyPhrasesFiles(_ osmandRepositoriesFolder: URL) {
        //Don't commit this changes by script to avoid merge conflicts.
        //Do a manual commit of Resources repo on new app version build.
        System.changeDir(osmandRepositoriesFolder.appendingPathComponent("resources/poi").path)
        System.runShell("./copy_phrases.sh")
    }
    
    static func pringDebugLog(prefix: String, iosKey: String, iosValue: String, androidKey: String, androidValue: String) {
        
        if (LOGGING) {
            print("#### " + prefix + ":   ios key       :  " + iosKey)
            print("#### " + prefix + ":   ios value     :  " + iosValue)
            print("#### " + prefix + ":   android key   :  " + androidKey)
            print("#### " + prefix + ":   android value :  " + androidValue)
            print("#### " + prefix + ":   ===========================================================================================")
        }
    }
    
}


// MARK: - IOSReader

class IOSReader {
    
    static func parseTranslationFile(language: String) -> [String : String] {
        var iosDict: [String:String] = [:]
        let url = URL(fileURLWithPath: Main.getOsmandRepositoriesPath().path + "/ios/Resources/Localizations/" + language + ".lproj/Localizable.strings")
        guard let dict = NSDictionary(contentsOf: url) else { return iosDict }
        iosDict = dict as! [String : String]
        return iosDict
    }

    static func makeOutputString(str1: String, str2: String) -> String {
        var str2 = str2;
        var i = 0
        while i < str2.count {
            let index = str2.index(str2.startIndex, offsetBy: i)
            if str2[index] == "\\" {
                i += 2
            }
            else if str2[index] == "\"" {
                str2.remove(at: index)
            }
            else {
                i += 1
            }
        }
        return "\"" + str1 + "\" = \"" + str2 + "\";"
    }
    
    static func replacePlaceholders(androidDict: [String : String]) -> [String : String] {
        var updatedDict = androidDict
        for elem in updatedDict {
            if DEBUG && elem.key == DEBUG_STOP_KEY {
                if LOGGING {
                    print("#### DEBUG_STOP_KEY #### ")
                }
            }
            var modString = elem.value;
            modString = modString.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            
            for i in 1 ..< 10 {
                let pattern = "%" + String(i) + "$"
                modString = modString.replacingOccurrences(of: pattern, with: "%")
            }
            
            modString = modString.replacingOccurrences(of: "%s", with: "%@")
            modString = modString.replacingOccurrences(of: "%tF", with: "%@")
            modString = modString.replacingOccurrences(of: "%tT", with: "%@")
            
            updatedDict.updateValue(modString, forKey: elem.key)
        }
        return updatedDict
    }
    
}
 

// MARK: - IOSWriter

class IOSWriter {
    
    static var jointEnAndroidIosDict: [String:String]?
    static var commonValuesDict: [String:[String]] = [:] // IOS_GUESS_KEYS_FROM_ANDROID_VALUES - to delete?
    
    static func syncTranslations() {
        let iosEnglishDict = IOSReader.parseTranslationFile(language: iosEnglishKey)
        let androidEnglishDictOrig = AndroidReader.parseTranslationFile(language: androidEnglishKey)
        let androidEnglishDict = IOSReader.replacePlaceholders(androidDict: androidEnglishDictOrig)
        jointEnAndroidIosDict = joinDictionariesWithSameKeyValue(iosDict: iosEnglishDict, androidDict: androidEnglishDict)
        
        print("TRANSLATING: English at \(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .medium))")
        generateNewTranslation(language: iosEnglishKey, iosDict: iosEnglishDict, androidDict: androidEnglishDict, iosEnglishDict: [:])

        for language in languageDict {
            print("\nTranslating: \(language.key) at \(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .medium))")
            let iosDict = IOSReader.parseTranslationFile(language: language.key)
            let androidDict = AndroidReader.parseTranslationFile(language: language.key)
            generateNewTranslation(language: language.key, iosDict: iosDict, androidDict: androidDict, iosEnglishDict: iosEnglishDict)
        }
    }

    static func joinDictionariesWithSameKeyValue(iosDict: [String : String], androidDict: [String : String]) -> [String:String] {
        let androidDict = IOSReader.replacePlaceholders(androidDict: androidDict)
        var commonTranslations: Dictionary = [String:String]()
        for iosTranslation in iosDict {
            if let androidTranslationValue = androidDict[iosTranslation.key] {
                commonTranslations[iosTranslation.key] = iosTranslation.value
                // if iosTranslation.value != androidTranslationValue {
                //     print("Values EN    are different \(iosTranslation.key) '\(androidTranslationValue)' (android) != \(iosTranslation.value) (ios) ")
                // }
                Main.pringDebugLog(prefix: "FOUND", iosKey: iosTranslation.key, iosValue: iosTranslation.value, androidKey: iosTranslation.key, androidValue: androidTranslationValue)
            } else if IOS_GUESS_KEYS_FROM_ANDROID_VALUES {
                /// iosKey != androidKey.
                /// find androidKey where iosEnValue == androidEnValue
                var keys: [String] = []
                if androidDict.values.contains(iosTranslation.value) {
                    keys = (androidDict as NSDictionary).allKeys(for: iosTranslation.value) as! [String]
                    commonValuesDict[iosTranslation.key] = keys
                    Main.pringDebugLog(prefix: "GUESSED", iosKey: iosTranslation.key, iosValue: iosTranslation.value, androidKey: keys.first!, androidValue: androidDict[keys.first!]!)
                }
                else if iosTranslation.value.last == "." && androidDict.values.contains(String(iosTranslation.value.dropLast())) {
                    keys = (androidDict as NSDictionary).allKeys(for: String(iosTranslation.value.dropLast())) as! [String]
                    commonValuesDict[iosTranslation.key] = keys
                    Main.pringDebugLog(prefix: "GUESSED", iosKey: iosTranslation.key, iosValue: iosTranslation.value, androidKey: keys.first!, androidValue: androidDict[keys.first!]!)
                } else {
                    Main.pringDebugLog(prefix: "NOT_FOUND", iosKey: iosTranslation.key, iosValue: iosTranslation.value, androidKey: "", androidValue: "")
                }
            }
        }
        for key in androidDict.keys {
            if var value = androidDict[key] {
                value = value.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                if key.hasPrefix("routeInfo_") || key.hasPrefix("routing_attr_") || key.hasPrefix("rendering_attr_") || key.hasPrefix("rendering_value_") {
                    commonTranslations[key] = value
                }
            }
        }
        return commonTranslations
    }
    
    static func equaslWithoutDots(str1: String, str2: String) -> Bool {
        if (str1.last == "." && str1.dropLast() == str2) || (str2.last == "." && str2.dropLast() == str1) {
            return true
        }
        return false
    }
    
    static func isStringEnglishOnly(_ text: String?) -> Bool {
        if let text {
            let transliteredText = text.applyingTransform(.toLatin, reverse: false)
            return text == transliteredText
        }
        return false
    }
    
    private static func isEnglishDuplicateInLocalFile(_ iosEnglishDict : [String : String], _ language: String, _ key: String, _ androidValue: String) -> Bool {
        let androidTrimmedValue = androidValue.replacingOccurrences(of: "\\", with: "")
        let iosEnglishTrimmedValue = (iosEnglishDict[key] ?? "").replacingOccurrences(of: "\\", with: "")
        return language != iosEnglishKey && androidTrimmedValue == iosEnglishTrimmedValue
    }
    

    static func isDuplicateEnString(key: String, currentValue: String?, newValue: String?, language: String, iosEnglishDict: [String: String]) -> Bool {
        // Remove strings identical to the same string in english file - trash duplicates.
        if let englishValue = iosEnglishDict[key], language != iosEnglishKey {
            // Check new value
            if let newValue, newValue == englishValue {
                return true
            }
            // Check current value
            let trimmedEnglishValue = englishValue.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            if currentValue == trimmedEnglishValue {
                return true
            }
        }
        // For non-latin languages (Korean, Arabic, etc) just remove every english-only string. It's usually just a duplicate like "GPX", "GPS", etc
        if DEBUG_DELETE_ALL_LATIN_ONLY_STRINGS_FROM_NONLATIN_LANGS && removeLatinOnlyStringsForLanguages.contains(language) && isStringEnglishOnly(newValue ?? "") { // Assuming newValue should be used here
            return true
        }
        return false
    }
    
    static func writeToFile(strings: [String], fileURL: URL) {
        // build a new Localizable.strings file
        var newFileContent = ""
        for string in strings {
            let trim = string.trimmingCharacters(in: .whitespaces)
            if trim.hasPrefix("//") || trim == "" {
                newFileContent += string + "\n"
            } else {
                newFileContent += string + ";\n"
            }
        }
        do {
            try newFileContent.write(to: fileURL, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            print ("error writing file: \(error)")
        }
    }

    static func readFileToStrings(_ filePath: String) -> [String] {
        var processedStrings = [String]()
        do {
            let fileContent = try String(contentsOfFile: filePath, encoding: .utf8)
            let strings = fileContent.components(separatedBy: ";\n")
            // split by comments lines
            for string in strings {
                var line = string
                while line.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("//") {
                    if let index = line.firstIndex(of: "\n") {
                        processedStrings.append(String(line[..<index]) )
                        line = String(line[line.index(after: index)...])
                    } else {
                        processedStrings.append(line)
                        line = "" // No more content after the first line
                    }
                }
                if !line.isEmpty {
                    processedStrings.append(line)
                }
            }
        } catch {
            print ("error reading file: \(error) \(filePath)")
        }
        return processedStrings;
    }
    
    static func extractKey(_ string: String) -> String {
        if string.trimmingCharacters(in: .whitespaces).hasPrefix("//") {
            return ""
        } else {
            // Split the string into key and value components using the "=" delimiter
            let components = string.split(separator: "=", maxSplits: 1).map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            var key = ""
            if components.count > 1 {
                key = components[0].trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            }
            if key.isEmpty && string.trimmingCharacters(in: .whitespaces) != "" {
                print("Missing key \(string) ")
            }
            return key
        }
    }

    static func generateNewTranslation(language: String, iosDict: [String : String], androidDict: [String : String], iosEnglishDict: [String : String]) {
        let androidDict = IOSReader.replacePlaceholders(androidDict: androidDict)
        if DEBUG {
            print("Making dictionary '\(language)' at \(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .medium))")
        }
        var keysToAdd: [String:String] = [:]
        var keysToUpdate: [String:String] = [:]

        for elem in jointEnAndroidIosDict! {
            if androidDict.keys.contains(elem.key) {
                // Update from localized android dict
                guard let androidValue = androidDict[elem.key] else { continue }
                guard valueHasNoPlaceholders(value: androidValue) else { continue }
                guard !isEnglishDuplicateInLocalFile(iosEnglishDict, language, elem.key, androidValue) else { continue }
                if iosDict.keys.contains(elem.key) {
                    keysToUpdate.updateValue(androidValue, forKey: elem.key)
                } else {
                    keysToAdd.updateValue(androidValue, forKey: elem.key)
                }
            }
        }
        
        if IOS_GUESS_KEYS_FROM_ANDROID_VALUES {
            for elem in commonValuesDict {
                if let androidKey = AndroidReader.dictContainsKeys(androidDict: androidDict, keys: [elem.key]) {
                    guard let androidValue = androidDict[androidKey] else { continue }
                    guard valueHasNoPlaceholders(value: androidValue) else { continue }
                    guard !isEnglishDuplicateInLocalFile(iosEnglishDict, language, elem.key, androidValue) else { continue }
                    if iosDict.keys.contains(elem.key) {
                        if androidValue != iosDict[elem.key] {
                            keysToUpdate.updateValue(androidValue, forKey: elem.key)
                        }
                    } else if iosEnglishDict[elem.key] != androidValue {
                        keysToAdd.updateValue(androidValue, forKey: elem.key)
                    }
                }
            }
        }

        if DEBUG {
            print("Updating lines '\(language)' at \(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .medium))")
        }
        var updatedStringsCount = 0;
        if keysToUpdate.count > 0 || keysToAdd.count > 0 {
            // First, we populate the keyOccurrences with the keys from iosDict, initializing their counts to 0.
            var keyOccurrences = [String: Int]()
            iosDict.keys.forEach { keyOccurrences[$0] = 0 }
            // 1. Read file to strings
            let filePath = Main.getOsmandRepositoriesPath().path + "/ios/Resources/Localizations/" + language + ".lproj/Localizable.strings"
            let fileURL = URL(fileURLWithPath: filePath)
            let readStrings = readFileToStrings(filePath)
            //  2. Update existing keys
            var updatedStrings = [String]()
            for string in readStrings {
                let key = extractKey(string)
                if key.isEmpty {
                    // keep line as it is
                    updatedStrings.append(string)
                    continue
                }
                let currentValue = iosDict[key] ?? ""
                keyOccurrences[key, default: 0] += 1
                if keyOccurrences[key]! > 1 {
                    print("Error removing duplicate key ! \(string) ")
                    continue
                }
                var newString = string
                var newValue = currentValue
                if let androidValue = keysToUpdate[key], let updatedString = replaceValueText(newValue: filterUnsafeChars(androidValue), inFullString: string),
                            updatedString != string  {
                    updatedStringsCount += 1
                    newValue = androidValue
                    newString = updatedString
                    // print("Update key ! \(string)  \(currentValue) -> \(androidValue)?? ")
                }
                
                if ALLOW_TO_HAVE_ENGLISH_NAMES ||
                        !self.isDuplicateEnString(key: key, currentValue: currentValue, newValue: newValue, language: language, iosEnglishDict: iosEnglishDict) {
                    updatedStrings.append(newString);
                }
            }
            // 3. Add new translations
            for elem in keysToAdd {
                // if keyOccurrences[elem.key]! < 1 {
                let newValue = filterUnsafeChars(elem.value)
                if !self.isDuplicateEnString(key: elem.key, currentValue: newValue, newValue: newValue, language: language, iosEnglishDict: iosEnglishDict) {
                    updatedStrings.append("\"" + elem.key + "\" = \"" + filterUnsafeChars(elem.value) + "\"")
                }
                // }
            }
            // 4. write to file
            if !DEBUG_STOP_UPDATING_TRANSLATIONS {
                writeToFile(strings: updatedStrings, fileURL: fileURL);
            }
        }
        print("\(language) added: \(keysToAdd.count) updated: \(updatedStringsCount)")
    }
    
    static func replaceValueText(newValue: String, inFullString fullString: String) -> String? {
        /// Localzable.strings  one string format:
        /// "key" = "value";
        ///
        ///
        
        let quotationMarkIndexes = getAllSubstringIndexes(fullString: fullString, subString: "\"")
        if (quotationMarkIndexes.count >= 4) {
            let startIndex = fullString.index(fullString.startIndex, offsetBy: quotationMarkIndexes[2] + 1)
            let endIndex = fullString.index(fullString.startIndex, offsetBy: quotationMarkIndexes.last!)
            var resultString = fullString
            resultString.replaceSubrange(startIndex ..< endIndex, with: newValue)
            return resultString
        } else if (quotationMarkIndexes.count >= 2) {
            let key = getKey(inFullString: fullString)
            return "\"" + key + "\" = \"" + newValue + "\""
        } else {
            return nil
        }
    }
    
    
    static func getKey(inFullString fullString: String) -> String {
        let quotationMarkIndexes = getAllSubstringIndexes(fullString: fullString, subString: "\"")
        guard (quotationMarkIndexes.count >= 4) else { return fullString }
        
        let startIndex = fullString.index(fullString.startIndex, offsetBy: quotationMarkIndexes[0] + 1)
        let endIndex = fullString.index(fullString.startIndex, offsetBy: quotationMarkIndexes[1])
        return String( fullString[startIndex ..< endIndex])
    }
    
    
    static func getAllSubstringIndexes(fullString: String, subString: String) -> [Int] {
        var indexes = [Int]()
        for i in 0..<fullString.count {
            let index = fullString.index(fullString.startIndex, offsetBy: i)
            let charAtIndex = fullString[index]
            if (String(charAtIndex) == subString) {
                indexes.append(i)
            }
        }
        return indexes
    }
    
    static func valueHasNoPlaceholders(value: String) -> Bool {
        return value.count > 0 && !value.contains("$")
    }
    
    static func filterUnsafeChars(_ text: String) -> String {
        var result: String = text;
        result = result.replacingOccurrences(of: ";", with: ".")
        result = result.replacingOccurrences(of: "\n", with: " ")
        
        if result.hasPrefix("\"") && !result.hasPrefix("\\\"") {
            result = String(result.dropFirst())
            result = "\\\"" + result
        }
        if result.hasSuffix("\"") && !result.hasSuffix("\\\"") {
            result = String(result.dropLast())
            result = result + "\\\""
        }
        return result
    }
    
}


// MARK: - AndroidReader

class AndroidReader {
    
    static func parseTranslationFile(language: String) -> [String : String] {
        var langSuffix: String = language
        if language != "" {
            if let lang = languageDict[language] {
                langSuffix = "-" + lang
            }
        }
        let url = URL(fileURLWithPath: Main.getOsmandRepositoriesPath().path + "/android/OsmAnd/res/values" + langSuffix + "/strings.xml")
        let myparser = Parser()
        return myparser.myparser(path: url)
    }

    
    static func dictContainsKeys(androidDict: [String:String], keys: [String]) -> String? {
        for elem in androidDict.keys {
            for key in keys {
                if elem == key {
                    return key
                }
            }
        }
        return nil
    }
    
}


// MARK: - Parser

class Parser: NSObject, XMLParserDelegate {

    var key = String()
    var dict = [String:String]()
    var value = String()

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        if elementName == "string" {
            if let name = attributeDict["name"] {
                key = name
            }
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "string" {
            dict.updateValue(value, forKey: key)
        }
        value = ""
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let data = String(string)
        if (!data.isEmpty) {
            value += data
        }
    }

    func myparser(path: URL) -> [String:String] {

        if let parser = XMLParser(contentsOf: path) {
            parser.delegate = self
            parser.parse()
        }
        return dict
    }
}


// MARK: - System

class System {
    
    //Run Bash command without output
    static func runShell(_ command: String) {
        print( getShellOutput(command) )
    }
    
    //Run Bash command with output
    static func getShellOutput(_ command: String) -> String {
        let task = Process()
        let pipe = Pipe()
        
        task.standardOutput = pipe
        task.standardError = pipe
        task.arguments = ["-c", command]
        task.launchPath = "/bin/zsh"
        task.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)!
        
        print (output)
        return output
    }
    
    
    static func changeDir(_ argument: String) {
        var path = ""
        if argument == ".." {
            let currentFolderPath = URL(fileURLWithPath: getShellOutput("echo $PWD"), isDirectory: true)
            let parentFolder = currentFolderPath.deletingLastPathComponent()
            path = parentFolder.path
        } else {
            path = argument
        }
        
        if !path.hasPrefix("/") {
            path = "/" + path
        }
        if path.contains("\n") {
            path = path.replacingOccurrences(of: "\n", with: "")
        }
        
        FileManager.default.changeCurrentDirectoryPath(path)
        print(path)
    }
    
}



// MARK: - Script is launching here

Main.run(CommandLine.arguments)
