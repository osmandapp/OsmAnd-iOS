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
final class MenuHelpDataService: NSObject {
    private let urlPrefix = "https://osmand.net"
    private var popularArticles: [PopularArticle] = []
    private var telegramChats: [TelegramChat] = []
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
    
    private func processPopularArticles(_ data: [String: String]) -> [PopularArticle] {
        let orderedData = data.map { ($0.key, $0.value) }.sorted { $0.0 < $1.0 }
        return orderedData.map { PopularArticle(title: $0.0, url: urlPrefix + $0.1) }
    }
    
    private func processTelegramChats(_ data: [String: String]) -> [TelegramChat] {
        let orderedData = data.map { ($0.key, $0.value) }.sorted { $0.0 < $1.0 }
        return orderedData.map { TelegramChat(title: $0.0, url: $0.1) }
    }
}
