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
let OSMAND_REPOSITORIES_PATH = "/Users/nnngrach/Projects/Coding/OsmAnd/"

///For quick debugging you can write interesting key only in this var.
let DEBUG_STOP_KEY = "empty_purchases_description"

///For turning off updating translations. In this mode scrip will only delete trash strings
let DEBUG_STOP_UPDATING_TRANSLATIONS = false

///Start really slow finding process. Deletes all strings with equals keys and values.
///Usialy there are duplicates like "map_locale" = "Map Language";
///But sometimes it cal delete correct loalization like "shared_string_done" = "Готово"; for ru, bel, uk languages.
///So this is risky method. Use Git Diff for manually check and rever all non-english deleting.
let DEBUG_RUN_SLOW_DUPLICATES_DELETING = false   // Danger mode

// For non-latin languages (Korean, Arabic, etc) just remove every english-only string. It's usuallu just a duplicate like "GPX", "GPS", etc
// Upd: this cleaning is already done. Maybe we don't need to run it much more.
let DEBUG_DELETE_ALL_LATIN_ONLY_STRINGS_FROM_NONLATIN_LANGS = false


var iosEnglishDict: [String : String] = [:]
var androidEnglishDict: [String : String] = [:]
var androidEnglishDictOrig: [String : String] = [:]

var commonDict: [String:String]?
var commonValuesDict: [String:[String]] = [:]
var duplicatesValues: [String: String] = [:]    // it stores inverted key and values. duplicatesValues["tranlation_value"] = "tranlation_key"
var duplicatesCount = 0

let iosEnglishKey = "en"
let androidEnglishKey = ""

/// For quick debug just comment out all unnecessary languages. Like this
/*
let languageDict = [
    //"af" : "af",
    //"an" : "an",
    "ar" : "ar",
    //"ars" : "ars",
    //"ast" : "ast",
    // ...
]
*/


let languageDict = [
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

var allLanguagesDict = languageDict
allLanguagesDict["en"] = ""

func trim(string: String, from index: Int) -> String {
    return string.substring(from: string.index(string.startIndex, offsetBy: index))
}

func charFrom(string: String, at index: Int) -> String {
    let charIndex = string.index(string.startIndex, offsetBy: index)
    return String(string[charIndex])
}


// MARK: - Main

class Main {
    
    static func run(_ arguments: [String]) {
        print("START: add_translations script \n")

        let path = getOsmandRepositoriesPath()
        if !DEBUG {
            updateGitRepositories(path)
            copyPhrasesFiles(path)
        }
        
        Initialiser.initUpdatingTranslationKeyLists(path)
        addRoutingParametersIfNeeded(arguments, path)
        updateTranslations(path)
        
        print("DONE: add_translations script \n")
    }
    
    
    static func getOsmandRepositoriesPath() -> URL {
        print("RUN: Main.getOsmandRepositoriesPath() \n")
        var path: URL? = nil
        if (DEBUG) {
            path = URL(fileURLWithPath: OSMAND_REPOSITORIES_PATH, isDirectory: true)
        } else {
            // ..OsmAnd/ios/Scripts/add_translations.swift
            let scriptFilePath = URL(fileURLWithPath: CommandLine.arguments[0], isDirectory: false)
            // ..OsmAnd/
            path = scriptFilePath.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        }
        print("INFO: osmandRepositoriesFolder: ", path!, "\n")
        return path!
    }
    
    
    static private func updateGitRepositories(_ osmandRepositoriesFolder: URL) {
        //Updating repositories to avoid Weblate merge conflicts
        print("RUN: Main.updateGitRepositories() \n")
        
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
        print("RUN: Main.copyPhrasesFiles() \n")
        System.changeDir(osmandRepositoriesFolder.appendingPathComponent("resources/poi").path)
        System.runShell("./copy_phrases.sh")
    }
    
    
    static private func addRoutingParametersIfNeeded(_ arguments: [String], _ osmandRepositoriesFolder: URL) {
        guard !DEBUG_STOP_UPDATING_TRANSLATIONS else { return }
        print("RUN: Main.addRoutingParametersIfNeeded() \n")
        System.changeDir(osmandRepositoriesFolder.appendingPathComponent("ios/").path)
        //if (arguments.count == 2) && (arguments[1] == "-routing") || DEBUG {
            RoutingParamsHelper.addRoutingParams()
        //}
    }
    
    
    static private func updateTranslations(_ osmandRepositoriesFolder: URL) {
        print("RUN: Main.updateTranslations() \n")
        System.changeDir(osmandRepositoriesFolder.appendingPathComponent("ios/").path)
        IOSWriter.addTranslations()
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


// MARK: - Initialiser

class Initialiser {
    
    static func initUpdatingTranslationKeyLists(_ osmandRepositoriesFolder: URL) {
        print("RUN: initUpdatingTranslationKeyLists() \n")
        System.changeDir(osmandRepositoriesFolder.appendingPathComponent("ios/").path)
        
        iosEnglishDict = IOSReader.parseTranslationFile(language: iosEnglishKey)
        androidEnglishDictOrig = AndroidReader.parseTranslationFile(language: androidEnglishKey)
        androidEnglishDict = IOSReader.replacePlaceholders(androidDict: androidEnglishDictOrig)
        compareDicts(iosDict: iosEnglishDict, androidDict: androidEnglishDict)
    }


    static func compareDicts(iosDict: [String : String], androidDict: [String : String]){
        if LOGGING {
            print("COMPARING: ios and android base english translations \n")
        }
        
        let androidDict = IOSReader.replacePlaceholders(androidDict: androidDict)
        var commonTranslations: Dictionary = [String:String]()
        for iosTranslation in iosDict
        {
            if DEBUG && iosTranslation.key == DEBUG_STOP_KEY {
                if LOGGING {
                    print("#### DEBUG_STOP_KEY #### ")
                }
            }
            if let androidTranslationValue = androidDict[iosTranslation.key] {
                commonTranslations[iosTranslation.key] = iosTranslation.value
                 Main.pringDebugLog(prefix: "FOUND", iosKey: iosTranslation.key, iosValue: iosTranslation.value, androidKey: iosTranslation.key, androidValue: androidTranslationValue)
            }
            else {
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
        commonDict = commonTranslations
    }

    
    static func equaslWithoutDots(str1: String, str2: String) -> Bool {
        if (str1.last == "." && str1.dropLast() == str2) || (str2.last == "." && str2.dropLast() == str1) {
            return true
        }
        return false
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
    
    static func deleteDuplicates() {
    }
    
    static func addTranslations() {
        
        print("\nTRANSLATING: English at \(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .medium))\n")
        IOSWriter.makeNewDict(language: iosEnglishKey, iosDict: iosEnglishDict, androidDict: androidEnglishDict, iosEnglishDict: [:])
        
        duplicatesValues = [:]
        var parsedIosDicts: [String: [String : String]] = [:]
        var parsedAndroidDicts: [String: [String : String]] = [:]
        
        for language in languageDict {
            print("\nparsing dictionaries for lang: " + language.key)
            var iosDict = IOSReader.parseTranslationFile(language: language.key)
            let androidDict = AndroidReader.parseTranslationFile(language: language.key)
            parsedIosDicts[language.key] = iosDict
            parsedAndroidDicts[language.key] = androidDict
        }
        
        // There was meny strings, duplicated from english file. this function find it
        if DEBUG_RUN_SLOW_DUPLICATES_DELETING {
            print("\nStart slow duplicates finding")
            for languageA in languageDict {
                guard let iosDictA = parsedIosDicts[languageA.key] else { continue }
                for languageB in languageDict {
                    guard languageA != languageB else { continue }
                    guard let iosDictB = parsedIosDicts[languageB.key] else { continue }
                    print("\nFinding duplicates. " + languageA.key  + " : " + languageB.key)

                    for elemA in iosDictA {
                        if duplicatesValues.keys.contains(elemA.value) {
                            continue
                        }
                        if iosDictB[elemA.key] == elemA.value {
                            // it stores inverted key and values. duplicatesValues["tranlation_value"] = "tranlation_key"
                            duplicatesValues[elemA.value] = elemA.key
                            // print("\nFound duplicate! " + elemA.key  + " : " + elemA.value)
                        }
                    }
                    
                }
            }
        }
        
        for language in languageDict {
            print("\nTranslating: \(language.key) at \(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .medium))\n")
            guard let iosDict = parsedIosDicts[language.key] else { continue }
            guard let androidDict = parsedAndroidDicts[language.key] else { continue }
            IOSWriter.makeNewDict(language: language.key, iosDict: iosDict, androidDict: androidDict, iosEnglishDict: iosEnglishDict)
        }
    }
    
    
    static func isStringEnglishOnly(_ text: String?) -> Bool {
        if let text {
            let transliteredText = text.applyingTransform(.toLatin, reverse: false)
            return text == transliteredText
        }
        return false
    }
    
    private static func isEnglishDuplicateInLocalFile(_ language: String, _ key: String, _ androidValue: String) -> Bool {
        let androidTrimmedValue = androidValue.replacingOccurrences(of: "\\", with: "")
        let iosEnglishTrimmedValue = (iosEnglishDict[key] ?? "").replacingOccurrences(of: "\\", with: "")
        let isDuplicate = language != iosEnglishKey && androidTrimmedValue == iosEnglishTrimmedValue
        
        if DEBUG && key == DEBUG_STOP_KEY && isDuplicate {
            if LOGGING {
                print("#### DEBUG_STOP_KEY #### ")
            }
        }
        return language != iosEnglishKey && androidTrimmedValue == iosEnglishTrimmedValue
    }
    
    private static func isDuplicatedValueInSeveralLanguages(_ key: String, _ value: String) -> Bool {
        if duplicatesValues.keys.contains(value) {
            let keyOfFoundedDuplicate = duplicatesValues[value]
            if key == keyOfFoundedDuplicate {
                return true
            }
        }
        return false
    }
    
    static func makeNewDict(language: String, iosDict: [String : String], androidDict: [String : String], iosEnglishDict: [String : String]) {
        let androidDict = IOSReader.replacePlaceholders(androidDict: androidDict)
        print("Making dictionary '\(language)' at \(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .medium))")
                

        var newLinesDict: [String:String] = [:]
        var existingLinesDict: [String:String] = [:]

        for elem in commonDict! {
            if DEBUG && elem.key == DEBUG_STOP_KEY {
                if LOGGING {
                    print("#### DEBUG_STOP_KEY #### ")
                }
            }
            
            if androidDict.keys.contains(elem.key)
            {
                // Update from localized android dict
                guard let androidValue = androidDict[elem.key] else { continue }
                guard isValueCorrect(value: androidValue) else { continue }
                guard !isEnglishDuplicateInLocalFile(language, elem.key, androidValue) else { continue }
                guard !isDuplicatedValueInSeveralLanguages(elem.key, androidValue) else { continue }
                
                if iosDict.keys.contains(elem.key) {
                    existingLinesDict.updateValue(androidValue, forKey: elem.key)
                } else {
                    newLinesDict.updateValue(androidValue, forKey: elem.key)
                }
            }
        }
        
        for elem in commonValuesDict {
            if DEBUG && elem.key == DEBUG_STOP_KEY {
                if LOGGING {
                    print("#### DEBUG_STOP_KEY #### ")
                }
            }
            if let androidKey = AndroidReader.dictContainsKeys(androidDict: androidDict, keys: elem.value) {
                guard let androidValue = androidDict[androidKey] else { continue }
                guard isValueCorrect(value: androidValue) else { continue }
                guard !isEnglishDuplicateInLocalFile(language, elem.key, androidValue) else { continue }
                guard !isDuplicatedValueInSeveralLanguages(elem.key, androidValue) else { continue }
                
                if iosDict.keys.contains(elem.key) {
                    existingLinesDict.updateValue(androidValue, forKey: elem.key)
                } else if iosEnglishDict[elem.key] != androidValue {
                    newLinesDict.updateValue(androidValue, forKey: elem.key)
                }
            }
        }

        print("Updating lines '\(language)' at \(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .medium))")
        if existingLinesDict.count > 0 || newLinesDict.count > 0 {
            let fileURL = URL(fileURLWithPath: Main.getOsmandRepositoriesPath().path + "/ios/Resources/Localizations/" + language + ".lproj/Localizable.strings")
            do {
                let fileContent = try String(contentsOf: fileURL)
                let strings = fileContent.components(separatedBy: ";\n")
                var processedStrings = [String]()
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
                var keyOccurrences = [String: Int]()
                // First, we populate the keyOccurrences with the keys from iosDict, initializing their counts to 0.
                iosDict.keys.forEach { keyOccurrences[$0] = 0 }
                var ind = 0
                var updatedStrings = [String]()
                for string in processedStrings {
                    ind += 1
                    if string.trimmingCharacters(in: .whitespaces).hasPrefix("//") {
                    //  print("Comment \(string) ")
                        updatedStrings.append(string)
                    } else {
                        // Split the string into key and value components using the "=" delimiter
                        let components = string.split(separator: "=", maxSplits: 1).map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
                        
                        // Extract the key, removing the surrounding quotation marks
                        var key = ""
                        var currentValue = ""
                        if components.count > 1 {
                            key = components[0].trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                            currentValue = iosDict[key] ?? ""
                        }
                        
                        if !key.isEmpty {
                            if DEBUG && key == DEBUG_STOP_KEY {
                                if LOGGING {
                                    print("#### DEBUG_STOP_KEY #### ")
                                }
                            }
                            
                            keyOccurrences[key, default: 0] += 1
                            if keyOccurrences[key]! > 1 {
                                print("Duplicate key ! \(string) ")
                            } else {
                                var newString = string
                                let newValue = existingLinesDict[key]
                                if let newValue, let updatedString = replaceValueText(newValue: filterUnsafeChars(newValue), inFullString: string)  {
                                    newString = updatedString
                                }
                                
                                // Filtering accendentally added old english lines
                                var isTrashString = false
                                
                                // Remove strings identical to the same string in english file - trash duplicates.
                                if let englishValue = iosEnglishDict[key] {
                                    if language != iosEnglishKey && !isTrashString {
                                        
                                        // Check new value
                                        if let newValue, newValue == englishValue {
                                            isTrashString = true
                                        }
                                        // Check current value
                                        let trimmedEnglishValue = englishValue.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                                        if currentValue == trimmedEnglishValue {
                                            isTrashString = true
                                        } else {
                                            if DEBUG && key == DEBUG_STOP_KEY {
                                                if LOGGING {
                                                    print("#### DEBUG_STOP_KEY #### ")
                                                }
                                            }
                                        }
                                    }
                                }
                                
                                // Filter the same value in several translations
                                if isDuplicatedValueInSeveralLanguages(key, currentValue) {
                                    isTrashString = true
                                }
                                if let newValue, isDuplicatedValueInSeveralLanguages(key, newValue) {
                                    isTrashString = true
                                }

                                
                                // For non-latin languages (Korean, Arabic, etc) just remove every english-only string. It's usuallu just a duplicate like "GPX", "GPS", etc
                                if DEBUG_DELETE_ALL_LATIN_ONLY_STRINGS_FROM_NONLATIN_LANGS && removeLatinOnlyStringsForLanguages.contains(language) && isStringEnglishOnly(newString) {
                                    isTrashString = true
                                }
                                
                                
                                // add updated string if it's ok
                                if !isTrashString {
                                    if !DEBUG_STOP_UPDATING_TRANSLATIONS {
                                        updatedStrings.append(newString);
                                    } else {
                                        // delete trash strings. don't change or update any another strings
                                        updatedStrings.append(string);
                                    }
                                }
                            }
                            //if let updstedString = replaceValueText(newValue: filterUnsafeChars(elem.value), inFullString: strings[i] )
                            // if ind % 1000 == 0 {
                            //     print("Index \(ind) \(key) \(string) ")
                            // }
                            
                            //return keyOccurrences[key]! == 1
                        } else if string.trimmingCharacters(in: .whitespaces) == "" {
                            // keep empty lines in the same order
                            updatedStrings.append(string)
                        } else {
                            print("Missing key \(string) ")
                            updatedStrings.append(string)
                        }
                    }
                    
                }
                
                // new translations adding
                if !DEBUG_STOP_UPDATING_TRANSLATIONS {
                    for elem in newLinesDict {
                        updatedStrings.append("\"" + elem.key + "\" = \"" + filterUnsafeChars(elem.value) + "\"")
                    }
                }
                
                // build a new Localizable.strings file
                var newFileContent = ""
                for string in updatedStrings {
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
            } catch {
                print ("error reading file: \(error)")
            }
        }
        print(language, "added: ", newLinesDict.count, "   updated: ", existingLinesDict.count, "   deleted duplicates: ", duplicatesCount)
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
    
    
    static func isValueCorrect(value: String) -> Bool {
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

// MARK: - RoutingParamsHelper

class RoutingParamsHelper {
    
    static func addRoutingParams() {
        addParams(language:iosEnglishKey)
        for lang in allLanguagesDict {
            addParams(language:lang.key)
        }
    }
    
    static func addParams (language: String) {
        //print("\nROUTE_PARAMS_TRANSLATING: " + language + "\n")
        var routeDict: [String:String] = [:]
        var addedStringsArray: [String] = []
        
        let url = URL(fileURLWithPath: Main.getOsmandRepositoriesPath().path + "/ios/Resources/Localizations/" + language + ".lproj/Localizable.strings")
        let path = url.path
        
        var str: String = ""
        do {
            str = try String(contentsOfFile: path)
        } catch {
            return
        }
        var iosArr = str.components(separatedBy: "\n")
        
        
        var myLang: String = ""
        if language != "en" {
            if let lang = languageDict[language] {
                myLang = "-" + lang
            }
        }
        let androidURL = URL(fileURLWithPath: Main.getOsmandRepositoriesPath().path + "/android/OsmAnd/res/values" + myLang + "/strings.xml")
        let myparser = Parser()
        var androidDict = myparser.myparser(path: androidURL)
        for key in androidDict.keys {
            if var value = androidDict[key] {
                value = value.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                androidDict[key] = value
                if key.hasPrefix("routeInfo_") || key.hasPrefix("routing_attr_") || key.hasPrefix("rendering_attr_") || key.hasPrefix("rendering_value_") {
                    routeDict[key] = value
                }
            }
        }
        
        var uniqueIosKeys = Set<String>()
        var foundedRenderingKeys = [String]()
        var updatedStringsCount = 0
        
        for elem in iosArr {
            if elem.hasPrefix("\"routeInfo_") || elem.hasPrefix("\"routing_attr_") || elem.hasPrefix("\"rendering_attr_") || elem.hasPrefix("\"rendering_value_") {
                
                if let index = iosArr.firstIndex(of: elem) {
                    let iosString = iosArr[index];
                    let key = IOSWriter.getKey(inFullString: iosString)
                    
                    if (uniqueIosKeys.contains(key)) {
                        iosArr[index] = ""
                        updatedStringsCount += 1;
                    } else {
                        uniqueIosKeys.insert(key)
                        if let androidValue = androidDict[key] {
                            foundedRenderingKeys.append(key)
                            if let updatedSrting = IOSWriter.replaceValueText(newValue: IOSWriter.filterUnsafeChars(androidValue), inFullString: iosString) {
                                //updatedSrting = IOSWriter.filterUnsafeChars(androidValue)
                                if (iosString != updatedSrting) {
                                    iosArr[index] = updatedSrting
                                    updatedStringsCount += 1
                                }
                            }
                        }
                    }
                }
            }
        }
        
        for elem in routeDict {
            if (!foundedRenderingKeys.contains(elem.key)) {
                addedStringsArray.append(makeOutputString(str1: elem.key, str2: elem.value))
            }
        }
        let joined1 = iosArr.joined(separator: "\n")
        let joined2 = addedStringsArray.joined(separator: "\n")
        var joined = joined1
        if (joined2.count > 0) {
            joined = joined1 + "\n" + joined2
        }

        print("route_params : ", language, " added : ", addedStringsArray.count, " updated: ", updatedStringsCount)
        do {
            try joined.write(to: url, atomically: false, encoding: .utf8)
        }
        catch { return }
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
