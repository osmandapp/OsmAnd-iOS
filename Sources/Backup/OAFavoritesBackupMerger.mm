//
//  OAFavoritesBackupMerger.mm
//  OsmAnd Maps
//

#import "OAFavoritesBackupMerger.h"

#import <CoreLocation/CoreLocation.h>

#import "OABackupHelper.h"
#import "OABackupInfo.h"
#import "OAFavoritesHelper.h"
#import "OAFavoritesSettingsItem.h"
#import "OAFavoriteItem.h"
#import "OALocalFile.h"
#import "OARemoteFile.h"
#import "OASettingsItemType.h"
#import "OAUtilities.h"
#import "OsmAndApp.h"
#import "OsmAnd_Maps-Swift.h"

static NSString * const kFavoritesSnapshotDirectory = @"favorites_sync";

@interface OAMergedFavoritesSettingsItem : OAFavoritesSettingsItem

- (instancetype)initWithBaseItem:(OAFavoritesSettingsItem *)baseItem
                       localGroup:(OAFavoriteGroup *)localGroup
                      mergedGroup:(OAFavoriteGroup *)mergedGroup
               sourceModifiedTime:(long)sourceModifiedTime
                     baseSyncTime:(long)baseSyncTime;
- (void)finishUpload:(NSString *)fileName uploadTime:(long)uploadTime;

@end

@implementation OAFavoritesBackupMerger

+ (void)prepareMergeUploads:(OABackupInfo *)info backupHelper:(OABackupHelper *)backupHelper
{
    for (NSArray *pair in info.filesToMerge.copy)
    {
        if (pair.count != 2)
            continue;

        OALocalFile *localFile = pair.firstObject;
        OARemoteFile *remoteFile = pair.lastObject;
        if (![localFile.item isKindOfClass:OAFavoritesSettingsItem.class])
            continue;

        OAFavoritesSettingsItem *localItem = (OAFavoritesSettingsItem *)localFile.item;
        OAFavoriteGroup *localGroup = localItem.items.count == 1 ? localItem.items.firstObject : nil;
        if (!localGroup || localGroup.isPersonal)
            continue;

        OAFavoriteGroup *baseGroup = [self loadSnapshot:remoteFile.name syncTime:localFile.uploadTime];
        OAFavoriteGroup *remoteGroup = baseGroup ? [self downloadGroup:remoteFile backupHelper:backupHelper] : nil;
        OAFavoriteGroup *mergedGroup = [self mergeBase:baseGroup local:localGroup remote:remoteGroup];
        if (!mergedGroup)
            continue;

        localFile.item = [[OAMergedFavoritesSettingsItem alloc] initWithBaseItem:localItem
                                                                     localGroup:localGroup
                                                                    mergedGroup:mergedGroup
                                                             sourceModifiedTime:localFile.localModifiedTime
                                                                   baseSyncTime:localFile.uploadTime];
        [info.filesToUpload addObject:localFile];
        [info.filesToMerge removeObject:pair];
    }
}

+ (void)onUploadSuccess:(OASettingsItem *)item fileName:(NSString *)fileName uploadTime:(long)uploadTime
{
    if (uploadTime <= 0 || ![item isKindOfClass:OAFavoritesSettingsItem.class])
        return;
    if (![fileName isEqualToString:[BackupUtils getItemFileName:item]])
        return;

    OAFavoritesSettingsItem *favoritesItem = (OAFavoritesSettingsItem *)item;
    if ([favoritesItem isKindOfClass:OAMergedFavoritesSettingsItem.class])
    {
        // Upload callbacks run in parallel, while applying a group mutates shared Favorites state.
        @synchronized (self)
        {
            [(OAMergedFavoritesSettingsItem *)favoritesItem finishUpload:fileName uploadTime:uploadTime];
        }
    }
    else if (favoritesItem.localModifiedTime == favoritesItem.lastModifiedTime)
    {
        OAFavoriteGroup *group = favoritesItem.items.count == 1 ? favoritesItem.items.firstObject : nil;
        [self saveSnapshot:group fileName:fileName syncTime:uploadTime];
    }
    else
    {
        OAFavoriteGroup *group = favoritesItem.items.count == 1 ? favoritesItem.items.firstObject : nil;
        if (group && [OAFavoritesHelper groupByName:group.name])
            favoritesItem.localModifiedTime = MAX((long)(NSDate.date.timeIntervalSince1970 * 1000.0), uploadTime + 1);
    }
}

+ (void)onDownloadSuccess:(OASettingsItem *)item remoteFile:(OARemoteFile *)remoteFile
{
    if (![item isKindOfClass:OAFavoritesSettingsItem.class])
        return;

    OAFavoritesSettingsItem *favoritesItem = (OAFavoritesSettingsItem *)item;
    OAFavoriteGroup *downloaded = favoritesItem.items.count == 1 ? favoritesItem.items.firstObject : nil;
    OAFavoriteGroup *current = downloaded ? [OAFavoritesHelper groupByName:downloaded.name] : nil;
    if (downloaded && [self sameGroup:downloaded other:current])
        [self saveSnapshot:downloaded fileName:remoteFile.name syncTime:remoteFile.updatetimems];
}

#pragma mark - Snapshots

+ (OAFavoriteGroup *)downloadGroup:(OARemoteFile *)remoteFile backupHelper:(OABackupHelper *)backupHelper
{
    if (remoteFile.isDeleted)
        return nil;

    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:
                      [NSString stringWithFormat:@"favorites-merge-%@.gpx", NSUUID.UUID.UUIDString]];
    @try
    {
        NSString *error = [backupHelper downloadFile:path remoteFile:remoteFile listener:nil];
        return error.length == 0 ? [self readGroup:path] : nil;
    }
    @catch (NSException *exception)
    {
        NSLog(@"FavoritesBackupMerger: failed to download %@: %@", remoteFile.name, exception.reason);
        return nil;
    }
    @finally
    {
        [NSFileManager.defaultManager removeItemAtPath:path error:nil];
    }
}

+ (OAFavoriteGroup *)loadSnapshot:(NSString *)fileName syncTime:(long)syncTime
{
    NSString *path = [self snapshotPath:fileName syncTime:syncTime];
    return path && [NSFileManager.defaultManager fileExistsAtPath:path] ? [self readGroup:path] : nil;
}

+ (void)saveSnapshot:(OAFavoriteGroup *)group fileName:(NSString *)fileName syncTime:(long)syncTime
{
    NSString *path = [self snapshotPath:fileName syncTime:syncTime];
    if (!group || !path || syncTime <= 0)
        return;

    NSFileManager *manager = NSFileManager.defaultManager;
    NSString *directory = path.stringByDeletingLastPathComponent;
    NSError *error = nil;
    if (![manager createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:&error])
    {
        NSLog(@"FavoritesBackupMerger: failed to create snapshot directory: %@", error.localizedDescription);
        return;
    }
    [[NSURL fileURLWithPath:[self snapshotRoot]] setResourceValue:@YES
                                                           forKey:NSURLIsExcludedFromBackupKey
                                                            error:nil];

    NSString *temporaryPath = [directory stringByAppendingPathComponent:
                               [NSString stringWithFormat:@".%@.gpx", NSUUID.UUID.UUIDString]];
    OAFavoriteGroup *snapshotGroup = [self copyGroup:group];
    OASGpxFile *gpx = [OAFavoritesHelper asGpxFile:@[snapshotGroup]];
    OASKException *exception = [OASGpxUtilities.shared writeGpxFileFile:
                                [[OASKFile alloc] initWithFilePath:temporaryPath] gpxFile:gpx];
    if (exception || ![manager fileExistsAtPath:temporaryPath])
    {
        [manager removeItemAtPath:temporaryPath error:nil];
        NSLog(@"FavoritesBackupMerger: failed to save snapshot for %@", fileName);
        return;
    }

    [manager removeItemAtPath:path error:nil];
    if (![manager moveItemAtPath:temporaryPath toPath:path error:&error])
    {
        [manager removeItemAtPath:temporaryPath error:nil];
        NSLog(@"FavoritesBackupMerger: failed to install snapshot for %@: %@", fileName, error.localizedDescription);
        return;
    }

    for (NSString *oldFile in [manager contentsOfDirectoryAtPath:directory error:nil])
    {
        NSString *oldPath = [directory stringByAppendingPathComponent:oldFile];
        if (![oldPath isEqualToString:path])
            [manager removeItemAtPath:oldPath error:nil];
    }
}

+ (NSString *)snapshotRoot
{
    return [OsmAndApp.instance.dataPath stringByAppendingPathComponent:kFavoritesSnapshotDirectory];
}

+ (NSString *)snapshotPath:(NSString *)fileName syncTime:(long)syncTime
{
    if (syncTime <= 0 || fileName.length == 0 || ![fileName.lastPathComponent isEqualToString:fileName])
        return nil;
    fileName = fileName.precomposedStringWithCanonicalMapping;
    NSString *directory = [[self snapshotRoot] stringByAppendingPathComponent:fileName];
    return [directory stringByAppendingPathComponent:[NSString stringWithFormat:@"%ld.gpx", syncTime]];
}

+ (OAFavoriteGroup *)readGroup:(NSString *)path
{
    OASGpxFile *gpx = [OAFavoritesHelper loadGpxFile:path];
    if (!gpx || gpx.pointsGroups.count != 1)
        return nil;

    OASGpxUtilitiesPointsGroup *pointsGroup = gpx.pointsGroups.allValues.firstObject;
    OAFavoriteGroup *group = [OAFavoriteGroup fromPointsGroup:pointsGroup];
    group.isVisible = !pointsGroup.isHidden;
    return group.points.count == gpx.getPointsList.count ? group : nil;
}

#pragma mark - Merge

+ (OAFavoriteGroup *)mergeBase:(OAFavoriteGroup *)base
                          local:(OAFavoriteGroup *)local
                         remote:(OAFavoriteGroup *)remote
{
    if (!base || !local || !remote ||
        ![self sameAppearance:base other:local] ||
        ![self sameAppearance:base other:remote])
        return nil;

    NSMutableDictionary<NSString *, OAFavoriteItem *> *basePoints = [self pointsByName:base];
    NSMutableDictionary<NSString *, OAFavoriteItem *> *localPoints = [self pointsByName:local];
    NSMutableDictionary<NSString *, OAFavoriteItem *> *remotePoints = [self pointsByName:remote];
    if (!basePoints || !localPoints || !remotePoints)
        return nil;

    NSMutableDictionary<NSString *, OAFavoriteItem *> *localAdditions = localPoints.mutableCopy;
    NSMutableDictionary<NSString *, OAFavoriteItem *> *remoteAdditions = remotePoints.mutableCopy;
    [localAdditions removeObjectsForKeys:basePoints.allKeys];
    [remoteAdditions removeObjectsForKeys:basePoints.allKeys];

    NSMutableArray<OAFavoriteItem *> *mergedPoints = [NSMutableArray array];
    for (OAFavoriteItem *basePoint in base.points)
    {
        NSString *name = basePoint.getName;
        OAFavoriteItem *localPoint = localPoints[name];
        OAFavoriteItem *remotePoint = remotePoints[name];
        [localPoints removeObjectForKey:name];
        [remotePoints removeObjectForKey:name];

        if (!localPoint && !remotePoint)
        {
            if ([self hasRenameOf:basePoint in:localAdditions] ||
                [self hasRenameOf:basePoint in:remoteAdditions])
                return nil;
            continue;
        }

        BOOL localUnchanged = [self samePoint:basePoint other:localPoint];
        BOOL remoteUnchanged = [self samePoint:basePoint other:remotePoint];
        if (!localUnchanged && !remoteUnchanged)
            return nil;

        OAFavoriteItem *result = localUnchanged ? remotePoint : localPoint;
        if (result)
            [mergedPoints addObject:[self copyPoint:result]];
    }

    NSMutableDictionary<NSString *, OAFavoriteItem *> *additions = localPoints.mutableCopy;
    for (NSString *name in remotePoints)
    {
        if (additions[name])
            return nil;
        additions[name] = remotePoints[name];
    }
    for (NSString *name in [additions.allKeys sortedArrayUsingSelector:@selector(compare:)])
        [mergedPoints addObject:[self copyPoint:additions[name]]];

    OAFavoriteGroup *merged = [self copyGroup:local];
    merged.points = mergedPoints;
    return merged;
}

+ (NSMutableDictionary<NSString *, OAFavoriteItem *> *)pointsByName:(OAFavoriteGroup *)group
{
    NSMutableDictionary<NSString *, OAFavoriteItem *> *points = [NSMutableDictionary dictionary];
    for (OAFavoriteItem *point in group.points)
    {
        NSString *name = point.getName;
        if (name.length == 0 || points[name])
            return nil;
        points[name] = point;
    }
    return points;
}

+ (BOOL)sameAppearance:(OAFavoriteGroup *)first other:(OAFavoriteGroup *)second
{
    return second && [first.name isEqualToString:second.name] &&
           first.color.toARGBNumber == second.color.toARGBNumber &&
           [[self normalizedIcon:first.iconName] isEqualToString:[self normalizedIcon:second.iconName]] &&
           [[self normalizedBackground:first.backgroundType] isEqualToString:[self normalizedBackground:second.backgroundType]] &&
           first.isVisible == second.isVisible &&
           first.isPinned == second.isPinned;
}

+ (BOOL)sameGroup:(OAFavoriteGroup *)first other:(OAFavoriteGroup *)second
{
    if (!second || ![self sameAppearance:first other:second])
        return NO;

    NSMutableDictionary<NSString *, OAFavoriteItem *> *secondPoints = [self pointsByName:second];
    if (!secondPoints || first.points.count != secondPoints.count)
        return NO;
    for (OAFavoriteItem *point in first.points)
    {
        if (![self samePoint:point other:secondPoints[point.getName]])
            return NO;
    }
    return YES;
}

+ (BOOL)samePoint:(OAFavoriteItem *)first other:(OAFavoriteItem *)second
{
    return second && [first.getName isEqualToString:second.getName] &&
           [self samePointContent:first other:second];
}

+ (BOOL)samePointContent:(OAFavoriteItem *)first other:(OAFavoriteItem *)second
{
    if (!second || ![first.getCategory isEqualToString:second.getCategory] ||
        ![self sameText:first.getDescription other:second.getDescription] ||
        ![self sameText:first.getAddress other:second.getAddress] ||
        ![self sameText:first.getAmenityOriginName other:second.getAmenityOriginName] ||
        first.getCalendarEvent != second.getCalendarEvent ||
        first.getColor.toARGBNumber != second.getColor.toARGBNumber ||
        ![first.getIcon isEqualToString:second.getIcon] ||
        ![first.getBackgroundIcon isEqualToString:second.getBackgroundIcon] ||
        first.isVisible != second.isVisible ||
        ![self sameTime:first.getPickupTime other:second.getPickupTime])
        return NO;

    CLLocation *firstLocation = [[CLLocation alloc] initWithLatitude:first.getLatitude longitude:first.getLongitude];
    CLLocation *secondLocation = [[CLLocation alloc] initWithLatitude:second.getLatitude longitude:second.getLongitude];
    return [firstLocation distanceFromLocation:secondLocation] < 0.1;
}

+ (BOOL)hasRenameOf:(OAFavoriteItem *)basePoint
                 in:(NSDictionary<NSString *, OAFavoriteItem *> *)additions
{
    for (OAFavoriteItem *point in additions.allValues)
    {
        if ([self samePointContent:basePoint other:point])
            return YES;
    }
    return NO;
}

+ (BOOL)sameText:(NSString *)first other:(NSString *)second
{
    return [first isEqualToString:second] || (first.length == 0 && second.length == 0);
}

+ (BOOL)sameTime:(NSDate *)first other:(NSDate *)second
{
    if (!first || !second)
        return first == second;
    return fabs([first timeIntervalSinceDate:second]) < 1.0;
}

+ (NSString *)normalizedIcon:(NSString *)icon
{
    return icon.length > 0 ? icon : DEFAULT_ICON_NAME_KEY;
}

+ (NSString *)normalizedBackground:(NSString *)background
{
    return background.length > 0 ? background : DEFAULT_ICON_SHAPE_KEY;
}

+ (OAFavoriteItem *)copyPoint:(OAFavoriteItem *)point
{
    std::shared_ptr<OsmAnd::IFavoriteLocation> favorite =
        [OAFavoritesHelper getFavoritesCollection]->copyFavoriteLocation(point.favorite);
    OAFavoriteItem *copy = [[OAFavoriteItem alloc] initWithFavorite:favorite];
    [copy setVisible:point.isVisible];
    return copy;
}

+ (OAFavoriteGroup *)copyGroup:(OAFavoriteGroup *)group
{
    OAFavoriteGroup *copy = [[OAFavoriteGroup alloc] initWithName:group.name
                                                       isVisible:group.isVisible
                                                           color:group.color];
    copy.isPinned = group.isPinned;
    copy.iconName = group.iconName;
    copy.backgroundType = group.backgroundType;
    for (OAFavoriteItem *point in group.points)
        [copy.points addObject:[self copyPoint:point]];
    return copy;
}

@end

@implementation OAMergedFavoritesSettingsItem
{
    OAFavoriteGroup *_localGroup;
    OAFavoriteGroup *_mergedGroup;
    long _sourceModifiedTime;
    long _baseSyncTime;
}

- (instancetype)initWithBaseItem:(OAFavoritesSettingsItem *)baseItem
                       localGroup:(OAFavoriteGroup *)localGroup
                      mergedGroup:(OAFavoriteGroup *)mergedGroup
               sourceModifiedTime:(long)sourceModifiedTime
                     baseSyncTime:(long)baseSyncTime
{
    self = [super initWithItems:@[mergedGroup] baseItem:baseItem];
    if (self)
    {
        _localGroup = [OAFavoritesBackupMerger copyGroup:localGroup];
        _mergedGroup = mergedGroup;
        _sourceModifiedTime = sourceModifiedTime;
        _baseSyncTime = baseSyncTime;
    }
    return self;
}

- (long)lastModifiedTime
{
    return _sourceModifiedTime;
}

- (void)finishUpload:(NSString *)fileName uploadTime:(long)uploadTime
{
    OAFavoriteGroup *current = [OAFavoritesHelper groupByName:_localGroup.name];
    if (![OAFavoritesBackupMerger sameGroup:_mergedGroup other:current] &&
        [OAFavoritesBackupMerger sameGroup:_localGroup other:current])
    {
        self.shouldReplace = YES;
        [self processDuplicateItems];
        [self apply];
        current = [OAFavoritesHelper groupByName:_mergedGroup.name];
    }

    if ([OAFavoritesBackupMerger sameGroup:_mergedGroup other:current])
    {
        self.localModifiedTime = _sourceModifiedTime;
        [OAFavoritesBackupMerger saveSnapshot:_mergedGroup fileName:fileName syncTime:uploadTime];
    }
    else
    {
        if (current)
        {
            // Preserve the old common base so the next preparation keeps both sides in conflict.
            [OABackupHelper.sharedInstance updateFileUploadTime:[OASettingsItemType typeName:self.type]
                                                       fileName:fileName
                                                     uploadTime:_baseSyncTime];
            self.localModifiedTime = MAX((long)(NSDate.date.timeIntervalSince1970 * 1000.0), uploadTime + 1);
        }
    }
}

@end
