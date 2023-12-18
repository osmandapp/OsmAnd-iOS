//
//  HelpDataManager.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 05.12.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import UIKit

@objcMembers
final class PopularArticle: NSObject {
    let title: String
    let url: String
    
    init(title: String, url: String) {
        self.title = title
        self.url = url
    }
}

@objcMembers
final class TelegramChat: NSObject {
    let title: String
    let url: String
    
    init(title: String, url: String) {
        self.title = title
        self.url = url
    }
}

@objcMembers
final class ArticleNode: NSObject {
    var title: String
    var url: String
    var childArticles: [ArticleNode]
    
    init(title: String, url: String, childArticles: [ArticleNode] = []) {
        self.title = title
        self.url = url
        self.childArticles = childArticles
    }
}

@objc enum HelperDataItems: Int {
    case popularArticles
    case telegramChats
    
    var description: String {
        switch self {
        case .popularArticles:
            return "popularArticles"
        case .telegramChats:
            return "telegramChats"
        }
    }
}

@objc(OAMenuHelpDataService)
@objcMembers
final class MenuHelpDataService: NSObject, XMLParserDelegate {
    private let urlPrefix = "https://osmand.net"
    private var popularArticles: [PopularArticle] = []
    private var telegramChats: [TelegramChat] = []
    private var currentArticleNode: ArticleNode?
    private var rootNode: ArticleNode = ArticleNode(title: "Root", url: "")
    private var articles: [ArticleNode] = []
    private var currentElement: String = ""
    private var currentURL: String = ""
    static let shared = MenuHelpDataService()
    
    private override init() { }
    
    func loadAndParseJson(from urlString: String, for dataItem: HelperDataItems, completion: @escaping (NSArray?, NSError?) -> Void) {
        if dataItem == .popularArticles, !popularArticles.isEmpty {
            completion(popularArticles as NSArray, nil)
            return
        } else if dataItem == .telegramChats, !telegramChats.isEmpty {
            completion(telegramChats as NSArray, nil)
            return
        }
        
        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async {
                completion(nil, NSError(domain: "URLInvalid", code: 0, userInfo: nil))
            }
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self else { return }
            guard let data, error == nil else {
                DispatchQueue.main.async {
                    completion(nil, error as NSError? ?? NSError(domain: "DataError", code: 1, userInfo: nil))
                }
                return
            }
            
            do {
                guard let jsonDict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                      let jsonData = jsonDict[dataItem.description] as? [String: String] else {
                    DispatchQueue.main.async {
                        completion(nil, NSError(domain: "JSONConversionError", code: 2, userInfo: nil))
                    }
                    return
                }
                
                switch dataItem {
                case .popularArticles:
                    let articles = self.processPopularArticles(jsonData)
                    self.popularArticles = articles
                    DispatchQueue.main.async {
                        completion(articles as NSArray, nil)
                    }
                case .telegramChats:
                    let chats = self.processTelegramChats(jsonData)
                    self.telegramChats = chats
                    DispatchQueue.main.async {
                        completion(chats as NSArray, nil)
                    }
                }
            } catch let error as NSError {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
            }
        }.resume()
    }
    
    func getCountForCategory(from urlString: String, for dataItem: HelperDataItems, completion: @escaping (Int) -> Void) {
        loadAndParseJson(from: urlString, for: dataItem) { data, error in
            guard let data = data, error == nil else {
                completion(0)
                return
            }
            
            if dataItem == .telegramChats, let chats = data as? [TelegramChat] {
                completion(chats.count)
            } else if dataItem == .popularArticles, let articles = data as? [PopularArticle] {
                completion(articles.count)
            } else {
                completion(0)
            }
        }
    }
    
    func loadAndProcessSitemap(completion: @escaping ([ArticleNode]?, Error?) -> Void) {
        let fileManager = FileManager.default
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            DispatchQueue.main.async {
                completion(nil, NSError(domain: "DirectoryError", code: 1, userInfo: nil))
            }
            return
        }
        
        let localFileURL = documentsDirectory.appendingPathComponent("sitemap.xml")
        if fileManager.fileExists(atPath: localFileURL.path) {
            processSitemapFile(at: localFileURL, completion: { articles, error in
                DispatchQueue.main.async {
                    completion(articles, error)
                }
            })
        } else {
            guard let url = URL(string: urlPrefix + "/sitemap.xml") else {
                DispatchQueue.main.async {
                    completion(nil, NSError(domain: "URLCreationError", code: 0, userInfo: nil))
                }
                return
            }
            
            URLSession.shared.dataTask(with: url) { data, _, error in
                guard let data, error == nil else {
                    DispatchQueue.main.async {
                        completion(nil, error)
                    }
                    return
                }
                
                do {
                    try data.write(to: localFileURL)
                    self.processSitemapFile(at: localFileURL, completion: { articles, error in
                        DispatchQueue.main.async {
                            completion(articles, error)
                        }
                    })
                } catch {
                    DispatchQueue.main.async {
                        completion(nil, error)
                    }
                }
            }.resume()
        }
    }
    
    func prepareArticlesForDisplay(rootNode: ArticleNode) -> [ArticleNode] {
        let sortedMainArticles = rootNode.childArticles.sorted {
            getArticleName(from: $0.url) < getArticleName(from: $1.url)
        }
        
        var items: [ArticleNode] = []
        for node in sortedMainArticles {
            if !node.childArticles.isEmpty {
                node.childArticles.sort {
                    getArticleName(from: $0.url) < getArticleName(from: $1.url)
                }
            }
            items.append(node)
        }
        
        return items
    }
    
    func getArticleName(from url: String) -> String {
        let articleId = getArticlePropertyName(from: url)
        if let specialName = getSpecialArticleName(for: articleId) {
            return specialName
        } else {
            let articleNameKey = "help_article_\(articleId)_name"
            let localized = localizedString(articleNameKey)
            return localized.isEmpty ? articleId.replacingOccurrences(of: "_", with: " ").capitalized : localized
        }
    }
    
    private func processPopularArticles(_ data: [String: String]) -> [PopularArticle] {
        let orderedData = data.map { ($0.key, $0.value) }.sorted { $0.0 < $1.0 }
        return orderedData.map { PopularArticle(title: $0.0, url: urlPrefix + $0.1) }
    }
    
    private func processTelegramChats(_ data: [String: String]) -> [TelegramChat] {
        let orderedData = data.map { ($0.key, $0.value) }.sorted { $0.0 < $1.0 }
        return orderedData.map { TelegramChat(title: $0.0, url: $0.1) }
    }
    
    private func addArticleNode(_ node: ArticleNode, url: String) {
        let parts = url.replacingOccurrences(of: kOsmAndUserBaseURL, with: "").split(separator: "/").map(String.init)
        var currentNode = rootNode
        for part in parts {
            if let childNode = currentNode.childArticles.first(where: { $0.title == part }) {
                currentNode = childNode
            } else {
                let newNode = ArticleNode(title: part, url: currentNode.url + part + "/")
                currentNode.childArticles.append(newNode)
                currentNode = newNode
                debugPrint("Added new article node: Title: \(newNode.title), URL: \(newNode.url)")
            }
        }
    }
    
    private func processSitemapFile(at fileURL: URL, completion: @escaping ([ArticleNode]?, Error?) -> Void) {
        guard let xmlData = try? Data(contentsOf: fileURL) else {
            completion(nil, NSError(domain: "XMLDataError", code: 2, userInfo: nil))
            return
        }
        
        let parser = XMLParser(data: xmlData)
        parser.delegate = self
        if parser.parse() {
            let articles = prepareArticlesForDisplay(rootNode: rootNode)
            completion(articles, nil)
        } else {
            completion(nil, NSError(domain: "XMLParsingError", code: 3, userInfo: nil))
        }
    }
    
    private func getArticlePropertyName(from url: String) -> String {
        var propertyName = url.lowercased().replacingOccurrences(of: kOsmAndUserBaseURL, with: "")
        propertyName = propertyName.replacingOccurrences(of: "-", with: "_").replacingOccurrences(of: "/", with: "_")
        guard !propertyName.isEmpty, propertyName.last == "_" else { return propertyName }
        propertyName.removeLast()
        return propertyName
    }
    
    private func getSpecialArticleName(for key: String) -> String? {
        switch key {
        case "plugins":
            return localizedString("plugins_menu_group")
        case "plugins_accessibility":
            return localizedString("shared_string_accessibility")
        case "plugins_audio_video_notes":
            return localizedString("audionotes_plugin_name")
        case "plugins_development":
            return localizedString("debugging_and_development")
        case "plugins_external_sensors":
            return localizedString("external_sensors_plugin_name")
        case "plugins_mapillary":
            return localizedString("mapillary")
        case "plugins_osm_editing":
            return localizedString("osm_editing_plugin_name")
        case "plugins_osmand_tracker":
            return localizedString("tracker_item")
        case "plugins_parking":
            return localizedString("osmand_parking_plugin_name")
        case "plugins_trip_recording":
            return localizedString("record_plugin_name")
        case "plugins_weather":
            return localizedString("shared_string_weather")
        case "plugins_wikipedia":
            return localizedString("download_wikipedia_maps")
        case "plugins_online_map":
            return localizedString("shared_string_online_maps")
        case "plugins_ski_maps":
            return localizedString("plugin_ski_name")
        case "plugins_nautical_charts":
            return localizedString("plugin_nautical_name")
        case "plugins_contour_lines":
            return localizedString("srtm_plugin_name")
        case "search":
            return localizedString("shared_string_search")
        case "map_legend":
            return localizedString("map_legend")
        case "map":
            return localizedString("shared_string_map")
        case "map_configure_map_menu":
            return localizedString("configure_map")
        case "map_public_transport":
            return localizedString("poi_filter_public_transport")
        case "navigation":
            return localizedString("shared_string_navigation")
        case "troubleshooting_navigation":
            return localizedString("shared_string_navigation")
        case "navigation_guidance_navigation_settings":
            return localizedString("routing_settings_2")
        case "navigation_routing":
            return localizedString("route_parameters")
        case "navigation_setup_route_details":
            return localizedString("help_article_navigation_setup_route_details_name")
        case "personal_favorites":
            return localizedString("favorites_item")
        case "personal_global_settings":
            return localizedString("global_settings")
        case "personal_maps":
            return localizedString("shared_string_maps")
        case "personal_markers":
            return localizedString("shared_string_markers")
        case "personal_myplaces":
            return localizedString("shared_string_my_places")
        case "personal_osmand_cloud":
            return localizedString("osmand_cloud")
        case "personal_tracks":
            return localizedString("shared_string_gpx_tracks")
        case "plan_route_create_route":
            return localizedString("plan_route")
        case "plan_route_travel_guides":
            return localizedString("wikivoyage_travel_guide")
        case "purchases":
            return localizedString("purchases")
        case "search_search_address":
            return localizedString("address_search_desc")
        case "search_search_history":
            return localizedString("shared_string_search_history")
        case "start_with_download_maps":
            return localizedString("welmode_download_maps")
        case "troubleshooting":
            return localizedString("troubleshooting")
        case "navigation_setup":
            return localizedString("shared_string_setup_route")
        case "troubleshooting_setup":
            return localizedString("setup")
        case "widgets_configure_screen":
            return localizedString("layer_map_appearance")
        case "widgets_quick_action":
            return localizedString("configure_screen_quick_action")
        default:
            return nil
        }
    }
}

extension MenuHelpDataService {
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        currentElement = elementName
        if elementName == "url" {
            currentArticleNode = ArticleNode(title: "", url: "")
            currentURL = ""
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if currentElement == "loc" {
            currentURL += string.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "loc" {
            currentElement = ""
        } else if elementName == "url" {
            guard let node = currentArticleNode else { return }
            if currentURL.starts(with: "\(urlPrefix)/docs/user/") {
                node.url = currentURL
                addArticleNode(node, url: currentURL)
            }
        }
    }
}
