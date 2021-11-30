#!/usr/bin/env swift
//
//  main.swift
//  addTranslation
//
//  Created by igor on 13.01.2020.
//  Copyright © 2020 igor. All rights reserved.
//

import Foundation

var commonDict: [String:String]?
var commonValuesDict: [String:[String]] = [:]
var duplicatesCount = 0

let languageDict = [
    "ar" : "ar",
    "ast" : "ast",
    "az" : "az",
    "be" : "be",
    "bg" : "bg",
    "ca" : "ca",
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
    "hsb" : "b+hsb",
    "hu" : "hu",
    "hy" : "hy",
    "id" : "id",
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
    "ml" : "ml",
    "my" : "my",
    "nb" : "nb",
    "nl" : "nl",
    "oc" : "oc",
    "pl" : "pl",
    "pt-BR" : "pt-rBR",
    "ro-RO" : "ro",
    "ru" : "ru",
    "sc" : "sc",
    "sk" : "sk",
    "sl" : "sl",
    "sq" : "sq",
    "sr" : "sr",
    "sr-Latn" : "b+sr+Latn",
    "sv" : "sv",
    "ta" : "ta",
    "tr" : "tr",
    "uk" : "uk",
    "vi" : "vi",
    "zh-Hans" : "zh-rCN" ,
    "zh-Hant" : "zh-rTW",
]

var allLanguagesDict = languageDict
allLanguagesDict["en"] = ""



//mark: Add Routing Params

func addRoutingParams (language: String) {
    var routeDict: [String:String] = [:]
    var outputArray: [String] = []
    
    let url = URL(fileURLWithPath: "../Resources/Localizations/" + language + ".lproj/Localizable.strings")
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
    let androidURL = URL(fileURLWithPath: "../../android/OsmAnd/res/values" + myLang + "/strings.xml")
    let myparser = Parser()
    let androidDict = myparser.myparser(path: androidURL)
    for elem in androidDict {
       if elem.key.hasPrefix("routeInfo_") || elem.key.hasPrefix("routing_attr_") || elem.key.hasPrefix("rendering_attr_") || elem.key.hasPrefix("rendering_value_") {
           routeDict[elem.key] = elem.value
       }
    }
  
    for elem in iosArr {
        if elem.hasPrefix("\"routeInfo_") || elem.hasPrefix("\"routing_attr_") || elem.hasPrefix("\"rendering_attr_") || elem.hasPrefix("\"rendering_value_") {
            if let index = iosArr.firstIndex(of: elem) {
                iosArr.remove(at: index)
            }
        }
    }
    
    for elem in routeDict {
        outputArray.append(makeOutputString(str1: elem.key, str2: elem.value))
    }
    print(language, outputArray.count)
    let joined1 = iosArr.joined(separator: "\n")
    let joined2 = outputArray.joined(separator: "")
    let joined = joined1 + joined2
    do {
        try joined.write(to: url, atomically: false, encoding: .utf8)
    }
    catch {return}
}



//mark: Add Translations

func addTranslations(language: String, initial: Bool) {
    let iosDict = parseIos(language: language, initial: initial)
    let androidDict = parseAndroid(language: language, initial: initial)
    if initial {
        compareDicts(language: language, iosDict: iosDict, androidDict: androidDict)
    }
    else {
        makeNewDict(language: language, iosDict: iosDict, androidDict: androidDict)
    }
}



//mark: IOS specific methods
func parseIos (language: String, initial: Bool) -> [String : String] {
    var iosDict: [String:String] = [:]
    var myLang: String = "en"
    if !initial {
        myLang = language
    }
    let url = URL(fileURLWithPath: "../Resources/Localizations/" + myLang + ".lproj/Localizable.strings")
    guard let dict = NSDictionary(contentsOf: url) else {return iosDict }
    iosDict = dict as! [String : String]
    return iosDict
}

func replaceValueText(newValue: String, inFullString fullString: String) -> String {
    /// Localzable.strings  one string format:
    /// "key" = "value";
    let quotationMarkIndexes = getAllSubstringIndexes(fullString: fullString, subString: "\"")
    guard (quotationMarkIndexes.count >= 4) else {return fullString}
    
    let startIndex = fullString.index(fullString.startIndex, offsetBy: quotationMarkIndexes[2] + 1)
    let endIndex = fullString.index(fullString.startIndex, offsetBy: quotationMarkIndexes.last!)

    var resultString = fullString
    resultString.replaceSubrange(startIndex ..< endIndex, with: newValue)
    return resultString
}

func getAllSubstringIndexes(fullString: String, subString: String) -> [Int] {
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

func makeOutputString(str1: String, str2: String) -> String {
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
    return "\n\"" + str1 + "\" = \"" + str2 + "\";"
}



//mark: Android specific methods
func parseAndroid(language: String, initial: Bool) -> [String : String] {
    var myLang: String = ""
    if !initial {
        if let lang = languageDict[language] {
            myLang = "-" + lang
        }
    }
    let url = URL(fileURLWithPath: "../../android/OsmAnd/res/values" + myLang + "/strings.xml")
    let myparser = Parser()
    return myparser.myparser(path: url)
}

func androidContains(androidDict: [String:String], keys: [String]) -> String? {
    for elem in androidDict.keys {
        for key in keys {
            if elem == key {
                return key
            }
        }
    }
    return nil
}



//mark: Compare Dict
func compareDicts(language: String, iosDict: [String : String], androidDict: [String : String]){
    let androidDict = modifyVariables(dict: androidDict)
    var common: Dictionary = [String:String]()
    for elem in iosDict
    {
        if let androidValue = androidDict[elem.key] {
            if androidValue == elem.value || equalWithoutDots(str1: androidValue, str2: elem.value) {
                /// iosKey == androidKey && iosEnValue == androidEnValue
                common[elem.key] = elem.value
                //pringDebugLog(iosKey: elem.key, iosValue: elem.value, androidKey: elem.key, androidValue: androidValue)
            } else {
                /// iosKey == androidKey && iosEnValue != androidEnValue
                /// ignoring
                //pringDebugLog(iosKey: elem.key, iosValue: elem.value, androidKey: elem.key, androidValue: androidValue)
            }
        }
        else {
            /// iosKey != androidKey.
            /// find androidKey where iosEnValue == androidEnValue
            var keys: [String] = []
            if androidDict.values.contains(elem.value) {
                keys = (androidDict as NSDictionary).allKeys(for: elem.value) as! [String]
                commonValuesDict[elem.key] = keys
                //pringDebugLog(iosKey: elem.key, iosValue: elem.value, androidKey: keys.first!, androidValue: androidDict[keys.first!]!)
            }
            else if elem.value.last == "." && androidDict.values.contains(String(elem.value.dropLast())) {
                keys = (androidDict as NSDictionary).allKeys(for: String(elem.value.dropLast())) as! [String]
                commonValuesDict[elem.key] = keys
                //pringDebugLog(iosKey: elem.key, iosValue: elem.value, androidKey: keys.first!, androidValue: androidDict[keys.first!]!)
            }
        }
    }
    commonDict = common
    if language != "en" {
        addTranslations(language: language, initial: false)
    }
}

func equalWithoutDots(str1: String, str2: String) -> Bool {
    if (str1.last == "." && str1.dropLast() == str2) || (str2.last == "." && str2.dropLast() == str1) {
        return true
    }
    return false
}



//mark: Make new dict

func makeNewDict(language: String, iosDict: [String : String], androidDict: [String : String]) {
    let androidDict = modifyVariables(dict: androidDict)
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
        if let key = androidContains(androidDict: androidDict, keys: elem.value) {
            guard isValueCorrect(value: androidDict[key]!) else {continue}
            if iosDict.keys.contains(elem.key) {
                existingLinesDict.updateValue(androidDict[key]!, forKey: elem.key)
            } else {
                newLinesDict.updateValue(androidDict[key]!, forKey: elem.key)
            }
        }
    }
    
    if existingLinesDict.count > 0 || newLinesDict.count > 0 {
        let fileURL = URL(fileURLWithPath: "../Resources/Localizations/" + language + ".lproj/Localizable.strings")
        do {
            let fileContent = try String(contentsOf: fileURL)
            var strings = fileContent.components(separatedBy: ";")
            strings = filterDuplicateStrings(strings, iosDict: iosDict)
            strings = filterEndingEmptyStrings(strings)

            for elem in existingLinesDict {
                for i in 0 ..< strings.count {
                    if strings[i].contains("\"" + elem.key + "\"") {
                        strings[i] = replaceValueText(newValue: filterUnsafeChars(elem.value), inFullString: strings[i] )
                    }
                }
            }

            for elem in newLinesDict {
                strings.append("\n\"" + elem.key + "\" = \"" + filterUnsafeChars(elem.value) + "\"")
            }
            strings.append("")
            
            let newFileContent = strings.joined(separator: ";")
        
            do {
                try newFileContent.write(to: fileURL, atomically: true, encoding: String.Encoding.utf8)
            } catch {
                print ("error writing file: \(error)")
            }
        } catch {
            print ("error reading file: \(error)")
        }
    }
    print(language, "added: ", newLinesDict.count, "   udated: ", existingLinesDict.count, "   deleted duplicates: ", duplicatesCount)
}

func isValueCorrect(value: String) -> Bool {
    return value.count > 0 && !value.contains("$")
}

func filterEndingEmptyStrings(_ stringsArray: [String]) -> [String] {
    var strings = stringsArray
    repeat {
        while strings.last!.hasSuffix("\n") && strings.count > 1
        {
            strings[strings.count - 1] = String(strings[strings.count - 1].dropLast())
        }
        if strings.last!.count == 0
        {
            strings.removeLast()
        }
    } while strings.last!.count == 0
    return strings
}

func filterDuplicateStrings(_ stringsArray: [String], iosDict: [String : String]) -> [String]
{
    var strings = stringsArray
    var linesToDelete = Set<Int>()
    
    for key in iosDict.keys {
        var count = 0
        for i in 0 ..< strings.count {
            if strings[i].contains("\"" + key + "\"") {
                count += 1
                if count > 1 {
                    linesToDelete.insert(i)
                }
            }
        }
    }

    for i in linesToDelete.sorted(by: >) {
        strings.remove(at: i)
    }
    
    duplicatesCount = linesToDelete.count
    return strings
}

func filterUnsafeChars(_ text: String) -> String {
    var result: String = text;
    if result.hasSuffix(";") {
        result = String(result.dropLast())
    }
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



//mark: Global utils

func modifyVariables(dict: [String : String]) -> [String : String] {
    var androidDict = dict
    for elem in androidDict {
        let range = NSRange(location: 0, length: elem.value.utf16.count)

        let regex = try! NSRegularExpression(pattern: "%[0-9]*[$]?[sdt.]")
        if regex.firstMatch(in: elem.value, options: [], range: range) != nil {
            let modString = regex.stringByReplacingMatches(in: elem.value, options: [], range: NSMakeRange(0, elem.value.utf16.count), withTemplate: replace(str: elem.value))
            androidDict.updateValue(modString, forKey: elem.key)
        }
    }
    return androidDict
}

func replace(str: String) -> String {
    let range = NSRange(location: 0, length: str.utf16.count)
    var regex = try! NSRegularExpression(pattern: "%[0-9]*[$]?[s]")
    if regex.firstMatch(in: str, options: [], range: range) != nil {
        return "%@"
    }
    regex = try! NSRegularExpression(pattern: "%[0-9]*[$]?[d]")
    if regex.firstMatch(in: str, options: [], range: range) != nil {
       return "%d"
    }
    return str
}

func pringDebugLog(iosKey: String, iosValue: String, androidKey: String, androidValue: String)
{
    print("#### ios key       :  " + iosKey)
    print("#### ios value     :  " + iosValue)
    print("#### android key   :  " + androidKey)
    print("#### android value :  " + androidValue)
    print("#### ================================================================================================")
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
            value = ""
        }
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



//mark: Bash commands helper

func shell(_ command: String) -> String {
    let task = Process()
    let pipe = Pipe()
    
    task.standardOutput = pipe
    task.standardError = pipe
    task.arguments = ["-c", command]
    task.launchPath = "/bin/zsh"
    task.launch()
    
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .utf8)!
    
    return output
}

func changeDir(_ argument: String) -> String {
    var path = ""
    if argument == ".." {
        let currentFolderPath = URL(fileURLWithPath: shell("echo $PWD"), isDirectory: true)
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
    return path
}






//mark: Start script

///Uncomment this line for debugging. Change this path to your "OsmAnd/ios/Scripts/" folder's path.
//print( changeDir("/Users/nnngrach/Documents/Projects/Coding/OsmAnd/ios/Scripts/") )


// Update repositories to avoid Weblate merge conflicts

let currentIosScriptsFolder = URL(fileURLWithPath: shell("echo $PWD"), isDirectory: true)
let osmandRepositoriesFolder = currentIosScriptsFolder.deletingLastPathComponent().deletingLastPathComponent()
//
print( changeDir(osmandRepositoriesFolder.appendingPathComponent("android/").path) )
print( shell("git pull") )

print( changeDir(osmandRepositoriesFolder.appendingPathComponent("ios/").path) )
print( shell("git pull") )

print( changeDir(osmandRepositoriesFolder.appendingPathComponent("resources/").path) )
print( shell("git pull") )


// Update phrases

print( changeDir(osmandRepositoriesFolder.appendingPathComponent("resources/poi/").path) )
print( shell("./copy_phrases.sh"))
//Don't commit this changes by script to avoid merge conflicts.
//Do manual commit of Resources repo щт new app version build.




//mark: run translation updating
print( changeDir(currentIosScriptsFolder.path) )

if (CommandLine.arguments.count == 2) && (CommandLine.arguments[1] == "-routing") {
    for lang in allLanguagesDict {
        addRoutingParams(language:lang.key)
    }
}

for lang in languageDict {
    addTranslations(language:lang.key, initial: true)
}
