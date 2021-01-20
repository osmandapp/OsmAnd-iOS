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
let languageDict = [
                    "es_AR" : "es-rAR",
                    "hsb" : "b+hsb",
                    "kab" : "b+kab",
                    "pt_BR" : "pt-rBR",
                    "ro-RO" : "ro",
                    "zh-Hans" : "zh-rCN" ,
                    "zh-Hant" : "zh-rTW",
                    "ar" : "ar",
                    "be" : "be",
                    "ca" : "ca",
                    "cs" : "cs",
                    "da" : "da",
                    "de" : "de",
                    "es" : "es",
                    "et" : "et",
                    "fa" : "fa",
                    "fr" : "fr",
                    "gl" : "gl",
                    "hu" : "hu",
                    "is" : "is",
                    "it" : "it",
                    "ja" : "ja",
                    "ku" : "ku",
                    "my" : "my",
                    "nb" : "nb",
                    "nl" : "nl",
                    "oc" : "oc",
                    "pl" : "pl",
                    "pt" : "pt",
                    "ru" : "ru",
                    "sc" : "sc",
                    "sk" : "sk",
                    "sl" : "sl",
                    "sq" : "sq",
                    "tr" : "tr",
                    "uk" : "uk",
                    "el" : "el"
]

var allLanguagesDict = languageDict
allLanguagesDict["en"] = ""

func addTranslations(language: String, initial: Bool) {
    let iosDict = parseIos(language: language, initial: initial)
    parseAndroidAndCompare(language: language, iosDict: iosDict, initial: initial)
}

func equalWithoutDots(str1: String, str2: String) -> Bool {
    if (str1.last == "." && str1.dropLast() == str2) || (str2.last == "." && str2.dropLast() == str1) {
        return true
    }
    return false
}

func withoutDot(str: String) -> String {
    if str.last == "." {
        return String(str.dropLast())
    }
    return str
}

func compareDicts(language: String, iosDict: [String : String], androidDict: [String : String]){
    let androidDict = modifyVariables(dict: androidDict)
    var common: Dictionary = [String:String]()
    for elem in iosDict
    {
        if let androidValue = androidDict[elem.key] {
            if androidValue == elem.value || equalWithoutDots(str1: androidValue, str2: elem.value) {
                common[elem.key] = elem.value
            }
        }
        else {
            var keys: [String] = []
            if androidDict.values.contains(elem.value) {
                keys = (androidDict as NSDictionary).allKeys(for: elem.value) as! [String]
                commonValuesDict[elem.key] = keys
            }
            else if elem.value.last == "." && androidDict.values.contains(String(elem.value.dropLast())) {
                keys = (androidDict as NSDictionary).allKeys(for: String(elem.value.dropLast())) as! [String]
                commonValuesDict[elem.key] = keys
            }
        }
    }
    commonDict = common
    if language != "en" {
        addTranslations(language: language, initial: false)
    }
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

func makeNewDict(language: String, iosDict: [String : String], androidDict: [String : String]) {
    let androidDict = modifyVariables(dict: androidDict)
    var outputDict: [String:String] = [:]
    var outputArray: [String] = []
    for elem in androidDict {
        if commonDict!.keys.contains(elem.key) && !iosDict.keys.contains(elem.key) {
            outputDict.updateValue(elem.value, forKey: elem.key)
        }
    }
    for elem in commonValuesDict {
        if !iosDict.keys.contains(elem.key) {
            if let key = androidContains(androidDict: androidDict, keys: elem.value) {
                outputDict.updateValue(androidDict[key]!, forKey: elem.key)
            }
        }
    }
    for elem in outputDict {
        outputArray.append(makeOutputString(str1: elem.key, str2: elem.value))
    }
    let joined = outputArray.joined(separator: "")

    let fileURL = URL(fileURLWithPath: "Resources/" + language + ".lproj/Localizable.strings")
    do {
        let fileHandle = try FileHandle(forWritingTo: fileURL)
        fileHandle.seekToEndOfFile()
        let textData = Data(joined.utf8)
        fileHandle.write(textData)
        fileHandle.closeFile()
    } catch {
        print(error)
    }
    print(language, "added: ", outputDict.count)
}

func parseIos (language: String, initial: Bool) -> [String : String] {
    var iosDict: [String:String] = [:]
    var myLang: String = "en"
    if !initial {
        myLang = language
    }
    let url = URL(fileURLWithPath: "Resources/" + myLang + ".lproj/Localizable.strings")
    guard let dict = NSDictionary(contentsOf: url) else {return iosDict }
    iosDict = dict as! [String : String]
    return iosDict
}

func parseAndroidAndCompare(language: String, iosDict: [String:String], initial: Bool) {
    var myLang: String = ""
    if !initial {
        if let lang = languageDict[language] {
            myLang = "-" + lang
        }
    }
    let url = URL(fileURLWithPath: "../android/OsmAnd/res/values" + myLang + "/strings.xml")
    let myparser = Parser()
    let androidDict = myparser.myparser(path: url)
    if initial {
        compareDicts(language: language, iosDict: iosDict, androidDict: androidDict)
    }
    else {
        makeNewDict(language: language, iosDict: iosDict, androidDict: androidDict)
    }
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

func addRoutingParams (language: String) {
    var routeDict: [String:String] = [:]
    var outputArray: [String] = []
    
    let url = URL(fileURLWithPath: "Resources/" + language + ".lproj/Localizable.strings")
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

if (CommandLine.arguments.count == 2) && (CommandLine.arguments[1] == "-routing") {
    for lang in allLanguagesDict {
        addRoutingParams(language:lang.key)
    }
}

for lang in languageDict {
    addTranslations(language:lang.key, initial: true)
}
