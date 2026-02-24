//
//  OAFavoritesHelper.m
//  OsmAnd
//
//  Created by Alexey Kulish on 23/12/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAFavoritesHelper.h"
#import "OsmAndApp.h"
#import "OALocationPoint.h"
#import "OAFavoriteItem.h"
#import "Localization.h"
#import "OAColors.h"
#import "OAUtilities.h"
#import "OADefaultFavorite.h"
#import "OAAppSettings.h"
#import "OAGPXDocumentPrimitives.h"
#import "OAParkingPositionPlugin.h"
#import "OAPlugin.h"
#import "OAIndexConstants.h"
#import "OAAppVersion.h"
#import "OAGPXAppearanceCollection.h"
#import "OANativeUtilities.h"
#import "OAFavoritesSettingsItem.h"
#import "OAPluginsHelper.h"
#import "OsmAndSharedWrapper.h"

#import <EventKit/EventKit.h>
#import "OsmAnd_Maps-Swift.h"

#include <OsmAndCore.h>
#include <OsmAndCore/ArchiveWriter.h>
#include <OsmAndCore/Utilities.h>

#define BACKUP_MAX_COUNT 10
#define BACKUP_MAX_PER_DAY 3

// NOTE: If the file name contains "\" macOS and iOS interpret it as a folder/subfolder. Additionally, ArchiveReader replaces "\" with "/". We do not allow the user to use this symbol in the file name.
static NSCharacterSet * const kIllegalFileNameCharacters = [NSCharacterSet characterSetWithCharactersInString:@"\\"];

@implementation OAFavoritesHelper

static OAObservable *_favoritesCollectionChangedObservable;
static OAObservable *_favoriteChangedObservable;
static std::shared_ptr<OsmAnd::FavoriteLocationsGpxCollection> _favoritesCollection;
static NSArray<OAFavoriteItem *> *_cachedFavoritePoints;
static NSArray<OAFavoriteGroup *> *_favoriteGroups;
static NSMutableDictionary<NSString *, OAFavoriteGroup *> *_flatGroups;
static NSArray<NSString *> *_flatBackgroundIcons;
static NSArray<NSString *> *_flatBackgroundContourIcons;
static NSOperationQueue *_favQueue;
static NSOperationQueue *_favCollectionQueue;

+ (void)initFavorites
{
    _favQueue = [[NSOperationQueue alloc] init];
    _favQueue.maxConcurrentOperationCount = 1;
    _favQueue.qualityOfService = NSQualityOfServiceUtility;
    _favCollectionQueue = [[NSOperationQueue alloc] init];
    _favCollectionQueue.maxConcurrentOperationCount = 1;
    _favCollectionQueue.qualityOfService = NSQualityOfServiceUtility;

    [self initFavoritesCollection];

    OsmAndAppInstance app = [OsmAndApp instance];
    // Sync favorites filename with android version
    NSString *oldfFavoritesFilename = app.documentsDir.filePath(QLatin1String("Favorites.gpx")).toNSString();
    NSString *favoritesLegacyFilename = app.favoritesLegacyStorageFilename;
    if ([[NSFileManager defaultManager] fileExistsAtPath:oldfFavoritesFilename] && ![[NSFileManager defaultManager] fileExistsAtPath:favoritesLegacyFilename])
    {
        NSError *error = nil;
        [[NSFileManager defaultManager] moveItemAtPath:oldfFavoritesFilename toPath:favoritesLegacyFilename error:&error];
        if (error)
            NSLog(@"Error moving file: %@ to %@ - %@", oldfFavoritesFilename, favoritesLegacyFilename, [error localizedDescription]);
    }

    // Move legacy favorites backup folder to new location
    NSString *oldFavoritesBackupPath = [app.documentsPath stringByAppendingPathComponent:@"favourites_backup"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:oldFavoritesBackupPath] && ![[NSFileManager defaultManager] fileExistsAtPath:app.favoritesBackupPath])
    {
        NSError *error = nil;
        [[NSFileManager defaultManager] moveItemAtPath:oldFavoritesBackupPath toPath:app.favoritesBackupPath error:&error];
        if (error)
            NSLog(@"Error moving dir: %@ to %@ - %@", oldFavoritesBackupPath, app.favoritesBackupPath, [error localizedDescription]);
    }

    BOOL legacyFavoritesExists = [[NSFileManager defaultManager] fileExistsAtPath:favoritesLegacyFilename];
    if (legacyFavoritesExists)
    {
        NSMutableDictionary<NSString *, OAFavoriteGroup *> *groups = [NSMutableDictionary dictionary];
         OASGpxFile *gpx = [self loadGpxFile:favoritesLegacyFilename];
        [self collectFavoriteGroups:gpx favoriteGroups:groups legacy:YES];
        [self saveFile:groups.allValues file:[app favoritesStorageFilename:@"old"]];
        [[NSFileManager defaultManager] removeItemAtPath:favoritesLegacyFilename error:nil];
    }

    [self loadFavorites];
}

+ (void)initFavoritesCollection
{
    _favoritesCollection.reset(new OsmAnd::FavoriteLocationsGpxCollection());
    _favoritesCollectionChangedObservable = [[OAObservable alloc] init];
    _favoriteChangedObservable = [[OAObservable alloc] init];
    _favoritesCollection->collectionChangeObservable
        .attach(reinterpret_cast<OsmAnd::IObservable::Tag>((__bridge const void*)self),
                [self]
                (const OsmAnd::IFavoriteLocationsCollection* const collection)
                {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_favoritesCollectionChangedObservable notifyEventWithKey:self];
            });
        });
    _favoritesCollection->favoriteLocationChangeObservable
        .attach(reinterpret_cast<OsmAnd::IObservable::Tag>((__bridge const void*)self),
                [self]
                (const OsmAnd::IFavoriteLocationsCollection* const collection,
                 const std::shared_ptr<const OsmAnd::IFavoriteLocation>& favoriteLocation)
                {
            NSString *title = favoriteLocation->getTitle().toNSString();
            dispatch_async(dispatch_get_main_queue(), ^{
                [_favoriteChangedObservable notifyEventWithKey:self andValue:title];
            });
        });
}

+ (void)loadFavorites
{
    _cachedFavoritePoints = @[];
    _flatGroups = [self loadGroups];
    _favoriteGroups = [_flatGroups.allValues copy];

    [self sortAll];
    [self recalculateCachedFavPoints];
    [[OAGPXAppearanceCollection sharedInstance] saveFavoriteColorsIfNeeded:_favoriteGroups];
}

+ (const std::shared_ptr<OsmAnd::FavoriteLocationsGpxCollection> &)getFavoritesCollection;
{
    if (_favoritesCollection == nullptr)
        [self initFavoritesCollection];
    return _favoritesCollection;
}

+ (NSMutableDictionary<NSString *, OAFavoriteGroup *> *)loadGroups
{
    NSMutableDictionary<NSString *, OAFavoriteGroup *> *groups = [NSMutableDictionary dictionary];
    NSArray<NSString *> *files = [self getGroupFiles];
    if (files.count > 0)
        for (NSString *file in files)
            [self loadFileGroups:file groups:groups];

    return groups;
}

+ (void)loadFileGroups:(NSString *)file groups:(NSMutableDictionary<NSString *, OAFavoriteGroup *> *)groups
{
    OASGpxFile *gpx = [self loadGpxFile:file];
    [self collectFavoriteGroups:gpx favoriteGroups:groups legacy:NO];
}

+ (void)collectFavoriteGroups:(OASGpxFile *)gpxFile
               favoriteGroups:(NSMutableDictionary<NSString *, OAFavoriteGroup *> *)favoriteGroups
                       legacy:(BOOL)legacy
{
    [gpxFile.pointsGroups enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, OASGpxUtilitiesPointsGroup * _Nonnull pointsGroup, BOOL * _Nonnull stop) {
        OAFavoriteGroup *favoriteGroup = [OAFavoriteGroup fromPointsGroup:pointsGroup];
        NSString *groupKey = !legacy ? key : [key stringByAppendingString:@"-old"];
        favoriteGroups[groupKey] = favoriteGroup;
    }];
}

+ (OASGpxFile *)loadGpxFile:(NSString *)file
{
    OASKFile *favoriteGPXFile = [[OASKFile alloc] initWithFilePath:file];
    return [OASGpxUtilities.shared loadGpxFileFile:favoriteGPXFile];
}

+ (void)importFavoritesFromGpx:(OASGpxFile *)gpxFile
{
    NSString *defCategory = @"";
    OAParkingPositionPlugin *plugin = (OAParkingPositionPlugin *)[OAPluginsHelper getPlugin:OAParkingPositionPlugin.class];
    NSArray<OASGpxUtilitiesPointsGroup *> *pointsGroups = gpxFile.pointsGroups.allValues;
    for (OASGpxUtilitiesPointsGroup *pointsGroup in pointsGroups)
    {
        NSArray<OAFavoriteItem *> *favorites = [self wptAsFavorites:pointsGroup.points defaultCategory:defCategory];
        [self checkDuplicateNames:favorites];
        [self deleteFavorites:favorites.copy saveImmediately:NO];
        [self addFavorites:favorites lookupAddress:YES sortAndSave:pointsGroup == pointsGroups.lastObject pointsGroup:pointsGroup];
        for (OAFavoriteItem *favorite in favorites)
        {
            if (plugin && favorite.specialPointType == OASpecialPointType.PARKING)
                [plugin updateParkingPoint:favorite];
        }
    }
}

+ (void)checkDuplicateNames:(NSArray<OAFavoriteItem *> *)favorites
{
    for (OAFavoriteItem *item in favorites)
    {
        NSInteger number = 1;
        NSString *index;
        NSString *name = [item getName];
        NSString *category = [item getCategory];
        BOOL duplicatesFound = NO;
        for (OAFavoriteItem *favoriteItem in favorites)
        {
            NSString *favoriteItemName = [favoriteItem getName];
            if ([name isEqualToString:favoriteItemName]
                && [category isEqualToString:[favoriteItem getCategory]]
                && ![item isEqual:favoriteItem])
            {
                if (!duplicatesFound)
                {
                    index = [NSString stringWithFormat:@" (%li)", number];
                    [item setName:[name stringByAppendingString:index]];
                }
                duplicatesFound = YES;
                number++;
                index = [NSString stringWithFormat:@" (%li)", number];
                [favoriteItem setName:[favoriteItemName stringByAppendingString:index]];
            }
        }
    }
}

+ (void) recalculateCachedFavPoints
{
    NSMutableArray *allPoints = [NSMutableArray array];
    for (OAFavoriteGroup *group in _favoriteGroups)
    {
        [allPoints addObjectsFromArray:group.points];
    }
    
    _cachedFavoritePoints = [allPoints copy];
    [self getFavoritesCollection];
    NSArray<OAFavoriteGroup *> *groupsSnapshot = _favoriteGroups ?: @[];
    [_favCollectionQueue addOperationWithBlock:^{
        if (_favoritesCollection == nullptr)
            return;
        
        _favoritesCollection->clearFavoriteLocations();
        for (NSUInteger i = 0; i < groupsSnapshot.count; i++)
        {
            OAFavoriteGroup *group = groupsSnapshot[i];
            QList<std::shared_ptr<OsmAnd::IFavoriteLocation>> favoriteLocations;
            for (OAFavoriteItem *point in group.points)
            {
                favoriteLocations.append(point.favorite);
            }
            
            const BOOL notify = (i == groupsSnapshot.count - 1);
            _favoritesCollection->addFavoriteLocations(favoriteLocations, notify);
        }
    }];
}

+ (OAFavoriteItem *) getSpecialPoint:(OASpecialPointType *)specialType
{
    for (OAFavoriteItem *item in _cachedFavoritePoints)
    {
        [item initPersonalType];
        if (item.specialPointType == specialType)
            return item;
    }
    return nil;
}

+ (void) setParkingPoint:(double)lat lon:(double)lon address:(NSString *)address pickupDate:(NSDate *)pickupDate addToCalendar:(BOOL)addToCalendar
{
    OASpecialPointType *specialType = OASpecialPointType.PARKING;
    OAFavoriteItem *point = [self getSpecialPoint:specialType];
    if (point)
    {
        [point setIcon:[specialType getIconName]];
        [point setAddress:address];
        [point setPickupTime:pickupDate];
        [point setCalendarEvent:addToCalendar];
        [self editFavorite:point lat:lat lon:lon description:[point getDescription]];
    }
    else
    {
        OAFavoriteItem *point = [[OAFavoriteItem alloc] initWithLat:lat lon:lon name:[specialType getName] category:[specialType getCategory]];
        [point setAddress:address];
        [point setIcon:[specialType getIconName]];
        [point setColor:[specialType getIconColor]];
        [point setTimestamp:[NSDate date]];
        [point setPickupTime:pickupDate];
        [point setCalendarEvent:addToCalendar];
        [self addFavorite:point];
    }
}

+ (void) setSpecialPoint:(OASpecialPointType *)specialType lat:(double)lat lon:(double)lon address:(NSString *)address
{
    OAFavoriteItem *point = [self getSpecialPoint:specialType];
    if (point)
    {
        [point setIcon:[specialType getIconName]];
        [point setAddress:address];
        [self editFavorite:point lat:lat lon:lon description:[point getDescription]];
    }
    else
    {
        OAFavoriteItem *point = [[OAFavoriteItem alloc] initWithLat:lat lon:lon name:[specialType getName] category:[specialType getCategory]];
        [point setAddress:address];
        [point setIcon:[specialType getIconName]];
        [point setColor:[specialType getIconColor]];
        [self addFavorite:point];
    }
}

+ (BOOL) addFavorite:(OAFavoriteItem *)point
{
    return [self addFavorites:@[point]];
}

+ (BOOL) addFavorites:(NSArray<OAFavoriteItem *> *)favorites
{
    return [self addFavorites:favorites
                lookupAddress:YES
                  sortAndSave:YES
                  pointsGroup:nil];
}

+ (BOOL)addFavorites:(NSArray<OAFavoriteItem *> *)favorites
       lookupAddress:(BOOL)lookupAddress
         sortAndSave:(BOOL)sortAndSave
         pointsGroup:(OASGpxUtilitiesPointsGroup *)pointsGroup
{
    BOOL res = NO;
    QList<std::shared_ptr<OsmAnd::IFavoriteLocation>> favoriteLocations;
    NSMutableArray *mutablePoints = [_cachedFavoritePoints mutableCopy];

    for (OAFavoriteItem *point in favorites)
    {
        if ([point getAltitude] == 0)
            [point initAltitude];

        if ([point getName].length == 0 && _flatGroups[[point getCategory]])
            continue;
        res = YES;

        if (lookupAddress && ![point isAddressSpecified])
            [self lookupAddress:point];

        OAFavoriteGroup *group = [self getOrCreateGroup:point pointsGroup:pointsGroup];
        if ([point getName].length > 0)
        {
            [point setVisible:group.isVisible];
            if (point.specialPointType == [OASpecialPointType PARKING])
                [point setColor:[point.specialPointType getIconColor]];
            else if (![point getColor])
                [point setColor:group.color];

            [group addPoint:point];
            [mutablePoints addObject:point];
            favoriteLocations.append(point.favorite);
        }

        OAGPXAppearanceCollection *appearanceCollection = [OAGPXAppearanceCollection sharedInstance];
        [appearanceCollection selectColor:[appearanceCollection getColorItemWithValue:[[point getColor] toARGBNumber]]];
    }

    if (res)
    {
        _cachedFavoritePoints = [mutablePoints copy];
        auto locsPtr = std::make_shared<QList<std::shared_ptr<OsmAnd::IFavoriteLocation>>>(favoriteLocations);
        [_favCollectionQueue addOperationWithBlock:^{
            _favoritesCollection->addFavoriteLocations(*locsPtr, true);
        }];
        [[OAAppSettings sharedManager] setShowFavorites:YES];
        if (sortAndSave)
        {
            [self sortAll];
            [self saveCurrentPointsIntoFile];
        }
    }
    return res;
}

+ (void) lookupAddress:(OAFavoriteItem *)point
{
    //TODO: implement
}

+ (NSArray<OAFavoriteItem *> *) getFavoriteItems
{
    return _cachedFavoritePoints;
}

+ (OAFavoriteItem *) getVisibleFavByLat:(double)lat lon:(double)lon
{
    for (OAFavoriteItem *item in _cachedFavoritePoints)
    {
        if ([item isVisible] && [OAUtilities isCoordEqual:[item getLatitude] srcLon:[item getLongitude] destLat:lat destLon:lon upToDigits:6])
            return item;
    }
    return nil;
}

+ (NSMutableDictionary<NSString *, OAFavoriteGroup *> *) getGroups
{
    return _flatGroups;
}

+ (OAFavoriteGroup *) getGroupByName:(NSString *)nameId
{
    return _flatGroups[nameId];
}

+ (OAFavoriteGroup *) getGroupByPoint:(OAFavoriteItem *)favoriteItem
{
    if (favoriteItem)
    {
        return _flatGroups[[favoriteItem getCategory]];
    }
    return nil;
}

+ (NSArray<OAFavoriteItem *> *) getVisibleFavoriteItems
{
    NSMutableArray<OAFavoriteItem *> *res = [NSMutableArray array];
    for (OAFavoriteItem *item in _cachedFavoritePoints)
    {
        if (item.isVisible)
            [res addObject:item];
    }
    return [res copy];
}

+ (BOOL) editFavoriteName:(OAFavoriteItem *)item newName:(NSString *)newName group:(NSString *)group descr:(NSString *)descr address:(NSString *)address
{
    NSString *oldGroup = [item getCategory];

    [item setName:newName];
    [item setCategory:group];
    [item setDescription:descr];
    [item setAddress:address];
    
    if (![oldGroup isEqualToString:group])
    {
        OAFavoriteGroup *old = _flatGroups[oldGroup];
        if (old)
            [old.points removeObject:item];
        
        OAFavoriteGroup *newGroup = [self getOrCreateGroup:item];
        [item setVisible:newGroup.isVisible];
        
        //TODO: change icon for parking points here

        UIColor *defaultColor = [OADefaultFavorite getDefaultColor];
        if (![item getColor] && [item getColor] == defaultColor)
            [item setColor:newGroup.color];

        [newGroup.points addObject:item];
    }

    OAGPXAppearanceCollection *appearanceCollection = [OAGPXAppearanceCollection sharedInstance];
    [appearanceCollection selectColor:[appearanceCollection getColorItemWithValue:[[item getColor] toARGBNumber]]];

    [self sortAll];
    [self saveCurrentPointsIntoFile];
    return YES;
}

+ (BOOL) editFavorite:(OAFavoriteItem *)item lat:(double)lat lon:(double)lon
{
    return [self editFavorite:item lat:lat lon:lon description:nil];
}

+ (BOOL) editFavorite:(OAFavoriteItem *)item lat:(double)lat lon:(double)lon description:(NSString *)description
{
    auto fav = item.favorite;
    [item setLat:lat lon:lon];
    auto fav2 = item.favorite;
    
    [_favCollectionQueue addOperationWithBlock:^{
        _favoritesCollection->removeFavoriteLocation(fav);
        _favoritesCollection->addFavoriteLocation(fav2);
    }];
    
    [item initAltitude];
    
    if (description)
        [item setDescription:description];
    
    [self saveCurrentPointsIntoFile];
    return YES;
}

+ (BOOL)isGroupNameValidWithText:(NSString *)text
{
    return text.length > 0
    && [text rangeOfCharacterFromSet:kIllegalFileNameCharacters].length == 0
    && ![text isEqualToString:OALocalizedString(@"favorites_item")]
    && ![text isEqualToString:OALocalizedString(@"personal_category_name")]
    && ![text isEqualToString:kPersonalCategory];
}

+ (void)updateGroup:(OAFavoriteGroup *)group
            newName:(NSString *)newName
    saveImmediately:(BOOL)saveImmediately
{
    if (![group.name isEqualToString:newName])
    {
        [_flatGroups removeObjectForKey:group.name];

        group.name = newName;
        OAFavoriteGroup *renamedGroup = _flatGroups[group.name];
        BOOL existing = renamedGroup != nil;
        if (!renamedGroup)
        {
            renamedGroup = group;
            _flatGroups[group.name] = group;
        }
        else
        {
            NSMutableArray *mutableGroups = [_favoriteGroups mutableCopy];
            [mutableGroups removeObject:group];
            _favoriteGroups = [mutableGroups copy];
        }

        for (OAFavoriteItem *point in group.points)
            [point setCategory:newName];

        if (existing)
            [renamedGroup.points addObjectsFromArray:group.points];
    }
    if (saveImmediately)
        [self saveCurrentPointsIntoFile];
}


+ (void)updateGroup:(OAFavoriteGroup *)group
           iconName:(NSString *)iconName
       updatePoints:(BOOL)updatePoints
    updateGroupIcon:(BOOL)updateGroupIcon
    saveImmediately:(BOOL)saveImmediately
{
    if (updatePoints)
        for (OAFavoriteItem *point in group.points)
            [point setIcon:iconName];

    if (updateGroupIcon)
        group.iconName = iconName;
    if (saveImmediately)
        [self saveCurrentPointsIntoFile];
}

+ (void)updateGroup:(OAFavoriteGroup *)group
              color:(UIColor *)color
       updatePoints:(BOOL)updatePoints
   updateGroupColor:(BOOL)updateGroupColor
    saveImmediately:(BOOL)saveImmediately
{
    if (updatePoints)
        for (OAFavoriteItem *point in group.points)
            [point setColor:color];

    if (updateGroupColor)
        group.color = color;
    if (saveImmediately)
        [self saveCurrentPointsIntoFile];
}

+ (void)updateGroup:(OAFavoriteGroup *)group
 backgroundIconName:(NSString *)backgroundIconName
       updatePoints:(BOOL)updatePoints
   updateGroupShape:(BOOL)updateGroupShape
    saveImmediately:(BOOL)saveImmediately
{
    if (updatePoints)
        for (OAFavoriteItem *point in group.points)
            [point setBackgroundIcon:backgroundIconName];

    if (updateGroupShape)
        group.backgroundType = backgroundIconName;
    if (saveImmediately)
        [self saveCurrentPointsIntoFile];
}

+ (void)updateGroup:(OAFavoriteGroup *)group
            visible:(BOOL)visible
    saveImmediately:(BOOL)saveImmediately
{
    for (OAFavoriteItem *point in group.points)
        [point setVisible:visible];

    group.isVisible = visible;
    if (saveImmediately)
        [self saveCurrentPointsIntoFile];
}

+ (void) saveCurrentPointsIntoFile
{
    [self saveCurrentPointsIntoFile:YES];
}

+ (void) saveCurrentPointsIntoFile:(BOOL)async
{
    [_favQueue cancelAllOperations];

    __block NSArray<OAFavoriteGroup *> *favoriteGroups = [[NSArray alloc] initWithArray:_favoriteGroups copyItems:YES];
    __block NSBlockOperation *operation;
    operation = [NSBlockOperation blockOperationWithBlock:^{

        if ([operation isCancelled])
            return;

        NSMutableDictionary<NSString *, OAFavoriteGroup *> *deletedGroups = [NSMutableDictionary dictionary];
        NSMutableDictionary<NSString *, OAFavoriteItem *> *deletedPoints = [NSMutableDictionary dictionary];

        NSArray<NSString *> *files = [self getGroupFiles];
        if (files.count > 0)
        {
            for (NSString *file in files)
            {
                [self loadFileGroups:file groups:deletedGroups];
                if ([operation isCancelled])
                    return;
            }
        }

        // Get all points from internal file to filter later
        for (OAFavoriteGroup *group in deletedGroups.allValues)
            for (OAFavoriteItem *point in group.points)
                deletedPoints[[point getKey]] = point;

        // Hold only deleted points in map
        for (OAFavoriteItem *point in [self getPointsFromGroups:favoriteGroups])
            [deletedPoints removeObjectForKey:[point getKey]];

        // Hold only deleted groups in map
        for (OAFavoriteGroup *group in favoriteGroups)
            [deletedGroups removeObjectForKey:group.name];

        // Save groups to internal file
        // [self saveFile:_favoriteGroups file:internalFile];
        // Save groups to external files

        if ([operation isCancelled])
            return;

        [self saveFiles:favoriteGroups deleted:deletedPoints.allKeys];

        // Save groups to backup file
        [self backup];
    }];

    [_favQueue addOperations:@[operation] waitUntilFinished:!async];
}

+ (NSArray<OAFavoriteItem *> *)getPointsFromGroups:(NSArray<OAFavoriteGroup *> *)groups
{
    NSMutableArray<OAFavoriteItem *> *favouritePoints = [NSMutableArray array];
    for (OAFavoriteGroup *group in groups)
        [favouritePoints addObjectsFromArray:group.points];

    return favouritePoints;
}

+ (void)saveFiles:(NSArray<OAFavoriteGroup *> *)localGroups
          deleted:(NSArray<NSString *> *)deleted
{
    NSDictionary<NSString *, OAFavoriteGroup *> *fileGroups = [self loadGroups];
    [self saveFileGroups:localGroups fileGroups:fileGroups];
    [self saveLocalGroups:localGroups fileGroups:fileGroups deleted:deleted];
}

+ (void)saveFileGroups:(NSArray<OAFavoriteGroup *> *)localGroups
            fileGroups:(NSDictionary<NSString *, OAFavoriteGroup *> *)fileGroups
{
    for (OAFavoriteGroup *fileGroup in fileGroups.allValues)
    {
        // Search corresponding group in memory
        BOOL hasLocalGroup = NO;
        for (OAFavoriteGroup *group in localGroups)
        {
            if ([group.name isEqualToString:fileGroup.name])
            {
                hasLocalGroup = YES;
                break;
            }
        }
        // Delete external group file if it does not exist in local groups
        if (!hasLocalGroup)
        {
            OsmAndAppInstance app = [OsmAndApp instance];
            NSString *fileGroupPath = [app.favoritesPath stringByAppendingPathComponent:
                                       [NSString stringWithFormat:@"%@%@%@%@",
                                        app.favoritesFilePrefix,
                                        fileGroup.name.length > 0 ? app.favoritesGroupNameSeparator : @"",
                                        [OsmAndApp.instance getGroupFileName:fileGroup.name],
                                        GPX_FILE_EXT]];
            [[NSFileManager defaultManager] removeItemAtPath:fileGroupPath error:nil];
        }
    }
}

+ (void)saveLocalGroups:(NSArray<OAFavoriteGroup *> *)localGroups
             fileGroups:(NSDictionary<NSString *, OAFavoriteGroup *> *)fileGroups
                deleted:(NSArray<NSString *> *)deleted
{
    for (OAFavoriteGroup *localGroup in localGroups)
    {
        OAFavoriteGroup *fileGroup = fileGroups[localGroup.name];
        // Collect non deleted points from external group
        NSMutableDictionary<NSString *, OAFavoriteItem *> *all = [NSMutableDictionary dictionary];
        if (fileGroup)
        {
            for (OAFavoriteItem *point in fileGroup.points)
            {
                NSString *key = [point getKey];
                if (![deleted containsObject:key])
                    all[key] = point;
            }
        }
        // Remove already existing in memory
        NSArray<OAFavoriteItem *> *localPoints = localGroup.points;
        for (OAFavoriteItem *point in localPoints)
            [all removeObjectForKey:[point getKey]];

        // save favoritePoints from memory in order to update existing
        [localGroup.points addObjectsFromArray:all.allValues];
        // Save file if group changed
        if (![localGroup isEqual:fileGroup])
        {
            OsmAndAppInstance app = [OsmAndApp instance];
            NSString *fileGroupPath = [app.favoritesPath stringByAppendingPathComponent:
                                       [NSString stringWithFormat:@"%@%@%@%@",
                                        app.favoritesFilePrefix,
                                        localGroup.name.length > 0 ? app.favoritesGroupNameSeparator : @"",
                                        [OsmAndApp.instance getGroupFileName:localGroup.name],
                                        GPX_FILE_EXT]];
           
            [self saveFile:@[localGroup] file:fileGroupPath];
        }
    }
}

+ (void)saveFile:(NSArray<OAFavoriteGroup *> *)favoriteGroups file:(NSString *)file
{
    OASGpxFile *gpx = [self asGpxFile:favoriteGroups];
    [OASGpxUtilities.shared writeGpxFileFile:[[OASKFile alloc] initWithFilePath:file] gpxFile:gpx];
}

+ (void) backup
{
    [self.class backup:[self.class getBackupFile]];
}

+ (void) backup:(NSString *)backupFileName
{
    NSFileManager *manager = [NSFileManager defaultManager];
    NSString *favoritesPath = OsmAndApp.instance.favoritesPath;
    QList<QString> filesList;
    NSArray<NSString *> *files = [manager contentsOfDirectoryAtPath:favoritesPath error:nil];
    for (NSString *file in files)
        filesList << QString::fromNSString([favoritesPath stringByAppendingPathComponent:file]);

    bool ok = !filesList.isEmpty();
    if (ok)
    {
        const auto backupFile = QString::fromNSString(backupFileName);
        const auto basePath = QString::fromNSString(favoritesPath);
        OsmAnd::ArchiveWriter archiveWriter;
        ok = false;
        archiveWriter.createArchive(&ok, backupFile, filesList, basePath);
    }
    if (!ok)
        NSLog(@"ERROR: Favorites backup failed");

    [self.class clearOldBackups:[self.class getBackupFiles] maxCount:BACKUP_MAX_COUNT];
}

+ (void) clearOldBackups:(NSArray *)files maxCount:(int)maxCount
{
    if (files.count < maxCount)
        return;

    // sort in order from oldest to newest
    NSArray* sortedFiles = [files sortedArrayUsingComparator:^(id file1, id file2) {
        return [[file2 objectForKey:@"lastDate"] compare:[file1 objectForKey:@"lastDate"]];
    }];

    NSFileManager *manager = [NSFileManager defaultManager];
    for (int i = (int) sortedFiles.count; i > maxCount; --i)
        [manager removeItemAtPath:sortedFiles[i - 1][@"path"] error:nil];
}

+ (NSString *) getBackupFile
{
    [self.class clearOldBackups:[self.class getBackupFilesForToday] maxCount:BACKUP_MAX_PER_DAY];

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy_MM_dd_HH_mm_ss"];
    NSString *fileName = [[dateFormatter stringFromDate:NSDate.date] stringByAppendingString:GPX_ZIP_FILE_EXT];
    return [OsmAndApp.instance.favoritesBackupPath stringByAppendingPathComponent:fileName];
}

+ (NSArray *) getBackupFilesForToday
{
    NSMutableArray *result = [NSMutableArray array];
    NSArray *files = [self.class getBackupFiles];

    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *dateComponents = [cal components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:NSDate.date];
    [dateComponents setHour:0];
    [dateComponents setMinute:0];
    [dateComponents setSecond:0];
    NSDate *startDayTime = [cal dateFromComponents:dateComponents];

    for (NSDictionary *file in files)
    {
        NSDate *lastModifiedDate = file[@"lastDate"];
        if ([lastModifiedDate compare:startDayTime] != NSOrderedAscending)
            [result addObject:file];
    }
    return [NSArray arrayWithArray:result];
}

+ (NSArray *) getBackupFiles
{
    NSString *backupPath = OsmAndApp.instance.favoritesBackupPath;
    NSFileManager *manager = [NSFileManager defaultManager];
    NSArray<NSString *> *files = [manager contentsOfDirectoryAtPath:backupPath error:nil];

    // acquire modification dates
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:files.count];
    for (NSString* file in files)
        if ([file hasSuffix:GPX_ZIP_FILE_EXT])
        {
            NSString* filePath = [backupPath stringByAppendingPathComponent:file];
            NSError *err = nil;
            NSDictionary<NSFileAttributeKey, id> *attrs = [manager attributesOfItemAtPath:filePath error:&err];
            [result addObject:@{ @"path": filePath, @"lastDate" : attrs.fileModificationDate}];
        }

    return [NSArray arrayWithArray:result];
}

+ (NSArray<NSString *> *) getGroupFiles
{
    NSString *favoritesPath = OsmAndApp.instance.favoritesPath;
    NSFileManager *manager = [NSFileManager defaultManager];
    NSArray<NSString *> *files = [manager contentsOfDirectoryAtPath:favoritesPath error:nil];

    NSMutableArray<NSString *> *result = [NSMutableArray arrayWithCapacity:files.count];
    for (NSString* file in files)
        if ([file hasSuffix:GPX_FILE_EXT])
        {
            NSString* filePath = [favoritesPath stringByAppendingPathComponent:file];
            [result addObject:filePath];
        }

    return [NSArray arrayWithArray:result];
}

+ (void) sortAll
{
    NSArray *sortedGroups = [_favoriteGroups sortedArrayUsingComparator:^NSComparisonResult(OAFavoriteGroup *obj1, OAFavoriteGroup *obj2) {
        if ([obj1 isPersonal])
            return NSOrderedAscending;
        else if ([obj2 isPersonal])
            return NSOrderedDescending;
        else
            return [obj1.name compare:obj2.name options:NSCaseInsensitiveSearch];
    }];
    _favoriteGroups = [NSMutableArray arrayWithArray:sortedGroups];
    
    for (OAFavoriteGroup *group in _favoriteGroups)
    {
        NSArray *sortedPoints = [group.points sortedArrayUsingComparator:^NSComparisonResult(OAFavoriteItem *obj1, OAFavoriteItem *obj2) {
            NSString *title1 = [obj1 getDisplayName];
            NSString *title2 = [obj2 getDisplayName];
            return [title1 compare:title2 options:NSCaseInsensitiveSearch];
        }];
        group.points = [NSMutableArray arrayWithArray:sortedPoints];
        
    }
    
    if (_cachedFavoritePoints)
    {
        NSArray *sortedCachedPoints = [_cachedFavoritePoints sortedArrayUsingComparator:^NSComparisonResult(OAFavoriteItem *obj1, OAFavoriteItem *obj2) {
            NSString *title1 = [obj1 getDisplayName];
            NSString *title2 = [obj2 getDisplayName];
            return [title1 compare:title2 options:NSCaseInsensitiveSearch];
        }];
        _cachedFavoritePoints = sortedCachedPoints;
    }
}

+ (OAFavoriteGroup *)getOrCreateGroup:(OAFavoriteItem *)item
{
    return [self getOrCreateGroup:item pointsGroup:nil];
}

+ (OAFavoriteGroup *)getOrCreateGroup:(OAFavoriteItem *)item
                          pointsGroup:(OASGpxUtilitiesPointsGroup *)pointsGroup
{
    OAFavoriteGroup *favoriteGroup = _flatGroups[[item getCategory]];
    
    if (!favoriteGroup)
    {
        favoriteGroup = [[OAFavoriteGroup alloc] initWithPoint:item];
        _flatGroups[favoriteGroup.name] = favoriteGroup;
        _favoriteGroups = [_favoriteGroups arrayByAddingObject:favoriteGroup];
    }
    [self updateGroupAppearance:favoriteGroup pointsGroup:pointsGroup];
    
    return favoriteGroup;
}

+ (void)updateGroupAppearance:(OAFavoriteGroup *)favoriteGroup
                  pointsGroup:(OASGpxUtilitiesPointsGroup *)pointsGroup
{
    if (favoriteGroup && pointsGroup)
    {
        favoriteGroup.color = UIColorFromRGB(pointsGroup.color) ;
        favoriteGroup.iconName = pointsGroup.iconName;
        favoriteGroup.backgroundType = pointsGroup.backgroundType;
        favoriteGroup.isVisible = ![pointsGroup isHidden];
    }
}

+ (NSArray<OAFavoriteGroup *> *)getFavoriteGroups
{
    return _favoriteGroups;
}

+ (void)addFavoriteGroup:(NSString *)name
                   color:(UIColor *)color
                iconName:(NSString *)iconName
      backgroundIconName:(NSString *)backgroundIconName
{
    OAFavoriteGroup *group = [[OAFavoriteGroup alloc] initWithName:name
                                                         isVisible:YES
                                                             color:color];
    group.iconName = iconName;
    group.backgroundType = backgroundIconName;
    _favoriteGroups = [_favoriteGroups arrayByAddingObject:group];
    _flatGroups[group.name] = group;
    
    [[OAGPXAppearanceCollection sharedInstance] saveFavoriteColorsIfNeeded:@[group]];
}


+ (void)deleteFavorites:(NSArray<OAFavoriteItem *> *)favorites saveImmediately:(BOOL)saveImmediately
{
    QList< std::shared_ptr<OsmAnd::IFavoriteLocation> > favoriteLocations;
    for (OAFavoriteItem *favorite in favorites)
    {
        favoriteLocations.append(favorite.favorite);
        OAFavoriteGroup *group = _flatGroups[[favorite getCategory]];
        if (group)
            [group.points removeObjectIdenticalTo:favorite];
    }
    [self removeFavoritePoints:favorites favoriteLocations:favoriteLocations];
    if (saveImmediately)
        [self saveCurrentPointsIntoFile];
}

+ (void)removeFavoritePoints:(NSArray<OAFavoriteItem *> *)favorites
           favoriteLocations:(const QList<std::shared_ptr<OsmAnd::IFavoriteLocation>> &)favoriteLocations
{
    // RemoveObjectIdenticalTo to remove only exact instances and prevent accidental removal of duplicates.
    NSMutableArray *mutablePoints = [_cachedFavoritePoints mutableCopy];
    for (OAFavoriteItem *favoriteToRemove in favorites)
        [mutablePoints removeObjectIdenticalTo:favoriteToRemove];
    
    _cachedFavoritePoints = [mutablePoints copy];
    auto locsPtr = std::make_shared<QList<std::shared_ptr<OsmAnd::IFavoriteLocation>>>(favoriteLocations);
    [_favCollectionQueue addOperationWithBlock:^{
        _favoritesCollection->removeFavoriteLocations(*locsPtr);
    }];
}

+ (BOOL) deleteNewFavoriteItem:(OAFavoriteItem *)favoritesItem
{
    return [self.class deleteFavoriteGroups:nil andFavoritesItems:@[favoritesItem] isNewFavorite:YES];
}

+ (BOOL) deleteFavoriteGroups:(NSArray<OAFavoriteGroup *> *)groupsToDelete andFavoritesItems:(NSArray<OAFavoriteItem *> *)favoritesItems
{
    return [self.class deleteFavoriteGroups:groupsToDelete andFavoritesItems:favoritesItems isNewFavorite:NO];
}

+ (BOOL)deleteFavoriteGroups:(NSArray<OAFavoriteGroup *> *)groupsToDelete
           andFavoritesItems:(NSArray<OAFavoriteItem *> *)favoritesItems
               isNewFavorite:(BOOL)isNewFavorite
{
    if (favoritesItems)
    {
        [self deleteFavorites:favoritesItems.copy saveImmediately:NO];
        
        for (OAFavoriteItem *item in favoritesItems)
        {
            OAFavoriteGroup *group = _flatGroups[[item getCategory]];
            
            if (group && group.points.count == 0 && (!isNewFavorite || (isNewFavorite && group.name.length > 0)))
            {
                [_flatGroups removeObjectForKey:group.name];
                _favoriteGroups = [_favoriteGroups filteredArrayUsingPredicate:
                                   [NSPredicate predicateWithFormat:@"SELF != %@", group]];
            }
        }
    }
    
    if (groupsToDelete)
    {
        for (OAFavoriteGroup *group in groupsToDelete)
        {
            [self deleteFavorites:group.points.copy saveImmediately:NO];
            [_flatGroups removeObjectForKey:group.name];
            _favoriteGroups = [_favoriteGroups filteredArrayUsingPredicate:
                               [NSPredicate predicateWithFormat:@"SELF != %@", group]];
        }
    }
    
    if (!isNewFavorite)
        [self saveCurrentPointsIntoFile];
    
    return YES;
}


+ (NSDictionary<NSString *, NSString *> *) checkDuplicates:(OAFavoriteItem *)point
{
    NSString *name = [point getName];
    NSString *index = @"";
    int number = 0;
    BOOL fl = YES;
    while (fl)
    {
        fl = NO;
        for (OAFavoriteItem *fp in _cachedFavoritePoints)
        {
            if ([[fp getName] isEqualToString:name]
                    && [[fp getCategory] isEqualToString:[point getCategory]])
            {
                number++;
                index = [NSString stringWithFormat:@" (%i)", number];
                name = [[point getName] stringByAppendingString:index];
                fl = YES;
                break;
            }
        }
    }
    if (index.length > 0)
    {
        [point setName:name];
        return @{ @"name": name, @"status": @"duplicate" };
    }
    return nil;
}

+ (NSArray<NSString *> *) getFlatBackgroundIconNamesList
{
    if (!_flatBackgroundIcons)
        _flatBackgroundIcons = @[@"circle", @"octagon", @"square"];
    return _flatBackgroundIcons;
}

+ (NSArray<NSString *> *) getFlatBackgroundContourIconNamesList
{
    if (!_flatBackgroundContourIcons)
        _flatBackgroundContourIcons = @[@"bg_point_circle_contour", @"bg_point_octagon_contour", @"bg_point_square_contour"];
    return _flatBackgroundContourIcons;
}

+ (OASGpxFile *)asGpxFile:(NSArray<OAFavoriteGroup *> *)favoriteGroups
{
    OASGpxFile *gpx = [[OASGpxFile alloc] initWithAuthor:[OAAppVersion getFullVersionWithAppName]];
    for (OAFavoriteGroup *group in favoriteGroups)
        [gpx addPointsGroupGroup:[group toPointsGroup]];

    return gpx;
}

+ (void) addParkingReminderToCalendar
{
    EKEventStore *eventStore = [[EKEventStore alloc] init];
    
    void (^createEvent)(void) = ^{
        EKEvent *event = [EKEvent eventWithEventStore:eventStore];
        event.title = OALocalizedString(@"pickup_car");
        
        OAParkingPositionPlugin *plugin = (OAParkingPositionPlugin *)[OAPluginsHelper getPlugin:OAParkingPositionPlugin.class];
        if (plugin)
        {
            if (plugin.getEventIdentifier)
                [self.class removeParkingReminderFromCalendar];
            
            NSDate *pickupDate = [NSDate dateWithTimeIntervalSince1970:plugin.getParkingTime / 1000];
            event.startDate = pickupDate;
            event.endDate = pickupDate;
            
            [event addAlarm:[EKAlarm alarmWithRelativeOffset:-60.0 * 5.0]];
            [event setCalendar:[eventStore defaultCalendarForNewEvents]];
            NSError *err;
            [eventStore saveEvent:event span:EKSpanThisEvent error:&err];
            if (err)
            {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:err.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok") style:UIAlertActionStyleCancel handler:nil]];
                [UIApplication.sharedApplication.mainWindow.rootViewController presentViewController:alert animated:YES completion:nil];
            }
            else
            {
                [plugin setEventIdentifier:[event.eventIdentifier copy]];

                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                [dateFormatter setDateStyle:NSDateFormatterNoStyle];
                [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:OALocalizedString(@"calendar_new_event_title")
                                                                               message:[NSString stringWithFormat:OALocalizedString(@"calendar_new_event_message"),
                                                                                        [dateFormatter stringFromDate:pickupDate]]
                                                                        preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok") style:UIAlertActionStyleCancel handler:nil]];
                [UIApplication.sharedApplication.mainWindow.rootViewController presentViewController:alert animated:YES completion:nil];
            }
        }
    };
    
    void (^requestAccessCompletionHandler)(BOOL, NSError *) = ^(BOOL granted, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error)
            {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:OALocalizedString(@"cannot_access_calendar") message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok") style:UIAlertActionStyleCancel handler:nil]];
                [UIApplication.sharedApplication.mainWindow.rootViewController presentViewController:alert animated:YES completion:nil];
            }
            else if (!granted)
            {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:OALocalizedString(@"cannot_access_calendar") message:OALocalizedString(@"reminder_not_set_text") preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok") style:UIAlertActionStyleCancel handler:nil]];
                [UIApplication.sharedApplication.mainWindow.rootViewController presentViewController:alert animated:YES completion:nil];
            }
            else
            {
                createEvent();
            }
        });
    };
    
    if (@available(iOS 17.0, *))
        [eventStore requestWriteOnlyAccessToEventsWithCompletion:requestAccessCompletionHandler];
    else
        [eventStore requestAccessToEntityType:EKEntityTypeEvent completion:requestAccessCompletionHandler];
}

+ (void) removeParkingReminderFromCalendar
{
    OAParkingPositionPlugin *plugin = (OAParkingPositionPlugin *) [OAPluginsHelper getPlugin:OAParkingPositionPlugin.class];
    if (plugin)
    {
        if (plugin.getEventIdentifier)
        {
            EKEventStore *eventStore = [[EKEventStore alloc] init];
            EKEvent *event = [eventStore eventWithIdentifier:plugin.getEventIdentifier];
            NSError *error;
            if (![eventStore removeEvent:event span:EKSpanFutureEvents error:&error])
                NSLog(@"%@", [error localizedDescription]);
            else
                [plugin setEventIdentifier:nil];
        }
    }
}

+ (UIImage *) getCompositeIcon:(NSString *)icon backgroundIcon:(NSString *)backgroundIcon color:(UIColor *)color
{
    if (!icon)
        icon = DEFAULT_ICON_NAME_KEY;
    if (!backgroundIcon)
        backgroundIcon = DEFAULT_ICON_SHAPE_KEY;
    if (!color)
        color = [OADefaultFavorite getDefaultColor];
    
    UIImage *resultImg;
    NSString *backgrounfIconName = [@"bg_point_" stringByAppendingString:backgroundIcon];
    UIImage *backgroundImg = [UIImage imageNamed:backgrounfIconName];
    backgroundImg = [OAUtilities tintImageWithColor:backgroundImg color:color];

    NSString *iconName = icon;
    if (![iconName hasPrefix:@"mx_"])
        iconName = [@"mx_" stringByAppendingString:iconName];
    UIImage *iconImg = [OAUtilities getMxIcon:iconName];
    iconImg = [OAUtilities tintImageWithColor:iconImg color:UIColor.whiteColor];

    CGFloat centredIconOffset = (backgroundImg.size.width - iconImg.size.width) / 2.0;
    UIGraphicsBeginImageContextWithOptions(backgroundImg.size, NO, [UIScreen mainScreen].scale);
    [backgroundImg drawInRect:CGRectMake(0.0, 0.0, backgroundImg.size.width, backgroundImg.size.height)];
    [iconImg drawInRect:CGRectMake(centredIconOffset, centredIconOffset, iconImg.size.width, iconImg.size.height)];
    resultImg = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return resultImg;
}

+ (BOOL) hasFavoriteAt:(CLLocationCoordinate2D)location
{
    for (OAFavoriteItem *item in _cachedFavoritePoints)
    {
        double lon = OsmAnd::Utilities::get31LongitudeX(item.favorite->getPosition31().x);
        double lat = OsmAnd::Utilities::get31LatitudeY(item.favorite->getPosition31().y);
        if ([OAUtilities isCoordEqual:lat srcLon:lon destLat:location.latitude destLon:location.longitude])
        {
            return YES;
        }
    }

    return NO;
}

+ (NSArray<OAFavoriteItem *> *)wptAsFavorites:(NSArray<OASWptPt *> *)points
                              defaultCategory:(NSString *)defaultCategory
{
    NSMutableArray<OAFavoriteItem *> *favorites = [NSMutableArray array];
    for (OASWptPt *point in points)
    {
        if (!point.name || point.name.length == 0)
            point.name = OALocalizedString(@"shared_string_waypoint");
        NSString *category = point.category ? point.category : defaultCategory;
        [favorites addObject:[OAFavoriteItem fromWpt:point category:category]];
    }
    return favorites;
}

@end

@implementation OAFavoriteGroup

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _points = [NSMutableArray array];
        _isVisible = YES;
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }

    if (![object isKindOfClass:[OAFavoriteGroup class]]) {
        return NO;
    }

    OAFavoriteGroup *otherGroup = (OAFavoriteGroup *)object;
    return ([self.name isEqualToString:otherGroup.name] &&
            [self.color isEqual:otherGroup.color] &&
            self.isVisible == otherGroup.isVisible &&
            [self.iconName isEqualToString:otherGroup.iconName] &&
            [self.backgroundType isEqualToString:otherGroup.backgroundType] &&
            [self.points isEqualToArray:otherGroup.points]);
}


- (instancetype)initWithPoint:(OAFavoriteItem *)point
{
    self = [self init];
    if (self)
    {
        _name = [point getCategory];
        _color = [point getInternalColor];
        _isVisible = [point isVisible];
        _iconName = [point getInternalIcon];
        _backgroundType = [point getInternalBackgroundIcon];
    }
    return self;
}

- (instancetype) initWithName:(NSString *)name isVisible:(BOOL)isVisible color:(UIColor *)color
{
    self = [self init];
    if (self)
    {
        _name = name;
        _isVisible = isVisible;
        _color = color;
    }
    return self;
}

- (instancetype) initWithPoints:(NSArray<OAFavoriteItem *> *)points name:(NSString *)name isVisible:(BOOL)isVisible color:(UIColor *)color
{
    self = [self init];
    if (self)
    {
        [_points addObjectsFromArray:points];
        _name = name;
        _isVisible = isVisible;
        _color = color;
    }
    return self;
}

- (void) addPoint:(OAFavoriteItem *)point
{
    [_points addObject:point];
}

- (UIColor *) color
{
    if (_color != nil && [_color toRGBNumber] != 0)
        return [UIColor colorRGB:_color equalToColorRGB:UIColor.whiteColor] ? [OADefaultFavorite getDefaultColor] : _color;
    else
        return [OADefaultFavorite getDefaultColor];
}

- (BOOL) isPersonal
{
    return [OAFavoriteGroup isPersonal:self.name];
}

+ (BOOL) isPersonal:(NSString *)name
{
    return [name isEqualToString:kPersonalCategory];
}

+ (BOOL) isPersonalCategoryDisplayName:(NSString *)name
{
    return [name isEqualToString:OALocalizedString(@"personal_category_name")];
}

+ (NSString *) getDisplayName:(NSString *)name
{
    if ([OAFavoriteGroup isPersonal:name])
        return OALocalizedString(@"personal_category_name");
    else if (name.length == 0)
        return OALocalizedString(kDefaultCategoryKey);
    else
        return name;
}

+ (NSString *) convertDisplayNameToGroupIdName:(NSString *)name
{
    if ([self isPersonalCategoryDisplayName:name])
        return kPersonalCategory;
    else if ([name isEqualToString:OALocalizedString(kDefaultCategoryKey)])
        return @"";
    return name;
}

- (OASGpxUtilitiesPointsGroup *)toPointsGroup
{
    NSString *mxPrefix = @"mx_";
    _iconName = [self removePrefix:mxPrefix fromValue:_iconName];
    OASGpxUtilitiesPointsGroup *pointsGroup = [[OASGpxUtilitiesPointsGroup alloc] initWithName:_name iconName:_iconName backgroundType:_backgroundType color:[self color].toARGBNumber hidden:!_isVisible];
    NSMutableArray<OASWptPt *> *points = [NSMutableArray array];
    
    for (OAFavoriteItem *point in _points)
    {
        [point setIcon:[self removePrefix:mxPrefix fromValue:[point getIcon]]];
        [points addObject:[point toWpt]];
    }
    
    pointsGroup.points = points;
    return pointsGroup;
}

- (NSString *)removePrefix:(NSString *)prefix fromValue:(NSString *)value
{
    return value && [value hasPrefix:prefix] ? [value substringFromIndex:prefix.length] : value;
}

+ (OAFavoriteGroup *)fromPointsGroup:(OASGpxUtilitiesPointsGroup *)pointsGroup
{
    OAFavoriteGroup *favoriteGroup = [[OAFavoriteGroup alloc] init];
    favoriteGroup.name = pointsGroup.name;
    favoriteGroup.color = UIColorFromRGB(pointsGroup.color);
    favoriteGroup.iconName = pointsGroup.iconName;
    favoriteGroup.backgroundType = pointsGroup.backgroundType;
    for (OASWptPt *point in pointsGroup.points)
    {
        [favoriteGroup.points addObject:[OAFavoriteItem fromWpt:point
                                                       category:nil]];
    }
    if (favoriteGroup.points && favoriteGroup.points.count > 0)
        favoriteGroup.isVisible = favoriteGroup.points[0].isVisible;
    return favoriteGroup;
}

#pragma mark NSCopying

- (id) copyWithZone:(NSZone *)zone
{
    OAFavoriteGroup *clone = [[OAFavoriteGroup alloc] initWithPoints:_points name:_name isVisible:_isVisible color:_color];
    clone.iconName = _iconName;
    clone.backgroundType = _backgroundType;
    return clone;
}

@end
