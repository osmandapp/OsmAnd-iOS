//
//  HelpDetailsViewController.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 05.12.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import UIKit

@objc(OAHelpDetailsViewController)
@objcMembers
final class HelpDetailsViewController: OABaseNavbarViewController {
    var telegramChats: [TelegramChat] = []
    var childArticles: [ArticleNode] = []
    var titleText: String?
    
    init(childArticles: [ArticleNode], title: String) {
        self.childArticles = childArticles
        self.titleText = title
        super.init(nibName: "OABaseNavbarViewController", bundle: nil)
        initTableData()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if titleText == localizedString("telegram_chats") {
            loadAndParseJson()
        } else {
            generateChildArticlesData()
        }
    }
    
    override func getTitle() -> String? {
        titleText
    }
    
    override func getNavbarColorScheme() -> EOABaseNavbarColorScheme {
        .orange
    }
    
    override func hideFirstHeader() -> Bool {
        true
    }
    
    override func getRow(_ indexPath: IndexPath?) -> UITableViewCell? {
        guard let indexPath else { return nil }
        let item = tableData.item(for: indexPath)
        var cell = tableView.dequeueReusableCell(withIdentifier: OASimpleTableViewCell.getIdentifier()) as? OASimpleTableViewCell
        if cell == nil {
            let nib = Bundle.main.loadNibNamed(OASimpleTableViewCell.getIdentifier(), owner: self, options: nil)
            cell = nib?.first as? OASimpleTableViewCell
            cell?.leftIconView.tintColor = .iconColorDefault
        }
        if let cell {
            cell.descriptionVisibility(item.key == "telegramChats")
            cell.titleLabel.text = item.title
            cell.descriptionLabel.text = item.descr
            cell.leftIconView.image = UIImage.templateImageNamed(item.iconName)
            cell.accessoryType = (item.obj(forKey: "childArticles") as? [ArticleNode])?.isEmpty == false ? .disclosureIndicator : .none
        }
        return cell
    }
    
    override func onRowSelected(_ indexPath: IndexPath?) {
        guard let indexPath else { return }
        let item = tableData.item(for: indexPath)
        if item.key == "telegramChats" {
            if let urlString = item.obj(forKey: "url") as? String,
               let url = URL(string: urlString) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        } else if item.key == "childArticle" {
            guard let title = item.title else { return }
            if let childArticles = item.obj(forKey: "childArticles") as? [ArticleNode], !childArticles.isEmpty {
                let vc = HelpDetailsViewController(childArticles: childArticles, title: title)
                navigationController?.pushViewController(vc, animated: true)
            } else if let urlString = item.obj(forKey: "url") as? String {
                guard let webView = OAWebViewController(urlAndTitle: urlString, title: title) else { return }
                navigationController?.pushViewController(webView, animated: true)
            }
        }
    }
    
    private func generateTelegramChatsData() {
        tableData.clearAllData()
        let telegramChatsSection = tableData.createNewSection()
        for chat in telegramChats {
            let title = removeTextInBrackets(from: chat.title)
            let url = chat.url
            let chatRow = telegramChatsSection.createNewRow()
            chatRow.cellType = OASimpleTableViewCell.getIdentifier()
            chatRow.key = "telegramChats"
            chatRow.title = title
            chatRow.descr = url
            chatRow.iconName = "ic_custom_logo_telegram"
            chatRow.setObj(url, forKey: "url")
        }
    }
    
    private func generateChildArticlesData() {
        tableData.clearAllData()
        let childArticlesSection = tableData.createNewSection()
        for article in childArticles {
            let title = MenuHelpDataService.shared.getArticleName(from: article.url)
            let url = kDocsBaseURL + article.url
            let articleRow = childArticlesSection.createNewRow()
            articleRow.cellType = OASimpleTableViewCell.getIdentifier()
            articleRow.key = "childArticle"
            articleRow.title = title
            articleRow.iconName = "ic_custom_book_info"
            articleRow.setObj(url, forKey: "url")
            articleRow.setObj(article.childArticles, forKey: "childArticles")
        }
    }
    
    private func loadAndParseJson() {
        MenuHelpDataService.shared.loadAndParseJson(from: kPopularArticlesAndTelegramChats, for: .telegramChats) { [weak self] result, error in
            guard let self else { return }
            
            if error != nil {
                debugPrint(error as Any)
            } else if let chats = result as? [TelegramChat] {
                self.telegramChats = chats
                self.generateTelegramChatsData()
                self.tableView.reloadData()
            }
        }
    }
    
    private func removeTextInBrackets(from string: String) -> String {
        let pattern = "\\s*\\(.*?\\)"
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let range = NSRange(string.startIndex..., in: string)
            return regex.stringByReplacingMatches(in: string, options: [], range: range, withTemplate: "")
        } catch {
            return string
        }
    }
}
