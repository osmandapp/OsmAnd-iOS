//
//  OASharedSearchAppAPIs.mm
//  OsmAnd
//
//  Copyright © 2026 OsmAnd. All rights reserved.
//

#import "OASharedSearchAppAPIs.h"
#import "OASharedSearchObjects.h"
#import "OAQuickSearchHelper.h"
#import "OAFavoritesHelper.h"
#import "OAFavoriteItem.h"
#import "OAFavoriteGroup.h"
#import "OAGPXDatabase.h"
#import "OAHistoryHelper.h"
#import "OAHistoryItem.h"
#import "OAPointDescription.h"
#import "OAPOIHelper.h"
#import "OAPOIType.h"
#import "OAPOIFiltersHelper.h"
#import "OAPOIUIFilter.h"
#import "OAResourcesUIHelper.h"
#import "OAManageResourcesViewController.h"
#import "OAWorldRegion.h"
#import "OsmAndApp.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapViewController.h"
#import "OAAtomicInteger.h"
#import "Localization.h"
#import "OsmAnd_Maps-Swift.h"

static const NSInteger SearchGpxMaxResults = 7;
static const NSInteger SearchGpxMaxResultsPerType = 4;

@implementation OASharedSearchAppAPI

+ (OASObjectType *)searchType
{
    [NSException raise:NSInternalInconsistencyException format:@"A search source must declare its result type"];
    return nil;
}

- (instancetype)init
{
    OASObjectType *type = [self.class searchType];
    return [super initWithSearchTypes:[OASKotlinArray arrayWithSize:1 init:^id(OASInt *index) {
        return type;
    }]];
}

- (BOOL)isSearchMoreAvailablePhrase:(OASSearchPhrase *)phrase
{
    return NO;
}

- (int32_t)getSearchPriorityP:(OASSearchPhrase *)phrase
{
    return [phrase isNoSelectedType] && [phrase isUnknownSearchWordPresent] ? 150 : -1;
}

@end

// Construct the collator once per query, before visiting the app's objects.
static OASNameStringMatcher *containsMatcher(OASSearchPhrase *phrase)
{
    NSString *text = [phrase getFullSearchPhrase];
    if (text.length <= 1 && [phrase isNoSelectedType])
        return nil;
    return [[OASNameStringMatcher alloc] initWithNamePart:[text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet]
                                                   mode:OASKStringMatcherMode.checkContains];
}

static OASSearchResult *favoriteResult(OAFavoriteItem *point, OASSearchPhrase *phrase, int priority, int zoom)
{
    OASSearchResult *result = [[OASSearchResult alloc] initWithSp:phrase];
    result.localeName = point.getDisplayName;
    result.object = point;
    result.objectType = OASObjectType.favorite;
    result.priority = priority;
    const auto location = point.favorite->getLatLon();
    result.location = [[OASKLatLon alloc] initWithLatitude:location.latitude longitude:location.longitude];
    result.preferredZoom = zoom;
    return result;
}

@implementation OASharedSearchFavoritesAPI

+ (OASObjectType *)searchType { return OASObjectType.favorite; }

- (int32_t)getSearchPriorityP:(OASSearchPhrase *)phrase
{
    return [phrase getLastSelectedWord].getType == OASObjectType.favoriteGroup ? 150 : [super getSearchPriorityP:phrase];
}

- (NSArray<OAFavoriteItem *> *)favoriteItems
{
    return [OAFavoritesHelper getFavoriteItems];
}

- (BOOL)searchPhrase:(OASSearchPhrase *)phrase resultMatcher:(OASSearchUICoreSearchResultMatcher *)matcher
{
    OAFavoriteGroup *group = [phrase getLastSelectedWord].getType == OASObjectType.favoriteGroup ? [phrase getLastSelectedWord].getResult.object : nil;
    // Selected words identify the group; only the remaining text filters its points.
    NSString *query = [[phrase getUnknownSearchPhrase] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    OASNameStringMatcher *nameMatcher = group
        ? (query.length <= 1 ? nil : [[OASNameStringMatcher alloc] initWithNamePart:query mode:OASKStringMatcherMode.checkContains])
        : containsMatcher(phrase);
    for (OAFavoriteItem *point in [self favoriteItems])
    {
        if ([matcher isCancelled])
            return NO;
        if (point.isVisible && (!group || [point.getCategory isEqualToString:group.name])
            && (!nameMatcher || [nameMatcher matchesName:point.getDisplayName]))
            [matcher publishObj:favoriteResult(point, phrase, 150, PREFERRED_FAVORITE_ZOOM)];
    }
    return YES;
}

@end

@implementation OASharedSearchFavoritesCategoryAPI

+ (OASObjectType *)searchType { return OASObjectType.favoriteGroup; }

- (NSArray<OAFavoriteGroup *> *)favoriteGroups
{
    return [OAFavoritesHelper favoriteGroups];
}

- (BOOL)searchPhrase:(OASSearchPhrase *)phrase resultMatcher:(OASSearchUICoreSearchResultMatcher *)matcher
{
    OASNameStringMatcher *nameMatcher = [phrase getFirstUnknownNameStringMatcher];
    for (OAFavoriteGroup *group in [self favoriteGroups])
    {
        if ([matcher isCancelled])
            return NO;
        NSString *name = [OAFavoriteGroup getDisplayName:group.name];
        if (!group.isVisible || ![nameMatcher matchesName:name])
            continue;
        if (group.points.count < 5)
        {
            for (OAFavoriteItem *point in group.points)
            {
                if ([matcher isCancelled])
                    return NO;
                [matcher publishObj:favoriteResult(point, phrase, 150, PREFERRED_FAVORITE_ZOOM)];
            }
        }
        else
        {
            OASSearchResult *result = [[OASSearchResult alloc] initWithSp:phrase];
            result.localeName = name;
            result.object = group;
            result.objectType = OASObjectType.favoriteGroup;
            result.priority = 151;
            result.preferredZoom = PREFERRED_FAVORITES_GROUP_ZOOM;
            [matcher publishObj:result];
        }
    }
    return YES;
}

@end

@implementation OASharedSearchGpxAPI

+ (OASObjectType *)searchType { return OASObjectType.gpxTrack; }

- (NSArray<OASGpxDataItem *> *)gpxItems
{
    return OAGPXDatabase.sharedDb.getDataItems;
}

- (BOOL)searchPhrase:(OASSearchPhrase *)phrase resultMatcher:(OASSearchUICoreSearchResultMatcher *)matcher
{
    NSInteger waypointCount = 0;
    for (OASSearchResult *result in [matcher getRequestResults])
        if (result.objectType == OASObjectType.wpt)
            waypointCount++;
    NSInteger limit = MIN(SearchGpxMaxResultsPerType, SearchGpxMaxResults - waypointCount);
    NSInteger count = 0;
    OASNameStringMatcher *nameMatcher = containsMatcher(phrase);
    for (OASGpxDataItem *item in [self gpxItems])
    {
        if ([matcher isCancelled])
            return NO;
        if (count >= limit)
            break;
        if ([item.gpxFolderName hasPrefix:@"Temp"])
            continue;
        NSString *name = item.gpxFileName;
        if (nameMatcher && ![nameMatcher matchesName:name])
            continue;
        OASSearchResult *result = [[OASSearchResult alloc] initWithSp:phrase];
        result.objectType = OASObjectType.gpxTrack;
        result.localeName = name;
        result.relatedObject = item;
        result.priority = 153;
        result.preferredZoom = PREFERRED_GPX_FILE_ZOOM;
        [matcher publishObj:result];
        count++;
    }
    return YES;
}

@end

// The file and its points stay alive after the map's selected files change.
@interface OASearchGpxSnapshot : NSObject
@property (nonatomic) OASGpxFile *file;
@property (nonatomic, copy) NSArray<OASWptPt *> *points;
@property (nonatomic, copy) NSString *name;
@end

@implementation OASearchGpxSnapshot
@end

@implementation OASharedSearchWptAPI

+ (OASObjectType *)searchType { return OASObjectType.wpt; }

- (int32_t)getSearchPriorityP:(OASSearchPhrase *)phrase
{
    return [phrase isNoSelectedType] ? 150 : -1;
}

- (void)readGpxFiles:(void (^)(NSArray<OASGpxFile *> *, NSArray<NSString *> *))reader
{
    OAMapViewController *map = OARootViewController.instance.mapPanel.mapViewController;
    if (map)
        [map readSearchableGpxFiles:reader];
    else
        reader(@[], @[]);
}

- (NSArray<OASearchGpxSnapshot *> *)gpxSnapshot:(OASSearchUICoreSearchResultMatcher *)matcher
{
    __block NSArray<OASearchGpxSnapshot *> *snapshot;
    dispatch_semaphore_t ready = dispatch_semaphore_create(0);
    OAAtomicInteger *abandoned = [OAAtomicInteger atomicInteger:0];
    dispatch_block_t read = ^{
        if ([abandoned get] != 0)
            return;
        [self readGpxFiles:^(NSArray<OASGpxFile *> *files, NSArray<NSString *> *paths) {
            NSMutableArray *items = [NSMutableArray arrayWithCapacity:files.count];
            for (NSUInteger i = 0; i < files.count; i++)
            {
                OASearchGpxSnapshot *item = [OASearchGpxSnapshot new];
                item.file = files[i];
                item.points = [files[i].getPointsList copy];
                item.name = i < paths.count ? paths[i].lastPathComponent : OALocalizedString(@"shared_string_currently_recording_track");
                [items addObject:item];
            }
            snapshot = [items copy];
        }];
        dispatch_semaphore_signal(ready);
    };
    if (NSThread.isMainThread)
    {
        read();
        return snapshot;
    }
    dispatch_async(dispatch_get_main_queue(), read);
    CFTimeInterval deadline = CACurrentMediaTime() + 3;
    while (dispatch_semaphore_wait(ready, dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_MSEC)) != 0)
    {
        if ([matcher isCancelled] || CACurrentMediaTime() >= deadline)
        {
            [abandoned incrementAndGet];
            if (![matcher isCancelled])
                NSLog(@"Waypoint search timed out waiting for the map's GPX selection");
            return nil;
        }
    }
    return snapshot;
}

- (BOOL)searchPhrase:(OASSearchPhrase *)phrase resultMatcher:(OASSearchUICoreSearchResultMatcher *)matcher
{
    if ([phrase isEmpty] || [matcher isCancelled])
        return NO;
    NSArray<OASearchGpxSnapshot *> *files = [self gpxSnapshot:matcher];
    if (!files)
        return NO;
    OASNameStringMatcher *nameMatcher = containsMatcher(phrase);
    NSInteger count = 0;
    for (OASearchGpxSnapshot *file in files)
    {
        for (OASWptPt *point in file.points)
        {
            if ([matcher isCancelled])
                return NO;
            if (count >= SearchGpxMaxResultsPerType)
                return YES;
            NSString *name = [point.name stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
            if (name.length == 0 || (nameMatcher && ![nameMatcher matchesName:name]))
                continue;
            OASSearchResult *result = [[OASSearchResult alloc] initWithSp:phrase];
            result.object = point;
            result.relatedObject = file.file;
            result.objectType = OASObjectType.wpt;
            result.localeName = name;
            result.localeRelatedObjectName = file.name;
            result.location = [[OASKLatLon alloc] initWithLatitude:point.position.latitude longitude:point.position.longitude];
            result.priority = 152;
            result.preferredZoom = PREFERRED_WPT_ZOOM;
            [matcher publishObj:result];
            count++;
        }
    }
    return YES;
}

@end

@implementation OASharedSearchHistoryAPI

+ (OASObjectType *)searchType { return OASObjectType.recentObj; }

- (int32_t)getSearchPriorityP:(OASSearchPhrase *)phrase
{
    return [phrase isEmpty] ? 150 : -1;
}

- (NSArray<OAHistoryItem *> *)historyItems
{
    OAHistoryHelper *helper = OAHistoryHelper.sharedInstance;
    return [helper getPointsHavingTypes:helper.searchTypes exceptNavigation:NO limit:0];
}

- (OASGpxDataItem *)gpxItemNamed:(NSString *)name
{
    return [OAGPXDatabase.sharedDb getGPXItemByFileName:name];
}

- (BOOL)searchPhrase:(OASSearchPhrase *)phrase resultMatcher:(OASSearchUICoreSearchResultMatcher *)resultMatcher
{
    int p = 0;
    for (OAHistoryItem *point in [self historyItems])
    {
        if ([resultMatcher isCancelled])
            return NO;
        BOOL publish = NO;
        OASSearchResult *sr = [[OASSearchResult alloc] initWithSp:phrase];
        OAPointDescription *pd = [[OAPointDescription alloc] initWithType:[point getPointDescriptionType]
                                                                 typeName:point.typeName
                                                                     name:point.name];
        if ([pd isPoiType])
        {
            NSString *name = pd.name;
            OAPOIHelper *mapPoiTypes = [OAPOIHelper sharedInstance];
            OAPOIBaseType *pt = [mapPoiTypes getAnyPoiTypeByName:name];
            if (!pt)
            {
                pt = [mapPoiTypes getAnyPoiAdditionalTypeByKey:name];
            }
            if (pt)
            {
                if ([OSM_WIKI_CATEGORY isEqualToString:pt.name])
                    sr.localeName = [NSString stringWithFormat:@"%@ (%@)", pt.nameLocalized, [mapPoiTypes getAllLanguagesTranslationSuffix]];
                else
                    sr.localeName = [PoiAdditionalLabels getSearchName:pt];
                sr.object = [OASharedSearchObjects sharedObjectFor:pt];
                sr.relatedObject = point;
                sr.priorityDistance = 0;
                sr.objectType = OASObjectType.poiType;
                publish = YES;
            }
        }
        else if ([pd isCustomPoiFilter])
        {
            OAPOIUIFilter *filter = [[OAPOIFiltersHelper sharedInstance] getFilterById:pd.name includeDeleted:YES];
            if (filter)
            {
                sr.localeName = filter.name;
                sr.object = [OASharedSearchObjects sharedObjectFor:filter];
                sr.relatedObject = point;
                sr.objectType = OASObjectType.poiType;
                publish = YES;
            }
        }
        else if ([pd isGpxFile])
        {
            OASGpxDataItem *dataItem = [self gpxItemNamed:pd.name];
            if (dataItem)
            {
                sr.localeName = [dataItem gpxFileName];
                sr.object = point;
                sr.objectType = OASObjectType.gpxTrack;
                sr.relatedObject = dataItem;
                publish = YES;
            }
        }
        else
        {
            sr.localeName = pd.name;
            sr.object = point;
            sr.objectType = OASObjectType.recentObj;
            sr.location = [[OASKLatLon alloc] initWithLatitude:point.latitude longitude:point.longitude];
            sr.preferredZoom = PREFERRED_DEFAULT_RECENT_ZOOM;
            publish = YES;
        }
        if (publish)
        {
            sr.priority = 154 + (p++);
            if ([phrase getFullSearchPhrase].length <= 1 && [phrase isNoSelectedType])
                [resultMatcher publishObj:sr];
            else if ([[phrase getFirstUnknownNameStringMatcher] matchesName:sr.localeName])
                [resultMatcher publishObj:sr];
        }
    }
    return YES;
}



@end

@implementation OASharedSearchIndexItemAPI

+ (OASObjectType *)searchType { return OASObjectType.indexItem; }

- (int32_t)getSearchPriorityP:(OASSearchPhrase *)phrase
{
    return [phrase isNoSelectedType] ? 150 : -1;
}

- (OAWorldRegion *)worldRegion
{
    return OsmAndApp.instance.worldRegion;
}

- (OARepositoryResourceItem *)uninstalledMapForRegion:(OAWorldRegion *)region
{
    NSArray *ids = [OAManageResourcesViewController getResourcesInRepositoryIdsByRegion:region];
    return [OAResourcesUIHelper uninstalledMapFromResourceIds:ids region:region];
}

- (void)searchRegion:(OAWorldRegion *)region phrase:(OASSearchPhrase *)phrase matcher:(OASSearchUICoreSearchResultMatcher *)matcher
{
    if (!region || [matcher isCancelled])
        return;
    NSString *name = [[region.allNames componentsJoinedByString:@" "] ?: region.name lowercaseString];
    if (region.superregion.superregion.resourceTypes
        && [region.resourceTypes containsObject:@((int) OsmAnd::ResourcesManager::ResourceType::MapRegion)]
        && [OASOsmandRegions.companion isRegionNameMatchedQuery:[phrase getFullSearchPhrase] regionName:name])
    {
        OARepositoryResourceItem *item = [self uninstalledMapForRegion:region];
        if (item && ![matcher isCancelled])
        {
            OASSearchResult *result = [[OASSearchResult alloc] initWithSp:phrase];
            result.objectType = OASObjectType.indexItem;
            result.localeName = item.title;
            result.relatedObject = item;
            result.priority = 149;
            [result setUnknownPhraseMatchWeightWeight:-1];
            result.preferredZoom = 17;
            [matcher publishObj:result];
        }
    }
    for (OAWorldRegion *child in region.subregions)
    {
        if ([matcher isCancelled])
            return;
        [self searchRegion:child phrase:phrase matcher:matcher];
    }
}

- (BOOL)searchPhrase:(OASSearchPhrase *)phrase resultMatcher:(OASSearchUICoreSearchResultMatcher *)matcher
{
    [self searchRegion:[self worldRegion] phrase:phrase matcher:matcher];
    return ![matcher isCancelled];
}

@end

@implementation OASharedSearchAppAPIs

+ (Class)sharedClassForAppClass:(Class)appClass
{
    NSDictionary<NSString *, Class> *classes = @{
        NSStringFromClass(OASearchFavoritesAPI.class): OASharedSearchFavoritesAPI.class,
        NSStringFromClass(OASearchFavoritesCategoryAPI.class): OASharedSearchFavoritesCategoryAPI.class,
        NSStringFromClass(OASearchWptAPI.class): OASharedSearchWptAPI.class,
        NSStringFromClass(OASearchHistoryAPI.class): OASharedSearchHistoryAPI.class,
        NSStringFromClass(OASearchGpxAPI.class): OASharedSearchGpxAPI.class,
        NSStringFromClass(SearchIndexItemAPI.class): OASharedSearchIndexItemAPI.class
    };
    return classes[NSStringFromClass(appClass)];
}

@end
