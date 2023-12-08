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

@objc(OAMenuHelpDataService)
@objcMembers
final class MenuHelpDataService: NSObject {
    private let urlPrefix = "https://osmand.net"
    var popularArticles: [PopularArticle] = []
    var telegramChats: [TelegramChat] = []
    static let shared = MenuHelpDataService()
    
    private override init() { }
    
    func loadAndParseJson(from urlString: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async {
                completion(false)
            }
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self = self else { return }
            guard let data, error == nil else {
                DispatchQueue.main.async {
                    debugPrint("Error downloading data: \(String(describing: error))")
                    completion(false)
                }
                return
            }
            
            do {
                guard let jsonDict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                    DispatchQueue.main.async {
                        debugPrint("Error: Unable to convert JSON to Dictionary")
                        completion(false)
                    }
                    return
                }
                
                if let popularArticlesData = jsonDict["popularArticles"] as? [String: String],
                   let telegramChatsData = jsonDict["telegramChats"] as? [String: String] {
                    
                    self.processPopularArticles(popularArticlesData)
                    self.processTelegramChats(telegramChatsData)
                    DispatchQueue.main.async {
                        completion(true)
                    }
                } else {
                    debugPrint("Error: Required data not found in JSON")
                    completion(false)
                }
            } catch {
                DispatchQueue.main.async {
                    debugPrint("Error parsing JSON:", error)
                    completion(false)
                }
            }
        }.resume()
    }
    
    func getPopularArticles() -> [PopularArticle] {
        popularArticles
    }
    
    func getTelegramChats() -> [TelegramChat] {
        telegramChats
    }
    
    func getTelegramChatsCount() -> String {
        String(telegramChats.count)
    }
    
    private func processPopularArticles(_ data: [String: String]) {
        let orderedData = data.map { ($0.key, $0.value) }.sorted { $0.0 < $1.0 }
        popularArticles = orderedData.map { PopularArticle(title: $0.0, url: urlPrefix + $0.1) }
    }
    
    private func processTelegramChats(_ data: [String: String]) {
        let orderedData = data.map { ($0.key, $0.value) }.sorted { $0.0 < $1.0 }
        telegramChats = orderedData.map { TelegramChat(title: $0.0, url: $0.1) }
    }
}
