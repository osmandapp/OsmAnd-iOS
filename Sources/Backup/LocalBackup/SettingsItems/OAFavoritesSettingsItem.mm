//
//  OAFavoritesSettingsItem.mm
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 26.11.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAFavoritesSettingsItem.h"
#import "OAAppSettings.h"
#import "OASelectedGPXHelper.h"
#import "OsmAndApp.h"
#import "OAFavoriteItem.h"
#import "OAFavoritesHelper.h"
#import "OAPlugin.h"
#import "OAParkingPositionPlugin.h"
#import "OAIndexConstants.h"
#import "OAPluginsHelper.h"
#import "Localization.h"
#import "OsmAndSharedWrapper.h"

#define APPROXIMATE_FAVOURITE_SIZE_BYTES 470

@interface OAFavoritesSettingsItem()

@property (nonatomic) NSMutableArray<OAFavoriteGroup *> *items;
@property (nonatomic) NSMutableArray<OAFavoriteGroup *> *appliedItems;
@property (nonatomic) NSMutableArray<OAFavoriteGroup *> *existingItems;
@property (nonatomic) NSMutableArray<OAFavoriteGroup *> *duplicateItems;

@end

@implementation OAFavoritesSettingsItem
{
    OAAppSettings *_settings;
    
    OAFavoriteGroup *_personalGroup;
}

@dynamic items, appliedItems, existingItems, duplicateItems;

- (void) initialization
{
    [super initialization];

    _settings = [OAAppSettings sharedManager];
    self.existingItems = [OAFavoritesHelper getFavoriteGroups];
}

- (EOASettingsItemType) type
{
    return EOASettingsItemTypeFavorites;
}

- (OAFavoriteGroup *) getSingleGroup
{
    return self.items.count == 1 ? self.items[0] : nil;
}

- (NSString *) name
{
    OsmAndAppInstance app = OsmAndApp.instance;
    OAFavoriteGroup *singleGroup = [self getSingleGroup];
    NSString *groupName = singleGroup ? singleGroup.name : nil;
    return ![groupName isEmpty]
            ? [NSString stringWithFormat:@"%@%@%@", app.favoritesFilePrefix, app.favoritesGroupNameSeparator, groupName]
            : app.favoritesFilePrefix;
}

- (NSString *) getPublicName
{
    OsmAndAppInstance app = OsmAndApp.instance;
    OAFavoriteGroup *singleGroup = [self getSingleGroup];
    NSString *groupName = singleGroup ? singleGroup.name : nil;
    NSString *fileName = self.fileName;
    if (![groupName isEmpty])
    {
        return [NSString stringWithFormat:OALocalizedString(@"ltr_or_rtl_combine_via_space"), OALocalizedString(@"favorites_item"), groupName];
    }
    else if (![fileName isEmpty])
    {
        groupName = [[[app getGroupName:fileName] stringByReplacingOccurrencesOfString:app.favoritesFilePrefix withString:@""] stringByReplacingOccurrencesOfString:GPX_FILE_EXT withString:@""];
        if ([groupName hasPrefix:app.favoritesGroupNameSeparator])
            groupName = [groupName substringFromIndex:1];

        return [NSString stringWithFormat:OALocalizedString(@"ltr_or_rtl_combine_via_space"), OALocalizedString(@"favorites_item"), groupName];
    }
    else
    {
        return OALocalizedString(@"favorites_item");
    }
}

- (NSString *) defaultFileName
{
    return [[OsmAndApp.instance getGroupFileName:self.name] stringByAppendingString:self.defaultFileExtension];
}

- (NSString *) defaultFileExtension
{
    return GPX_FILE_EXT;
}

- (long) localModifiedTime
{
    OAFavoriteGroup *singleGroup = [self getSingleGroup];
    NSString *groupFilePath = singleGroup ? [OsmAndApp.instance favoritesStorageFilename:singleGroup.name] : nil;
    NSFileManager *manager = NSFileManager.defaultManager;
    if (groupFilePath && [manager fileExistsAtPath:groupFilePath])
    {
        NSError *err = nil;
        NSDictionary *attrs = [manager attributesOfItemAtPath:groupFilePath error:&err];
        return !err ? attrs.fileModificationDate.timeIntervalSince1970 : 0;
    }
    
    NSString *favPath = OsmAndApp.instance.favoritesLegacyStorageFilename;
    if ([manager fileExistsAtPath:favPath])
    {
        NSError *err = nil;
        NSDictionary *attrs = [manager attributesOfItemAtPath:favPath error:&err];
        if (!err)
            return attrs.fileModificationDate.timeIntervalSince1970;
    }
    return 0;
}

- (void) setLocalModifiedTime:(long)localModifiedTime
{
    OAFavoriteGroup *singleGroup = [self getSingleGroup];
    NSString *groupFilePath = singleGroup ? [OsmAndApp.instance favoritesStorageFilename:singleGroup.name] : nil;
    NSFileManager *manager = NSFileManager.defaultManager;
    if (groupFilePath && [manager fileExistsAtPath:groupFilePath])
    {
        [manager setAttributes:@{ NSFileModificationDate : [NSDate dateWithTimeIntervalSince1970:localModifiedTime] } ofItemAtPath:groupFilePath error:nil];
    }
    else
    {
        NSString *favPath = OsmAndApp.instance.favoritesLegacyStorageFilename;
        if ([manager fileExistsAtPath:favPath])
            [manager setAttributes:@{ NSFileModificationDate : [NSDate dateWithTimeIntervalSince1970:localModifiedTime] } ofItemAtPath:favPath error:nil];
    }
}

- (void) apply
{
    NSArray<OAFavoriteGroup *> *newItems = [self getNewItems];
    if (_personalGroup)
        [self.duplicateItems addObject:_personalGroup];
    if (newItems.count > 0 || self.duplicateItems.count > 0)
    {
        self.appliedItems = [NSMutableArray arrayWithArray:newItems];
        for (OAFavoriteGroup *duplicate in self.duplicateItems)
        {
            BOOL isPersonal = duplicate.isPersonal;
            BOOL shouldReplace = [self shouldReplace] || isPersonal;
            if (shouldReplace)
            {
                OAFavoriteGroup *existingGroup = [OAFavoritesHelper getGroupByName:duplicate.name];
                if (existingGroup)
                    [OAFavoritesHelper deleteFavorites:existingGroup.points.copy saveImmediately:NO];
            }
            if (!isPersonal)
            {
                [self.appliedItems addObject:shouldReplace ? duplicate : [self renameItem:duplicate]];
            }
            else
            {
                OAParkingPositionPlugin *plugin = (OAParkingPositionPlugin *) [OAPluginsHelper getPlugin:OAParkingPositionPlugin.class];
                for (OAFavoriteItem *point in duplicate.points)
                {
                    if (plugin && point.specialPointType == OASpecialPointType.PARKING)
                    {
                        [plugin clearParkingPosition];
                        [plugin updateParkingPoint:point];
                    }
                }
            }
        }
        @synchronized (self.class)
        {
            for (OAFavoriteGroup *group in self.appliedItems)
            {
                [OAFavoritesHelper addFavorites:group.points
                                  lookupAddress:NO
                                    sortAndSave:group == self.appliedItems.lastObject
                                    pointsGroup:[group toPointsGroup]];
            }
        }
    }
}

- (long) getEstimatedItemSize:(OAFavoriteGroup *)item
{
    return item.points.count * APPROXIMATE_FAVOURITE_SIZE_BYTES;
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
    if (item.isPersonal)
    {
        _personalGroup = item;
        return NO;
    }
    for (OAFavoriteGroup *group in self.existingItems)
    {
        if ([name isEqualToString:group.name])
            return YES;
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

- (void)deleteItem:(OAFavoriteGroup *)item
{
    [OAFavoritesHelper deleteFavoriteGroups:@[item] andFavoritesItems:nil];
    [OAFavoritesHelper saveCurrentPointsIntoFile];
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
    OASGpxFile *gpxFile = [OAFavoritesHelper asGpxFile:self.items];
    return [self getGpxWriter:gpxFile];
}

@end

#pragma mark - OAFavoritesSettingsItemReader

@implementation OAFavoritesSettingsItemReader

- (BOOL) readFromFile:(NSString *)filePath error:(NSError * _Nullable *)error
{
    if (self.item.read)
    {
        if (error)
            *error = [NSError errorWithDomain:kSettingsItemErrorDomain code:kSettingsItemErrorCodeAlreadyRead userInfo:nil];

        return NO;
    }

    OASKFile *file = [[OASKFile alloc] initWithFilePath:filePath];
    OASGpxFile *gpxFile = [OASGpxUtilities.shared loadGpxFileFile:file];
    if (gpxFile)
    {
        NSMutableDictionary<NSString *, OAFavoriteGroup *> *flatGroups = [NSMutableDictionary dictionary];
        NSArray<OAFavoriteItem *> *favorites = [OAFavoritesHelper wptAsFavorites:gpxFile.getPointsList defaultCategory:@""];
        for (OAFavoriteItem *point in favorites)
        {
            OAFavoriteGroup *group = flatGroups[[point getCategory]];
            if (!group)
            {
                group = [self createFavoriteGroup:gpxFile point:point];
                flatGroups[group.name] = group;
                [self.item.items addObject:group];
            }
            [group.points addObject:point];
        }
    }

    self.item.read = YES;
    return YES;
}

- (OAFavoriteGroup *)createFavoriteGroup:(OASGpxFile *)gpxFile point:(OAFavoriteItem *)point
{
    OAFavoriteGroup *favoriteGroup = [[OAFavoriteGroup alloc] initWithPoint:point];
    OASGpxUtilitiesPointsGroup *pointsGroup = gpxFile.pointsGroups[favoriteGroup.name];
    if (pointsGroup)
    {
        favoriteGroup.color = UIColorFromRGB(pointsGroup.color);
        favoriteGroup.iconName = pointsGroup.iconName;
        favoriteGroup.backgroundType = pointsGroup.backgroundType;
    }
    return favoriteGroup;
}

@end
