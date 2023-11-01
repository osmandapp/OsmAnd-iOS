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
#import "OAGPXMutableDocument.h"
#import "OAGPXDocumentPrimitives.h"
#import "OAParkingPositionPlugin.h"
#import "OAPlugin.h"
#import "OAIndexConstants.h"
#import "OAAppVersionDependentConstants.h"
#import "OAGPXAppearanceCollection.h"
#import "OANativeUtilities.h"
#import "OAFavoritesSettingsItem.h"

#import <EventKit/EventKit.h>
#import "OsmAnd_Maps-Swift.h"

#include <OsmAndCore.h>
#include <OsmAndCore/ArchiveWriter.h>

#define BACKUP_MAX_COUNT 10
#define BACKUP_MAX_PER_DAY 3

@implementation OAFavoritesHelper

static NSMutableArray<OAFavoriteItem *> *_cachedFavoritePoints;
static NSMutableArray<OAFavoriteGroup *> *_favoriteGroups;
static NSMutableDictionary<NSString *, OAFavoriteGroup *> *_flatGroups;
static NSArray<NSString *> *_flatBackgroundIcons;
static NSArray<NSString *> *_flatBackgroundContourIcons;
static BOOL _favoritesLoaded = NO;

+ (BOOL) isFavoritesLoaded
{
    return _favoritesLoaded;
}

+ (void) loadFavorites
{
    _cachedFavoritePoints = [NSMutableArray array];
    _favoriteGroups = [NSMutableArray array];
    _flatGroups = [NSMutableDictionary dictionary];

    NSMutableDictionary<NSString *, OAFavoriteGroup *> *groups = [self loadGroups];
    _flatGroups = groups;
    _favoriteGroups = [NSMutableArray arrayWithArray:groups.allValues];

    [OAFavoritesHelper sortAll];
    [OAFavoritesHelper recalculateCachedFavPoints];
    [[OAGPXAppearanceCollection sharedInstance] saveFavoriteColorsIfNeeded:_favoriteGroups];

    _favoritesLoaded = YES;
}

+ (NSMutableDictionary<NSString *, OAFavoriteGroup *> *)loadGroups
{
    NSMutableDictionary<NSString *, OAFavoriteGroup *> *groups = [NSMutableDictionary dictionary];
    NSArray<NSString *> *files = [self getGroupFiles];
    if (files.count > 0)
    {
        for (NSString *file in files)
        {
            [self loadFileGroups:file groups:groups];
        }
    }
    return groups;
}

+ (void)loadFileGroups:(NSString *)file groups:(NSMutableDictionary<NSString *, OAFavoriteGroup *> *)groups
{
    OAGPXDocument *gpx = [self loadGpxFile:file];
    [self collectFavoriteGroups:gpx favoriteGroups:groups legacy:NO];
}

+ (void)collectFavoriteGroups:(OAGPXDocument *)gpxFile
               favoriteGroups:(NSMutableDictionary<NSString *, OAFavoriteGroup *> *)favoriteGroups
                       legacy:(BOOL)legacy
{
    [gpxFile.pointsGroups enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, OAPointsGroup * _Nonnull pointsGroup, BOOL * _Nonnull stop) {
        OAFavoriteGroup *favoriteGroup = [OAFavoriteGroup fromPointsGroup:pointsGroup];
        NSString *groupKey = !legacy ? key : [key stringByAppendingString:@"-old"];
        favoriteGroups[groupKey] = favoriteGroup;
    }];
}

+ (void) initialLoadFavorites
{
    OsmAndAppInstance app = [OsmAndApp instance];
    // Sync favorites filename with android version
    NSString *oldfFavoritesFilename = app.documentsDir.filePath(QLatin1String("Favorites.gpx")).toNSString();
    NSString *favoritesLegacyFilename = app.documentsDir.filePath(QLatin1String("favourites.gpx")).toNSString();
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
        OAGPXDocument *gpx = [self loadGpxFile:favoritesLegacyFilename];
        [self collectFavoriteGroups:gpx favoriteGroups:groups legacy:YES];
        [self saveFile:groups.allValues file:[app favoritesStorageFilename:@"old"]];
        [[NSFileManager defaultManager] removeItemAtPath:favoritesLegacyFilename error:nil];
    }
}

+ (OAGPXDocument *)loadGpxFile:(NSString *)file
{
    return [[OAGPXDocument alloc] initWithGpxFile:file];
}

+ (void)importFavoritesFromGpx:(OAGPXDocument *)gpxFile
{
    NSString *defCategory = @"";
    NSArray<OAFavoriteItem *> *favorites = [OAFavoritesSettingsItem wptAsFavourites:gpxFile.points
                                                                    defaultCategory:defCategory];
    [self checkDuplicateNames:favorites];

    OAParkingPositionPlugin *plugin = (OAParkingPositionPlugin *)[OAPlugin getPlugin:OAParkingPositionPlugin.class];
    NSDictionary<NSString *, OAPointsGroup *> *pointsGroups = gpxFile.pointsGroups;

    for (OAFavoriteItem *favorite in favorites)
    {
        [self deleteFavorite:favorite saveImmediately:NO];

        OAPointsGroup *pointsGroup = pointsGroups[[favorite getCategory]];
        [self addFavorite:favorite lookupAddress:NO sortAndSave:NO pointsGroup:pointsGroup];
        
        if (plugin && favorite.specialPointType == OASpecialPointType.PARKING)
            [plugin updateParkingPoint:favorite];
    }
    [self sortAll];
    [self saveCurrentPointsIntoFile];
}

+ (void)checkDuplicateNames:(NSArray<OAFavoriteItem *> *)favorites
{
    for (OAFavoriteItem *item in favorites)
    {
        NSInteger number = 1;
        NSString *index;
        NSString *name = [item getName];
        BOOL duplicatesFound = NO;
        for (OAFavoriteItem *favoriteItem in favorites)
        {
            if ([name isEqualToString:[favoriteItem getName]]
                && [[item getCategory] isEqualToString:[favoriteItem getCategory]]
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
                [favoriteItem setName:[[favoriteItem getName] stringByAppendingString:index]];
            }
        }
    }
}

+ (void) recalculateCachedFavPoints
{
    NSMutableArray *allPoints = [NSMutableArray new];
    for (OAFavoriteGroup *group in _favoriteGroups)
        [allPoints addObjectsFromArray:group.points];
    
    _cachedFavoritePoints = allPoints;
}

+ (void) import:(QList< std::shared_ptr<OsmAnd::IFavoriteLocation> >)favorites
{
    for (auto it = favorites.begin(); it != favorites.end(); ++it)
    {
        OAFavoriteItem* favData = [[OAFavoriteItem alloc] initWithFavorite:*it];
        [_cachedFavoritePoints addObject:favData];
        
        NSString *groupName = [favData getCategory];
        UIColor *color = [OADefaultFavorite nearestFavColor:[favData getColor]].color;
        OAFavoriteGroup *group = [_flatGroups objectForKey:groupName];
        if (!group)
        {
            group = [[OAFavoriteGroup alloc] initWithName:groupName isVisible:[favData isVisible] color:color];
            [_flatGroups setObject:group forKey:groupName];
            [_favoriteGroups addObject:group];
        }
        [group addPoint:favData];
    }
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
    OAFavoriteItem *point = [OAFavoritesHelper getSpecialPoint:specialType];
    if (point)
    {
        [point setIcon:[specialType getIconName]];
        [point setAddress:address];
        [point setPickupTime:pickupDate];
        [point setCalendarEvent:addToCalendar];
        [OAFavoritesHelper editFavorite:point lat:lat lon:lon description:[point getDescription]];
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
    OAFavoriteItem *point = [OAFavoritesHelper getSpecialPoint:specialType];
    if (point)
    {
        [point setIcon:[specialType getIconName]];
        [point setAddress:address];
        [OAFavoritesHelper editFavorite:point lat:lat lon:lon description:[point getDescription]];
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
    return [self addFavorite:point
               lookupAddress:YES
                 sortAndSave:YES
                 pointsGroup:nil];
}

+ (BOOL)addFavorite:(OAFavoriteItem *)point
      lookupAddress:(BOOL)lookupAddress
        sortAndSave:(BOOL)sortAndSave
        pointsGroup:(OAPointsGroup *)pointsGroup;
{
    if ([point getAltitude] == 0)
        [point initAltitude];
    
    if ([point getName].length == 0 && _flatGroups[[point getCategory]])
        return YES;
    
    if (lookupAddress && ![point isAddressSpecified])
        [self lookupAddress:point];
    
    [[OAAppSettings sharedManager] setShowFavorites:YES];
    
    OAFavoriteGroup *group = [self getOrCreateGroup:point pointsGroup:pointsGroup];
    
    if ([point getName].length > 0)
    {
        [point setVisible:group.isVisible];
        if (point.specialPointType == [OASpecialPointType PARKING])
            [point setColor:[point.specialPointType getIconColor]];
        else if (![point getColor])
            [point setColor:group.color];
        
        [group addPoint:point];
        [_cachedFavoritePoints addObject:point];
    }

    OAGPXAppearanceCollection *appearanceCollection = [OAGPXAppearanceCollection sharedInstance];
    [appearanceCollection selectColor:[appearanceCollection getColorItemWithValue:[[point getColor] toARGBNumber]]];
    if (sortAndSave)
    {
        [self sortAll];
        [self saveCurrentPointsIntoFile];
    }
    
    return YES;
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
    return res;
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
        
        OAFavoriteGroup *newGroup = [OAFavoritesHelper getOrCreateGroup:item];
        [item setVisible:newGroup.isVisible];
        
        //TODO: change icon for parking points here

        UIColor *defaultColor = [OADefaultFavorite getDefaultColor];
        if (![item getColor] && [item getColor] == defaultColor)
            [item setColor:newGroup.color];

        [newGroup.points addObject:item];
    }

    OAGPXAppearanceCollection *appearanceCollection = [OAGPXAppearanceCollection sharedInstance];
    [appearanceCollection selectColor:[appearanceCollection getColorItemWithValue:[[item getColor] toARGBNumber]]];

    [OAFavoritesHelper sortAll];
    [OAFavoritesHelper saveCurrentPointsIntoFile];
    return YES;
}

+ (BOOL) editFavorite:(OAFavoriteItem *)item lat:(double)lat lon:(double)lon
{
    return [OAFavoritesHelper editFavorite:item lat:lat lon:lon description:nil];
}

+ (BOOL) editFavorite:(OAFavoriteItem *)item lat:(double)lat lon:(double)lon description:(NSString *)description
{
    [item setLat:lat lon:lon];
    [item initAltitude];
    
    if (description)
        [item setDescription:description];
    
    [OAFavoritesHelper saveCurrentPointsIntoFile];
    return YES;
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
            [_favoriteGroups removeObject:group];
        }
        for (OAFavoriteItem *point in group.points)
        {
            [point setCategory:newName];
        }
        if (existing)
            [renamedGroup.points addObjectsFromArray:group.points];
    }
    if (saveImmediately)
        [self saveCurrentPointsIntoFile];
}

+ (void)updateGroup:(OAFavoriteGroup *)group
           iconName:(NSString *)iconName
       updatePoints:(BOOL)updatePoints
    saveImmediately:(BOOL)saveImmediately
{
    if (updatePoints)
    {
        for (OAFavoriteItem *point in group.points)
        {
            [point setIcon:iconName];
        }
    }
    group.iconName = iconName;
    if (saveImmediately)
        [self saveCurrentPointsIntoFile];
}

+ (void)updateGroup:(OAFavoriteGroup *)group
              color:(UIColor *)color
       updatePoints:(BOOL)updatePoints
    saveImmediately:(BOOL)saveImmediately
{
    if (updatePoints)
    {
        for (OAFavoriteItem *point in group.points)
        {
            [point setColor:color];
        }
    }
    group.color = color;
    if (saveImmediately)
        [self saveCurrentPointsIntoFile];
}

+ (void)updateGroup:(OAFavoriteGroup *)group
 backgroundIconName:(NSString *)backgroundIconName
       updatePoints:(BOOL)updatePoints
    saveImmediately:(BOOL)saveImmediately
{
    if (updatePoints)
    {
        for (OAFavoriteItem *point in group.points)
        {
            [point setBackgroundIcon:backgroundIconName];
        }
    }
    group.backgroundType = backgroundIconName;
    if (saveImmediately)
        [self saveCurrentPointsIntoFile];
}

+ (void) saveCurrentPointsIntoFile
{
    NSMutableDictionary<NSString *, OAFavoriteGroup *> *deletedGroups = [NSMutableDictionary dictionary];
    NSMutableDictionary<NSString *, OAFavoriteItem *> *deletedPoints = [NSMutableDictionary dictionary];

    NSArray<NSString *> *files = [self getGroupFiles];
    if (files.count > 0)
    {
        for (NSString *file in files)
        {
            [self loadFileGroups:file groups:deletedGroups];
        }
    }
    // Get all points from internal file to filter later
    for (OAFavoriteGroup *group in deletedGroups.allValues)
    {
        for (OAFavoriteItem *point in group.points)
        {
            deletedPoints[[point getKey]] = point;
        }
    }
    // Hold only deleted points in map
    for (OAFavoriteItem *point in [self getPointsFromGroups:_favoriteGroups])
    {
        [deletedPoints removeObjectForKey:[point getKey]];
    }
    // Hold only deleted groups in map
    for (OAFavoriteGroup *group in _favoriteGroups)
    {
        [deletedGroups removeObjectForKey:group.name];
    }
    // Save groups to internal file
//    [self saveFile:_favoriteGroups file:internalFile];
    // Save groups to external files
    [self saveFiles:_favoriteGroups deleted:deletedPoints.allKeys];
    // Save groups to backup file
    [self backup];
}

+ (NSArray<OAFavoriteItem *> *)getPointsFromGroups:(NSArray<OAFavoriteGroup *> *)groups
{
    NSMutableArray<OAFavoriteItem *> *favouritePoints = [NSMutableArray array];
    for (OAFavoriteGroup *group in groups)
    {
        [favouritePoints addObjectsFromArray:group.points];
    }
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
                                        fileGroup.name,
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
        {
            [all removeObjectForKey:[point getKey]];
        }
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
                                        localGroup.name,
                                        GPX_FILE_EXT]];
            [self saveFile:@[localGroup] file:fileGroupPath];
        }
    }
}

+ (void)saveFile:(NSArray<OAFavoriteGroup *> *)favoriteGroups file:(NSString *)file
{
    OAGPXMutableDocument *gpx = [self asGpxFile:favoriteGroups];
    [gpx writeGpxFile:file];
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

    NSDateComponents *startDay = [[NSDateComponents alloc] init];
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
            NSDate *modifiedDate = !err ? attrs.fileModificationDate : [NSDate dateWithTimeIntervalSince1970:0];
            [result addObject:@{ @"path": filePath, @"lastDate" : attrs.fileModificationDate}];
        }

    return [NSArray arrayWithArray:result];
}

+ (NSArray<NSString *> *) getGroupFiles
{
    NSString *favoritesPath = OsmAndApp.instance.favoritesPath;
    NSFileManager *manager = [NSFileManager defaultManager];
    NSArray<NSString *> *files = [manager contentsOfDirectoryAtPath:favoritesPath error:nil];

    // acquire modification dates
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
        _cachedFavoritePoints = [NSMutableArray arrayWithArray:sortedCachedPoints];
    }
}

+ (OAFavoriteGroup *)getOrCreateGroup:(OAFavoriteItem *)item
{
    return [self getOrCreateGroup:item pointsGroup:nil];
}

+ (OAFavoriteGroup *)getOrCreateGroup:(OAFavoriteItem *)item
                          pointsGroup:(OAPointsGroup *)pointsGroup
{
    OAFavoriteGroup *favoriteGroup = _flatGroups[[item getCategory]];
    if (!favoriteGroup)
    {
        favoriteGroup = [[OAFavoriteGroup alloc] initWithPoint:item];
        _flatGroups[favoriteGroup.name] = favoriteGroup;
        [_favoriteGroups addObject:favoriteGroup];
    }
    [self updateGroupAppearance:favoriteGroup pointsGroup:pointsGroup];

    return favoriteGroup;
}

+ (void)updateGroupAppearance:(OAFavoriteGroup *)favoriteGroup
                  pointsGroup:(OAPointsGroup *)pointsGroup
{
    if (favoriteGroup && pointsGroup)
    {
        favoriteGroup.color = pointsGroup.color;
        favoriteGroup.iconName = pointsGroup.iconName;
        favoriteGroup.backgroundType = pointsGroup.backgroundType;
    }
}

+ (NSMutableArray<OAFavoriteGroup *> *) getFavoriteGroups
{
    return _favoriteGroups;
}

+ (void) addFavoriteGroup:(NSString *)name
                    color:(UIColor *)color
                 iconName:(NSString *)iconName
       backgroundIconName:(NSString *)backgroundIconName
{
    OAFavoriteGroup *group = [[OAFavoriteGroup alloc] initWithName:name
                                                         isVisible:YES
                                                             color:color];
    group.iconName = iconName;
    group.backgroundType = backgroundIconName;
    [_favoriteGroups addObject:group];
    _flatGroups[group.name] = group;
    [[OAGPXAppearanceCollection sharedInstance] saveFavoriteColorsIfNeeded:@[group]];
}

+ (BOOL)deleteFavorite:(OAFavoriteItem *)p saveImmediately:(BOOL)saveImmediately
{
    if (p)
    {
        OAFavoriteGroup *group = _flatGroups[[p getCategory]];
        if (group)
            [group.points removeObject:p];
        [self removeFavouritePoint:p];
    }
    if (saveImmediately)
        [self saveCurrentPointsIntoFile];

    return YES;
}

+ (void)removeFavouritePoint:(OAFavoriteItem *)point
{
    [_cachedFavoritePoints removeObject:point];
}

+ (BOOL) deleteNewFavoriteItem:(OAFavoriteItem *)favoritesItem
{
    return [self.class deleteFavoriteGroups:nil andFavoritesItems:@[favoritesItem] isNewFavorite:YES];
}

+ (BOOL) deleteFavoriteGroups:(NSArray<OAFavoriteGroup *> *)groupsToDelete andFavoritesItems:(NSArray<OAFavoriteItem *> *)favoritesItems
{
    return [self.class deleteFavoriteGroups:groupsToDelete andFavoritesItems:favoritesItems isNewFavorite:NO];
}

+ (BOOL) deleteFavoriteGroups:(NSArray<OAFavoriteGroup *> *)groupsToDelete andFavoritesItems:(NSArray<OAFavoriteItem *> *)favoritesItems isNewFavorite:(BOOL)isNewFavorite
{
    if (favoritesItems)
    {
        for (OAFavoriteItem *item in favoritesItems)
        {
            OAFavoriteGroup *group = _flatGroups[[item getCategory]];
            if (group)
            {
                NSInteger indexItem = [group.points indexOfObject:item];
                if (indexItem != NSNotFound)
                    [group.points removeObjectAtIndex:indexItem];
            }
            if (group.points.count == 0 && (!isNewFavorite || (isNewFavorite && group.name.length > 0)))
            {
                [_flatGroups removeObjectForKey:group.name];
                [_favoriteGroups removeObject:group];
            }
            NSInteger cachedIndexItem = [_cachedFavoritePoints indexOfObject:item];
            if (cachedIndexItem != NSNotFound)
                [_cachedFavoritePoints removeObjectAtIndex:cachedIndexItem];
            [OsmAndApp instance].favoritesCollection->removeFavoriteLocation(item.favorite);
        }
    }
    if (groupsToDelete)
    {
        QList< std::shared_ptr<OsmAnd::IFavoriteLocation> > toDelete;
        for (OAFavoriteGroup *group in groupsToDelete)
        {
            [_flatGroups removeObjectForKey:group.name];
            [_favoriteGroups removeObject:group];

            NSArray<OAFavoriteItem *> *favoriteItems = group.points;
            for (OAFavoriteItem *favoriteItem in favoriteItems)
            {
                NSInteger cachedIndexItem = [_cachedFavoritePoints indexOfObject:favoriteItem];
                if (cachedIndexItem != NSNotFound)
                {
                    [_cachedFavoritePoints removeObjectAtIndex:cachedIndexItem];
                }

                toDelete.push_back(favoriteItem.favorite);
            }
        }
        [OsmAndApp instance].favoritesCollection->removeFavoriteLocations(toDelete);
    }
    if (!isNewFavorite)
        [OAFavoritesHelper saveCurrentPointsIntoFile];
    return YES;
}

+ (NSArray<OAFavoriteGroup *> *) getGroupedFavorites:(QList< std::shared_ptr<OsmAnd::IFavoriteLocation> >)allFavorites
{
    NSMutableDictionary<NSString *, OAFavoriteGroup *> *flatGroups = [NSMutableDictionary dictionary];
    NSMutableArray<OAFavoriteGroup *> *favorites = [NSMutableArray array];
    for (const auto& favorite : allFavorites)
    {
        OAFavoriteItem* favData = [[OAFavoriteItem alloc] initWithFavorite:favorite];
        NSString *groupName = [favData getCategory];
        UIColor *color = [favData getColor];
        OAFavoriteGroup *group = [flatGroups objectForKey:groupName];
        if (!group)
        {
            group = [[OAFavoriteGroup alloc] initWithName:groupName isVisible:[favData isVisible] color:color];
            [flatGroups setObject:group forKey:groupName];
            [favorites addObject:group];
        }
        [group addPoint:favData];
    }
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
    [favorites sortUsingDescriptors:[NSArray arrayWithObject:sort]];
    return favorites;
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
        for (OAFavoriteItem *fp in [self getFavoriteItems])
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

+ (OAGPXMutableDocument *) asGpxFile:(NSArray<OAFavoriteGroup *> *)favoriteGroups
{
    OAGPXMutableDocument *gpx = [[OAGPXMutableDocument alloc] init];
    [gpx setVersion:[NSString stringWithFormat:@"%@ %@", @"OsmAnd", OAAppVersionDependentConstants.getVersion]];
    for (OAFavoriteGroup *group in favoriteGroups)
    {
        [gpx addPointsGroup:[group toPointsGroup]];
    }
    return gpx;
}

+ (void) addParkingReminderToCalendar
{
    EKEventStore *eventStore = [[EKEventStore alloc] init];
    [eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
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
                EKEvent *event = [EKEvent eventWithEventStore:eventStore];
                event.title = OALocalizedString(@"pickup_car");
                
                OAParkingPositionPlugin *plugin = (OAParkingPositionPlugin *) [OAPlugin getPlugin:OAParkingPositionPlugin.class];
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
                        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
                        [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok") style:UIAlertActionStyleCancel handler:nil]];
                        [UIApplication.sharedApplication.mainWindow.rootViewController presentViewController:alert animated:YES completion:nil];
                    }
                    else
                        [plugin setEventIdentifier:[event.eventIdentifier copy]];
                }
            }
        });
    }];
}

+ (void) removeParkingReminderFromCalendar
{
    OAParkingPositionPlugin *plugin = (OAParkingPositionPlugin *) [OAPlugin getPlugin:OAParkingPositionPlugin.class];
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
    UIImage *resultImg;
    NSString *backgrounfIconName = [@"bg_point_" stringByAppendingString:backgroundIcon];
    UIImage *backgroundImg = [UIImage imageNamed:backgrounfIconName];
    backgroundImg = [OAUtilities tintImageWithColor:backgroundImg color:color];

    UIImage *iconImg = [OAUtilities getMxIcon:[@"mx_" stringByAppendingString:icon]];
    iconImg = [OAUtilities tintImageWithColor:iconImg color:UIColor.whiteColor];

    CGFloat centredIconOffset = (backgroundImg.size.width - iconImg.size.width) / 2.0;
    UIGraphicsBeginImageContextWithOptions(backgroundImg.size, NO, [UIScreen mainScreen].scale);
    [backgroundImg drawInRect:CGRectMake(0.0, 0.0, backgroundImg.size.width, backgroundImg.size.height)];
    [iconImg drawInRect:CGRectMake(centredIconOffset, centredIconOffset, iconImg.size.width, iconImg.size.height)];
    resultImg = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return resultImg;
}

@end

@implementation OAFavoriteGroup

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _points = [NSMutableArray array];
    }
    return self;
}

- (instancetype)initWithPoint:(OAFavoriteItem *)point
{
    self = [self init];
    if (self)
    {
        _name = [point getCategory];
        _color = [point getColor];
        _isVisible = [point isVisible];
        _iconName = [point getIcon];
        _backgroundType = [point getBackgroundIcon];
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
    return [UIColor colorRGB:_color equalToColorRGB:UIColor.whiteColor] ? UIColorFromRGB(color_chart_orange) : _color;
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
        return OALocalizedString(@"favorites_item");
    else
        return name;
}

+ (NSString *) convertDisplayNameToGroupIdName:(NSString *)name
{
    if ([self isPersonalCategoryDisplayName:name])
        return kPersonalCategory;
    else if ([name isEqualToString:OALocalizedString(@"favorites_item")])
        return @"";
    return name;
}

- (OAPointsGroup *)toPointsGroup
{
    OAPointsGroup *pointsGroup = [[OAPointsGroup alloc] initWithName:_name
                                                            iconName:_iconName
                                                      backgroundType:_backgroundType
                                                               color:_color];

    for (OAFavoriteItem *point in _points)
    {
        OAWptPt *wptPt = [point toWpt];
        [pointsGroup.points addObject:wptPt];
    }
    return pointsGroup;
}

+ (OAFavoriteGroup *)fromPointsGroup:(OAPointsGroup *)pointsGroup
{
    OAFavoriteGroup *favoriteGroup = [[OAFavoriteGroup alloc] init];
    favoriteGroup.name = pointsGroup.name;
    favoriteGroup.color = pointsGroup.color;
    favoriteGroup.iconName = pointsGroup.iconName;
    favoriteGroup.backgroundType = pointsGroup.backgroundType;
    for (OAWptPt *point in pointsGroup.points)
    {
        [favoriteGroup.points addObject:[OAFavoriteItem fromWpt:point
                                                       category:nil]];
    }
    if (favoriteGroup.points && favoriteGroup.points.count > 0)
        favoriteGroup.isVisible = favoriteGroup.points[0].isVisible;
    return favoriteGroup;
}

@end
