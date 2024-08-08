//
//  MenuHelpDataService.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 05.12.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import UIKit

@objc protocol ArticleRepresentable {
    var title: String { get }
    var url: String { get }
}

@objcMembers
final class PopularArticle: NSObject, ArticleRepresentable {
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
final class ArticleNode: NSObject, ArticleRepresentable {
    var title: String
    var url: String
    var level: Int
    var type: String
    var childArticles: [ArticleNode]
    
    init(title: String, url: String, level: Int, type: String, childArticles: [ArticleNode] = []) {
        self.title = title
        self.url = url
        self.level = level
        self.type = type
        self.childArticles = childArticles
    }
}

@objc enum HelperDataItems: Int {
    case popularArticles
    case telegramChats
    case siteArticles
    
    var description: String {
        switch self {
        case .popularArticles:
            return "popularArticles"
        case .telegramChats:
            return "telegramChats"
        case .siteArticles:
            return "siteArticles"
        }
    }
}

@objc(OAMenuHelpDataService)
@objcMembers
final class MenuHelpDataService: NSObject, XMLParserDelegate {
    private let urlPrefix = "https://osmand.net"
    private var popularArticles: [PopularArticle] = []
    private var telegramChats: [TelegramChat] = []
    private var articles: [ArticleNode] = []
    private var rootNode: ArticleNode = ArticleNode(title: "Root", url: "", level: 1, type: "root")
    static let shared = MenuHelpDataService()
    
    private override init() { }
    
    func loadAndParseJson(from urlString: String, for dataItem: HelperDataItems, completion: @escaping (NSArray?, NSError?) -> Void) {
        if dataItem == .popularArticles, !popularArticles.isEmpty {
            completion(popularArticles as NSArray, nil)
            return
        } else if dataItem == .telegramChats, !telegramChats.isEmpty {
            completion(telegramChats as NSArray, nil)
            return
        } else if dataItem == .siteArticles, !rootNode.childArticles.isEmpty {
            completion(rootNode.childArticles as NSArray, nil)
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
                guard let jsonDict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                    DispatchQueue.main.async {
                        completion(nil, NSError(domain: "JSONConversionError", code: 2, userInfo: nil))
                    }
                    return
                }
                
                switch dataItem {
                case .popularArticles:
                    if let popularArticlesData = jsonDict["ios"] as? [String: Any],
                       let articles = popularArticlesData["popularArticles"] as? [String: String] {
                        popularArticles = articles.map { PopularArticle(title: $0.key, url: self.urlPrefix + $0.value) }
                        DispatchQueue.main.async {
                            completion(self.popularArticles as NSArray, nil)
                        }
                    }
                case .telegramChats:
                    if let telegramChatsData = jsonDict["ios"] as? [String: Any],
                       let chats = telegramChatsData["telegramChats"] as? [String: String] {
                        telegramChats = chats.map { TelegramChat(title: $0.key, url: $0.value) }
                        DispatchQueue.main.async {
                            completion(self.telegramChats as NSArray, nil)
                        }
                    }
                case .siteArticles:
                    let urlDocsPrefix = "/docs/user/"
                    if let articlesData = jsonDict["articles"] as? [[String: Any]] {
                        articles.removeAll()
                        for articleDict in articlesData {
                            if let title = articleDict["label"] as? String,
                               let level = articleDict["level"] as? Int,
                               let url = (articleDict["url"] as? String) ?? (level > 1 ? urlDocsPrefix + title : nil),
                               url.hasPrefix(urlDocsPrefix),
                               let type = articleDict["type"] as? String {
                                let articleNode = ArticleNode(title: title, url: self.urlPrefix + url, level: level, type: type)
                                addArticleNode(articleNode)
                                articles.append(articleNode)
                            }
                        }
                        
                        DispatchQueue.main.async {
                            completion(self.rootNode.childArticles as NSArray, nil)
                        }
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
    
    func getArticleName(from article: ArticleRepresentable) -> String {
        let articleId = getArticlePropertyName(from: article.url)
        if let specialName = getSpecialArticleName(for: articleId) {
            return specialName
        } else {
            let articleNameKey = "help_article_\(articleId)_name"
            let localized = localizedString(articleNameKey)
            return localized == articleNameKey ? article.title : localized
        }
    }
    
    private func addArticleNode(_ node: ArticleNode) {
        var parentNode: ArticleNode = rootNode
        while let lastChild = parentNode.childArticles.last, lastChild.level < node.level {
            parentNode = lastChild
        }
        
        let nodeAlreadyExists = parentNode.childArticles.contains { existingNode in
            existingNode.title == node.title && existingNode.level == node.level
        }
        
        if !nodeAlreadyExists {
            parentNode.childArticles.append(node)
        } else {
            debugPrint("Skipped adding duplicate article node: Title: \(node.title), Level: \(node.level)")
        }
    }
    
    private func getArticlePropertyName(from url: String) -> String {
        var propertyName = url.lowercased().replacingOccurrences(of: kOsmAndUserBaseURL, with: "")
        let charactersToReplace = CharacterSet(charactersIn: "-/ ")
        propertyName = propertyName.components(separatedBy: charactersToReplace).joined(separator: "_")
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
        case "setup_a_route":
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
