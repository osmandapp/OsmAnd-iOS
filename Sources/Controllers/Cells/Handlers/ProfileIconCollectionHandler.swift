//
//  ProfileIconCollectionHandler.swift
//  OsmAnd
//
//  Created by Vitaliy Sova on 25.05.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

@objcMembers
final class ProfileIconCollectionHandler: BasePoiIconCollectionHandler {
    static var cachedCategories = [IconsAppearanceCategory]()
    static var cachedCategoriesByKeyName = [String: IconsAppearanceCategory]()
    
    override init() {
        super.init()
        setup()
        collectionType = .profileIconCategories
    }
    
    override func initIconCategories() {
        if Self.cachedCategories.isEmpty {
            initActivitiesCategory()
            addProfileIconsCategory()
            initOriginalCategory()
            initAssetsCategories()
            initPoiCategories()
            categories.forEach { categoriesByKeyName[$0.key] = $0 }
            Self.cachedCategories = categories
            Self.cachedCategoriesByKeyName = categoriesByKeyName
            loadAllIconsData()
        } else {
            categories = Self.cachedCategories
            categoriesByKeyName = Self.cachedCategoriesByKeyName
        }

        sortCategories()
        initLastUsedCategory(isFirst: true)
        initFilteredCategories()
    }
    
    override func sortCategories() {
        sortCategoriesAndMoveKeyUp(ACTIVITIES_KEY)
    }
    
    override func saveLastUsed(_ icons: [String]) {
        OAAppSettings.sharedManager().lastUsedProfileIcons.set(icons)
    }
    
    override func getLastUsed() -> [String] {
        return OAAppSettings.sharedManager().lastUsedProfileIcons.get()
    }
}
