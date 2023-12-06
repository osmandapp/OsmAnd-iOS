//
//  HelpDataManager.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 05.12.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation
import UIKit

@objcMembers
class PopularArticle: NSObject {
    let title: String
    let url: String
    
    init(title: String, url: String) {
        self.title = title
        self.url = url
    }
}

@objcMembers
class TelegramChat: NSObject {
    let title: String
    let url: String
    
    init(title: String, url: String) {
        self.title = title
        self.url = url
    }
}

@objc(OAHelpDataManager)
@objcMembers
class HelpDataManager: NSObject {
    private let urlPrefix = "https://osmand.net"
    var popularArticles: [PopularArticle] = []
    var telegramChats: [TelegramChat] = []
    private static var sharedHelperInstance: HelpDataManager = {
        return HelpDataManager()
    }()
    
    static var sharedInstance: HelpDataManager {
        return sharedHelperInstance
    }
    
    func loadAndParseJson(from urlString: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(false)
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let data = data, error == nil else {
                print("Error downloading data: \(String(describing: error))")
                completion(false)
                return
            }
            
            do {
                if let jsonDict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let popularArticlesData = jsonDict["popularArticles"] as? [String: String],
                   let telegramChatsData = jsonDict["telegramChats"] as? [String: String] {
                    
                    self?.processPopularArticles(popularArticlesData)
                    self?.processTelegramChats(telegramChatsData)
                    completion(true)
                }
            } catch {
                print("Error parsing JSON: \(error)")
                completion(false)
            }
        }.resume()
    }
    
    private func processPopularArticles(_ data: [String: String]) {
        let orderedData = data.map { ($0.key, $0.value) }.sorted { $0.0 < $1.0 }
        popularArticles = orderedData.map { PopularArticle(title: $0.0, url: urlPrefix + $0.1) }
    }
    
    private func processTelegramChats(_ data: [String: String]) {
        let orderedData = data.map { ($0.key, $0.value) }.sorted { $0.0 < $1.0 }
        telegramChats = orderedData.map { TelegramChat(title: $0.0, url: $0.1) }
    }
    
    func getPopularArticles() -> [PopularArticle] {
        return popularArticles
    }
    
    func getTelegramChats() -> [TelegramChat] {
        return telegramChats
    }
    
    func getTelegramChatsCount() -> String {
        return String(telegramChats.count)
    }
}
