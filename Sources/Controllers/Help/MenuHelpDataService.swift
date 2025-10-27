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

@objcMembers
final class MenuHelpDataService: NSObject {
    static let shared = MenuHelpDataService()
    
    private let docsPrefix = "/docs/user/"
    
    private(set) var popularArticles: [PopularArticle] = []
    private(set) var telegramChats: [TelegramChat] = []
    private(set) var languages: [String] = []
    private(set) var rootNode = ArticleNode(title: "Root", url: "", level: 1, type: "root")
    
    private var articles: [ArticleNode] = []
    private var isLoading = false
    private var pendingCompletions: [(NSError?) -> Void] = []
    
    private override init() {}
    
    func fetchData(completion: ((NSError?) -> Void)? = nil) {
        if hasContent() {
            if let completion {
              return executeOnMainThread { completion(nil) }
            }
        }
        
        if let completion {
            pendingCompletions.append(completion)
        }
        
        guard !isLoading else {
            return
        }
        
        isLoading = true
        
        guard let url = URL(string: kPopularArticlesAndTelegramChats) else {
            finishLoading(with: Self.errorInvalidURL)
            return
        }
        
        isLoading = true
        
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self else { return }
            defer { isLoading = false }
            
            if let error = error as NSError? {
                finishLoading(with: error)
                return
            }
            
            guard let data else {
                finishLoading(with: Self.errorNoData)
                return
            }
            
            do {
                guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    self.finishLoading(with: Self.errorInvalidJSON)
                    return
                }
                parseHelperData(json)
                finishLoading(with: nil)
            } catch {
                finishLoading(with: error as NSError)
            }
        }.resume()
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
    
    private func hasContent() -> Bool {
        !popularArticles.isEmpty || !telegramChats.isEmpty || !languages.isEmpty
    }
    
    private func finishLoading(with error: NSError?) {
        let completions = pendingCompletions
        pendingCompletions.removeAll()
        executeOnMainThread({
            completions.forEach { $0(error) }
        })
    }
    
    // MARK: - Parsing
    
    private func parseHelperData(_ json: [String: Any]) {
        popularArticles.removeAll()
        telegramChats.removeAll()
        articles.removeAll()
        languages.removeAll()
        rootNode.childArticles.removeAll()
        
        // iOS section
        if let iosData = json["ios"] as? [String: Any] {
            if let popular = iosData["popularArticles"] as? [String: String] {
                popularArticles = popular.map { PopularArticle(title: $0.key, url: OSMAND_URL + $0.value) }
            }
            
            if let chats = iosData["telegramChats"] as? [String: String] {
                telegramChats = chats.map { TelegramChat(title: $0.key, url: $0.value) }
            }
        }
        
        if let languages = json["languages"] as? [String] {
            self.languages = languages
        }
        
        // Articles
        if let articlesData = json["articles"] as? [[String: Any]] {
            for item in articlesData {
                guard
                    let title = item["label"] as? String,
                    let level = item["level"] as? Int,
                    let type = item["type"] as? String
                else { continue }
                
                let url = (item["url"] as? String) ?? (level > 1 ? docsPrefix + title : "")
                guard url.hasPrefix(docsPrefix) else { continue }
                
                let node = ArticleNode(title: title, url: OSMAND_URL + url, level: level, type: type)
                addArticleNode(node)
                articles.append(node)
            }
        }
    }
    
    private func addArticleNode(_ node: ArticleNode) {
        var parent = rootNode
        while let lastChild = parent.childArticles.last, lastChild.level < node.level {
            parent = lastChild
        }
        
        guard !parent.childArticles.contains(where: { $0.title == node.title && $0.level == node.level }) else {
            debugPrint("Skipped duplicate article node: \(node.title)")
            return
        }
        parent.childArticles.append(node)
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
        case "search", "web_web_search":
            return localizedString("shared_string_search")
        case "map_legend":
            return localizedString("map_legend")
        case "map", "web_web_map":
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
        case "personal_osmand_cloud", "web_web_cloud":
            return localizedString("osmand_cloud")
        case "personal_tracks", "map_tracks_tracks_article":
            return localizedString("shared_string_gpx_tracks")
        case "plan_route_create_route", "web_planner":
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
        case "route_parameters":
            return localizedString("help_article_navigation_routing_name")
        case "personal_maps_resources":
            return localizedString("res_mapsres")
        case "plugins_topography":
            return localizedString("srtm_plugin_name")
        case "plugins_vehicle_metrics":
            return localizedString("obd_plugin_name")
        case "web":
            return localizedString("website")
        default:
            return nil
        }
    }
}

// MARK: - Named Errors
extension MenuHelpDataService {
    private static let errorDomain = "MenuHelpDataService"
    
    @objc static let errorInvalidURL = NSError(domain: errorDomain, code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid help structure URL"])
    @objc static let errorNoData = NSError(domain: errorDomain, code: 2, userInfo: [NSLocalizedDescriptionKey: "No data received from server"])
    @objc static let errorInvalidJSON = NSError(domain: errorDomain, code: 3, userInfo: [NSLocalizedDescriptionKey: "Invalid help structure JSON"])
}
