//
//  OAFavoritesSettingsItem.mm
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 26.11.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAFavoritesSettingsItem.h"
#import "OAAppSettings.h"
#import "OAGPXDocument.h"
#import "OASelectedGPXHelper.h"
#import "OsmAndApp.h"
#import "OAFavoriteItem.h"
#import "OAFavoritesHelper.h"

#include <OsmAndCore/IFavoriteLocation.h>

@interface OAFavoritesSettingsItem()

@property (nonatomic) NSMutableArray<OAFavoriteGroup *> *items;
@property (nonatomic) NSMutableArray<OAFavoriteGroup *> *appliedItems;
@property (nonatomic) NSMutableArray<OAFavoriteGroup *> *existingItems;

@end

@implementation OAFavoritesSettingsItem
{
    OAAppSettings *_settings;
}

@dynamic items, appliedItems, existingItems;

- (void) initialization
{
    [super initialization];

    _settings = [OAAppSettings sharedManager];
    const auto& allFavorites = [OsmAndApp instance].favoritesCollection->getFavoriteLocations();
    self.existingItems = [NSMutableArray arrayWithArray:[OAFavoritesHelper getGroupedFavorites:allFavorites]];
}

- (EOASettingsItemType) type
{
    return EOASettingsItemTypeFavorites;
}

- (NSString *) name
{
    return @"favourites";
}

- (NSString *) defaultFileExtension
{
    return @".gpx";
}

- (void) apply
{
    OsmAndAppInstance app = [OsmAndApp instance];
    NSArray<OAFavoriteGroup *> *newItems = [self getNewItems];
    if (newItems.count > 0 || self.duplicateItems.count > 0)
    {
        self.appliedItems = [NSMutableArray arrayWithArray:newItems];
        QList< std::shared_ptr<OsmAnd::IFavoriteLocation> > toDelete;
        for (OAFavoriteGroup *duplicate in self.duplicateItems)
        {
            if ([self shouldReplace])
            {
                OAFavoriteGroup *existingGroup = [self getGroup:duplicate.name];
                if (existingGroup)
                {
                    [self.existingItems removeObject:existingGroup];
                    NSArray<OAFavoriteItem *> *favoriteItems = existingGroup.points;
                    for (OAFavoriteItem *favoriteItem in favoriteItems)
                    {
                        toDelete.push_back(favoriteItem.favorite);
                    }
                }
            }
            [self.appliedItems addObject:[self shouldReplace] ? duplicate : [self renameItem:duplicate]];
        }
        app.favoritesCollection->removeFavoriteLocations(toDelete);
        NSArray<OAFavoriteItem *> *favourites = [NSArray arrayWithArray:[self getPointsFromGroups:self.appliedItems]];
        std::shared_ptr<OsmAnd::FavoriteLocationsGpxCollection> favoriteCollection(new OsmAnd::FavoriteLocationsGpxCollection());
        for (OAFavoriteItem *favorite in favourites)
            favoriteCollection->copyFavoriteLocation(favorite.favorite);
        app.favoritesCollection->mergeFrom(favoriteCollection);
        [app saveFavoritesToPermamentStorage];
    }
}

- (OAFavoriteGroup *) getGroup:(NSString *)nameId
{
    for (OAFavoriteGroup *group in self.existingItems)
    {
        if ([nameId isEqualToString:group.name])
            return group;
    }
    return nil;
}

- (BOOL) isDuplicate:(OAFavoriteGroup *)item
{
    NSString *name = item.name;
    for (OAFavoriteGroup *group in self.existingItems) {
        if ([name isEqualToString:group.name]) {
            return true;
        }
    }
    return NO;
}

- (NSArray<OAFavoriteItem *> *)getPointsFromGroups:(NSArray<OAFavoriteGroup *> *)groups
{
    NSMutableArray<OAFavoriteItem *> *favouriteItems = [NSMutableArray array];
    for (OAFavoriteGroup *group in groups)
        [favouriteItems addObjectsFromArray:group.points];
    return favouriteItems;
}

- (BOOL) shouldReadOnCollecting
{
    return YES;
}

- (OAFavoriteGroup *) renameItem:(OAFavoriteGroup *)item
{
    int number = 0;
    while (true)
    {
        number++;
        NSString *name = [NSString stringWithFormat:@"%@ (%d)", item.name, number];
        OAFavoriteGroup *renamedItem = [[OAFavoriteGroup alloc] initWithPoints:item.points name:name isVisible:item.isVisible color:item.color];
        if (![self isDuplicate:renamedItem])
        {
            for (OAFavoriteItem *point in renamedItem.points)
            {
                point.favorite->setGroup(QString::fromNSString(renamedItem.name));
            }
            return renamedItem;
        }
    }
    return nil;
}

- (OASettingsItemReader *) getReader
{
    return [[OAFavoritesSettingsItemReader alloc] initWithItem:self];
}

- (OASettingsItemWriter *)getWriter
{
    NSArray<OAFavoriteItem *> *favorites = [self getPointsFromGroups:self.items];
    OAGPXDocument *doc = [OAFavoritesHelper asGpxFile:favorites];
    return [self getGpxWriter:doc];
}

@end

#pragma mark - OAFavoritesSettingsItemReader

@implementation OAFavoritesSettingsItemReader

- (BOOL) readFromFile:(NSString *)filePath error:(NSError * _Nullable *)error
{
    const auto favoritesCollection = OsmAnd::FavoriteLocationsGpxCollection::tryLoadFrom(QString::fromNSString(filePath));
    if (favoritesCollection)
        [self.item.items addObjectsFromArray:[OAFavoritesHelper getGroupedFavorites:favoritesCollection->getFavoriteLocations()]];
    return YES;
}

@end
