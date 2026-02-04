//
//  AmenityInfoRowParams.swift
//  OsmAnd
//
//  Created by Max Kojin on 15/01/26.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

final class AmenityInfoRowParams: NSObject {
    
    var key: String?
    //var icon: UIImage? //TODO: delete, not needed?
    var iconName: String?
    var textPrefix: String?
    var text: String?
    var hiddenUrl: String?
    var collapsableView: OACollapsableView?
    var textColor: UIColor?
    var isWiki = false
    var isText = false
    var needLinks = false
    var isPhoneNumber = false
    var isUrl = false
    var order = 0
    var name: String?
    var matchWidthDivider = false
    var textLinesLimit = 0
    
    init(builder: Builder) {
        self.key = builder.key
        self.iconName = builder.iconName
        self.textPrefix = builder.textPrefix
        self.text = builder.text
        self.hiddenUrl = builder.hiddenUrl
        self.collapsableView = builder.collapsableView
        self.textColor = builder.textColor
        self.isWiki = builder.isWiki
        self.isText = builder.isText
        self.needLinks = builder.needLinks
        self.isPhoneNumber = builder.isPhoneNumber
        self.isUrl = builder.isUrl
        self.order = builder.order
        self.name = builder.name
        self.matchWidthDivider = builder.matchWidthDivider
        self.textLinesLimit = builder.textLinesLimit
    }
    
    func collapsable() -> Bool {
        collapsableView != nil
    }
    
    
    final class Builder: NSObject {
        
        var key: String?
        //var icon: UIImage? //TODO: delete?
        var iconName: String?
        var textPrefix: String? = ""
        var text: String?
        var hiddenUrl: String?
        var collapsableView: OACollapsableView?
        var textColor: UIColor?
        var isWiki = false
        var isText = false
        var needLinks = false
        var isPhoneNumber = false
        var isUrl = false
        var order = 0
        var name: String?
        var matchWidthDivider = false
        var textLinesLimit = 0
        
        init(key: String) {
            self.key = key
        }
        
        func setTextPrefixIfNotPresent(_ textPrefix: String?) {
            if !hasTextPrefix() {
                self.textPrefix = textPrefix
            }
        }
        
        func setTextIfNotPresent(_ text: String?) {
            if !hasText() {
                self.text = text
            }
        }
        
        func hasIcon() -> Bool {
            if let iconName, !iconName.isEmpty {
                return true
            }
            return false
        }
        
        func hasTextPrefix() -> Bool {
            if let textPrefix, !textPrefix.isEmpty {
                return true
            }
            return false
        }
        
        func hasText() -> Bool {
            if let text, !text.isEmpty {
                return true
            }
            return false
        }
        
        func hasHiddenUrl() -> Bool {
            if let hiddenUrl, !hiddenUrl.isEmpty {
                return true
            }
            return false
        }
        
        func isCollapsable() -> Bool {
            collapsableView != nil
        }
        
        func isNeedLinks() -> Bool {
            needLinks && collapsableView == nil
        }
        
        func isDescription() -> Bool {
            isText && iconName == AmenityUIHelper.defaultAmenityIconName
        }
        
        func build() -> AmenityInfoRowParams {
            AmenityInfoRowParams(builder: self)
        }
    }
}
