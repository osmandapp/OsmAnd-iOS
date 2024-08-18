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
let OSMAND_REPOSITORIES_PATH = "/Users/nnngrach/Documents/Projects/Coding/OsmAnd/"


var iosEnglishDict: [String : String] = [:]
var androidEnglishDict: [String : String] = [:]
var androidEnglishDictOrig: [String : String] = [:]

var commonDict: [String:String]?
var commonValuesDict: [String:[String]] = [:]
var duplicatesCount = 0

let iosEnglishKey = "en"
let androidEnglishKey = ""
// Test
// let languageDict = [
//     "ru" : "ru"
// ]

let languageDict = [
    "af" : "af",
    "an" : "an",
    "ar" : "ar",
    "ars" : "ars",
    "ast" : "ast",
    "az" : "az",
    "be" : "be",
    "bg" : "bg",
    "bn" : "bn",
    "br" : "br",
    "bs" : "bs",
    "ca" : "ca",
    "ckb" : "ckb",
    "cs" : "cs",
    "cy" : "cy",
    "da" : "da",
    "de" : "de",
    "el" : "el",
    "en-GB" : "en-rGB",
    "eo" : "eo",
    "es" : "es",
    "es-AR" : "es-rAR",
    "es-US" : "es-rUS",
    "et" : "et",
    "eu" : "eu",
    "fa" : "fa",
    "fi" : "fi",
    "fr" : "fr",
    "gl" : "gl",
    "he" : "iw",
    "hr" : "hr",
    "hsb" : "b+hsb",
    "hu" : "hu",
    "hy" : "hy",
    "ia" : "ia",
    "id" : "in",
    "is" : "is",
    "it" : "it",
    "ja" : "ja",
    "ka" : "ka",
    "kab" : "b+kab",
    "kn" : "kn",
    "ko" : "ko",
    "ku" : "ku",
    "lt" : "lt",
    "lv" : "lv",
    "mk" : "mk",
    "ml" : "ml",
    "mn" : "mn",
    "mr" : "mr",
    "my" : "my",
    "nb" : "nb",
    "nl" : "nl",
    "nn" : "nn",
    "oc" : "oc",
    "pa-Arab-PK" : "pa-rPK",
    "pl" : "pl",
    "pt" : "pt",
    "pt-BR" : "pt-rBR",
    "ro-RO" : "ro",
    "ru" : "ru",
    "sat" : "sat",
    "sc" : "sc",
    "sk" : "sk",
    "sl" : "sl",
    "sq" : "sq",
    "sr" : "sr",
    "sr-Latn" : "b+sr+Latn",
    "sv" : "sv",
    "ta" : "ta",
    "te" : "te",
    "tr" : "tr",
    "tt" : "tt",
    "tzm" : "tzm",
    "uk" : "uk",
    "ur" : "ur",
    "uz-Cyrl" : "uz",
    "vi" : "vi",
    "zh-Hans" : "zh-rCN" ,
    "zh-Hant" : "zh-rTW",
]



var allLanguagesDict = languageDict
allLanguagesDict["en"] = ""



class Main {
    
    static func run(_ arguments: [String]) {
        print("START: add_translations script \n")

        let path = getOsmandRepositoriesPath()
        updateGitRepositories(path) 
        copyPhrasesFiles(path) 
        
        Initialiser.initUpdatingTranslationKeyLists(path)
        addRoutingParametersIfNeeded(arguments, path) 
        updateTranslations(path)
        
        print("DONE: add_translations script \n")
    }
    
    
    static private func getOsmandRepositoriesPath() -> URL {
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
        let androidDict = IOSReader.replacePlaceholders(androidDict: androidDict)
        var commonTranslations: Dictionary = [String:String]()
        for iosTranslation in iosDict
        {
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



class IOSReader {
    
    static func parseTranslationFile(language: String) -> [String : String] {
        var iosDict: [String:String] = [:]
        let url = URL(fileURLWithPath: "./Resources/Localizations/" + language + ".lproj/Localizable.strings")
        guard let dict = NSDictionary(contentsOf: url) else {return iosDict }
        iosDict = dict as! [String : String]
        return iosDict
    }
    
    
    static func replacePlaceholders(androidDict: [String : String]) -> [String : String] {
        var updatedDict = androidDict
        for elem in updatedDict {
            var modString = elem.value;
            
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
 


class IOSWriter {
    
    static func addTranslations() {
        
        print("\nTRANSLATING: English at \(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .medium))\n")
        IOSWriter.makeNewDict(language: iosEnglishKey, iosDict: iosEnglishDict, androidDict: androidEnglishDict)
        
        for language in languageDict {
            print("\nTranslating: \(language.key) at \(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .medium))\n")
            let iosDict = IOSReader.parseTranslationFile(language: language.key)
            let androidDict = AndroidReader.parseTranslationFile(language: language.key)
            IOSWriter.makeNewDict(language: language.key, iosDict: iosDict, androidDict: androidDict)
        }
    }
    
    
    static func makeNewDict(language: String, iosDict: [String : String], androidDict: [String : String]) {
        let androidDict = IOSReader.replacePlaceholders(androidDict: androidDict)
        print("Making dictionary '\(language)' at \(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .medium))")
                

        var newLinesDict: [String:String] = [:]
        var existingLinesDict: [String:String] = [:]

        for elem in commonDict! {
            if androidDict.keys.contains(elem.key)
            {
                guard isValueCorrect(value: androidDict[elem.key]!) else {continue}
                if iosDict.keys.contains(elem.key) {
                    existingLinesDict.updateValue(androidDict[elem.key]!, forKey: elem.key)
                } else {
                    newLinesDict.updateValue(androidDict[elem.key]!, forKey: elem.key)
                }
            }
        }
        
        for elem in commonValuesDict {
            if let key = AndroidReader.dictContainsKeys(androidDict: androidDict, keys: elem.value) {
                guard isValueCorrect(value: androidDict[key]!) else {continue}
                if iosDict.keys.contains(elem.key) {
                    existingLinesDict.updateValue(androidDict[key]!, forKey: elem.key)
                } else {
                    newLinesDict.updateValue(androidDict[key]!, forKey: elem.key)
                }
            }
        }

        print("Updating lines '\(language)' at \(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .medium))")        
        if existingLinesDict.count > 0 || newLinesDict.count > 0 {
            let fileURL = URL(fileURLWithPath: "./Resources/Localizations/" + language + ".lproj/Localizable.strings")
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
                        let key = components.first?.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                        if  let key = key, iosDict.keys.contains(key) {
                            keyOccurrences[key, default: 0] += 1
                            if keyOccurrences[key]! > 1 {
                                print("Duplicate key ! \(string) ")
                            } else {
                                if let value = existingLinesDict[key], let updatedString = replaceValueText(newValue: filterUnsafeChars(value), inFullString: string)  {
                                    updatedStrings.append(updatedString)
                                } else {
                                    updatedStrings.append(string);
                                }
                            }
                            //if let updstedString = replaceValueText(newValue: filterUnsafeChars(elem.value), inFullString: strings[i] ) 
                            // if ind % 1000 == 0 {
                            //     print("Index \(ind) \(key) \(string) ")
                            // }
                            
                            //return keyOccurrences[key]! == 1
                        } else if string.trimmingCharacters(in: .whitespaces) == "" {
                            // keep empty lines
                            updatedStrings.append(string)
                        } else {
                            print("Missing key \(string) ")
                            updatedStrings.append(string)
                        }
                    }
                    
                }
                for elem in newLinesDict {
                    updatedStrings.append("\"" + elem.key + "\" = \"" + filterUnsafeChars(elem.value) + "\"")
                }
                
                //let newFileContent = strings.joined(separator: ";\n")
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
        guard (quotationMarkIndexes.count >= 4) else {return fullString}
        
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



class AndroidReader {
    
    static func parseTranslationFile(language: String) -> [String : String] {
        var langSuffix: String = language
        if language != "" {
            if let lang = languageDict[language] {
                langSuffix = "-" + lang
            }
        }
        let url = URL(fileURLWithPath: "../android/OsmAnd/res/values" + langSuffix + "/strings.xml")
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
        let data = string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
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
        
        let url = URL(fileURLWithPath: "./Resources/Localizations/" + language + ".lproj/Localizable.strings")
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
        let androidURL = URL(fileURLWithPath: "../android/OsmAnd/res/values" + myLang + "/strings.xml")
        let myparser = Parser()
        let androidDict = myparser.myparser(path: androidURL)
        for elem in androidDict {
            if elem.key.hasPrefix("routeInfo_") || elem.key.hasPrefix("routing_attr_") || elem.key.hasPrefix("rendering_attr_") || elem.key.hasPrefix("rendering_value_") {
                routeDict[elem.key] = elem.value
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
        catch {return}
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




//MARK: Script launching
Main.run(CommandLine.arguments)
