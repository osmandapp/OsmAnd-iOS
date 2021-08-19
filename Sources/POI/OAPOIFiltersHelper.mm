//
//  OAPOIFiltersHelper.m
//  OsmAnd
//
//  Created by Alexey Kulish on 21/12/2016.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OAPOIFiltersHelper.h"
#import "OAPOIUIFilter.h"
#import "OASearchByNameFilter.h"
#import "Localization.h"
#import "OAPOIHelper.h"
#import "OAUtilities.h"
#import "OAPOIBaseType.h"
#import "OAPOIType.h"
#import <sqlite3.h>
#import "OALog.h"
#import "OAAppSettings.h"
#import "OAAutoObserverProxy.h"
#import "OsmAndApp.h"
#import "OAApplicationMode.h"
#import "OAPlugin.h"

static NSString* const UDF_CAR_AID = @"car_aid";
static NSString* const UDF_FOR_TOURISTS = @"for_tourists";
static NSString* const UDF_FOOD_SHOP = @"food_shop";
static NSString* const UDF_FUEL = @"fuel";
static NSString* const UDF_SIGHTSEEING = @"sightseeing";
static NSString* const UDF_EMERGENCY = @"emergency";
static NSString* const UDF_PUBLIC_TRANSPORT = @"public_transport";
static NSString* const UDF_ACCOMMODATION = @"accommodation";
static NSString* const UDF_RESTAURANTS = @"restaurants";
static NSString* const UDF_PARKING = @"parking";

static const NSArray<NSString *> *DEL = @[UDF_CAR_AID, UDF_FOR_TOURISTS, UDF_FOOD_SHOP, UDF_FUEL, UDF_SIGHTSEEING, UDF_EMERGENCY,
                                         UDF_PUBLIC_TRANSPORT, UDF_ACCOMMODATION, UDF_RESTAURANTS, UDF_PARKING];


#define DATABASE_NAME @"poi_filters"
#define FILTER_NAME @"poi_filters"
#define FILTER_COL_NAME @"name"
#define FILTER_COL_ID @"id"
#define FILTER_COL_FILTERBYNAME @"filterbyname"
#define FILTER_TABLE_CREATE @"CREATE TABLE poi_filters (name, id, filterbyname);"

#define CATEGORIES_NAME @"categories"
#define CATEGORIES_FILTER_ID @"filter_id"
#define CATEGORIES_COL_CATEGORY @"category"
#define CATEGORIES_COL_SUBCATEGORY @"subcategory"
#define CATEGORIES_TABLE_CREATE @"CREATE TABLE categories (filter_id, category, subcategory);"

@interface OAPOIFilterDbHelper : NSObject

@end

@implementation OAPOIFilterDbHelper
{
    sqlite3 *filtersDB;
    NSString *databasePath;
    dispatch_queue_t dbQueue;
    dispatch_queue_t syncQueue;
    OAPOIHelper *_poiHelper;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        dbQueue = dispatch_queue_create("uifilters_dbQueue", DISPATCH_QUEUE_SERIAL);
        syncQueue = dispatch_queue_create("uifilters_syncQueue", DISPATCH_QUEUE_SERIAL);
        
        _poiHelper = [OAPOIHelper sharedInstance];
        
        [self createDb];
    }
    return self;
}

- (void)createDb
{
    NSString *dir = [NSHomeDirectory() stringByAppendingString:@"/Library/UIFilters"];
    databasePath = [dir stringByAppendingString:@"/uifilters.db"];
    
    BOOL isDir = YES;
    if (![[NSFileManager defaultManager] fileExistsAtPath:dir isDirectory:&isDir])
        [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    
    dispatch_sync(dbQueue, ^{
        
        NSFileManager *filemgr = [NSFileManager defaultManager];
        const char *dbpath = [databasePath UTF8String];
        
        if ([filemgr fileExistsAtPath: databasePath ] == NO)
        {
            if (sqlite3_open(dbpath, &filtersDB) == SQLITE_OK)
            {
                char *errMsg;
                const char *sql_stmt = [FILTER_TABLE_CREATE UTF8String];
                if (sqlite3_exec(filtersDB, sql_stmt, NULL, NULL, &errMsg) != SQLITE_OK)
                    OALog(@"Failed to create table: %@", [NSString stringWithCString:errMsg encoding:NSUTF8StringEncoding]);
                if (errMsg != NULL) sqlite3_free(errMsg);
                
                sql_stmt = [CATEGORIES_TABLE_CREATE UTF8String];
                if (sqlite3_exec(filtersDB, sql_stmt, NULL, NULL, &errMsg) != SQLITE_OK)
                    OALog(@"Failed to create table: %@", [NSString stringWithCString:errMsg encoding:NSUTF8StringEncoding]);
                if (errMsg != NULL) sqlite3_free(errMsg);
                
                sqlite3_close(filtersDB);
            }
            else
            {
                // Failed to open/create database
            }
        }
        else
        {
            // Upgrade if needed
        }
        
    });
    
}

- (BOOL) addFilter:(OAPOIUIFilter *)p addOnlyCategories:(BOOL)addOnlyCategories
{
    dispatch_async(dbQueue, ^{
        sqlite3_stmt    *statement;
        
        const char *dbpath = [databasePath UTF8String];
        
        if (sqlite3_open(dbpath, &filtersDB) == SQLITE_OK)
        {
            if (!addOnlyCategories)
            {
                NSString *query = [NSString stringWithFormat:@"INSERT INTO %@ (%@, %@, %@) VALUES (?, ?, ?)", FILTER_NAME, FILTER_COL_NAME, FILTER_COL_ID, FILTER_COL_FILTERBYNAME];
                const char *update_stmt = [query UTF8String];
                
                sqlite3_prepare_v2(filtersDB, update_stmt, -1, &statement, NULL);
                sqlite3_bind_text(statement, 1, [p.name UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(statement, 2, [p.filterId UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(statement, 3, [p.filterByName UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_step(statement);
                sqlite3_finalize(statement);
            }
            
            NSString *query = [NSString stringWithFormat:@"INSERT INTO %@ (%@, %@, %@) VALUES (?, ?, ?)", CATEGORIES_NAME, CATEGORIES_FILTER_ID, CATEGORIES_COL_CATEGORY, CATEGORIES_COL_SUBCATEGORY];
            const char *update_stmt = [query UTF8String];
            
            NSMapTable<OAPOICategory *, NSMutableSet<NSString *> *> *types = [p getAcceptedTypes];
            for (OAPOICategory *a in types.keyEnumerator)
            {
                if ([types objectForKey:a] == [OAPOIBaseType nullSet])
                {
                    sqlite3_prepare_v2(filtersDB, update_stmt, -1, &statement, NULL);
                    sqlite3_bind_text(statement, 1, [p.filterId UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(statement, 2, [a.name UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_null(statement, 3);
                    sqlite3_step(statement);
                    sqlite3_finalize(statement);
                }
                else
                {
                    for (NSString *s in [types objectForKey:a])
                    {
                        sqlite3_prepare_v2(filtersDB, update_stmt, -1, &statement, NULL);
                        sqlite3_bind_text(statement, 1, [p.filterId UTF8String], -1, SQLITE_TRANSIENT);
                        sqlite3_bind_text(statement, 2, [a.name UTF8String], -1, SQLITE_TRANSIENT);
                        sqlite3_bind_text(statement, 3, [s UTF8String], -1, SQLITE_TRANSIENT);
                        sqlite3_step(statement);
                        sqlite3_finalize(statement);
                    }
                }
            }
            
            sqlite3_close(filtersDB);
        }
    });
    return YES;
}
// TODO: Implement filters deletion later!
- (NSArray<OAPOIUIFilter *> *) getFilters:(BOOL)includeDeleted
{
    NSMutableArray<OAPOIUIFilter *> *list = [NSMutableArray array];
    
    dispatch_sync(dbQueue, ^{
        
        const char *dbpath = [databasePath UTF8String];
        sqlite3_stmt *statement;
        
        if (sqlite3_open(dbpath, &filtersDB) == SQLITE_OK)
        {
            NSString *querySQL = [NSString stringWithFormat:@"SELECT %@, %@, %@ FROM %@", CATEGORIES_FILTER_ID, CATEGORIES_COL_CATEGORY, CATEGORIES_COL_SUBCATEGORY, CATEGORIES_NAME];
            
            NSMapTable<NSString *, NSMapTable<OAPOICategory *, NSMutableSet<NSString *> *> *> *map = [NSMapTable strongToStrongObjectsMapTable];
            
            const char *query_stmt = [querySQL UTF8String];
            if (sqlite3_prepare_v2(filtersDB, query_stmt, -1, &statement, NULL) == SQLITE_OK)
            {
                while (sqlite3_step(statement) == SQLITE_ROW)
                {
                    NSString *filterId;
                    if (sqlite3_column_text(statement, 0) != nil)
                        filterId = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 0)];

                    NSString *category;
                    if (sqlite3_column_text(statement, 1) != nil)
                        category = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 1)];

                    NSString *subCategory;
                    if (sqlite3_column_text(statement, 2) != nil)
                        subCategory = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 2)];

                    if (![map objectForKey:filterId])
                        [map setObject:[NSMapTable strongToStrongObjectsMapTable] forKey:filterId];
                    
                    NSMapTable<OAPOICategory *, NSMutableSet<NSString *> *> *m = [map objectForKey:filterId];
                    OAPOICategory *a = [_poiHelper getPoiCategoryByName:[category lowerCase] create:NO];
                    if (!subCategory)
                    {
                        [m setObject:[OAPOIBaseType nullSet] forKey:a];
                    }
                    else
                    {
                        if (![m objectForKey:a])
                            [m setObject:[NSMutableSet set] forKey:a];
                        
                        [[m objectForKey:a] addObject:subCategory];
                    }

                }
                sqlite3_finalize(statement);
            }
            
            querySQL = [NSString stringWithFormat:@"SELECT %@, %@, %@ FROM %@", FILTER_COL_ID, FILTER_COL_NAME, FILTER_COL_FILTERBYNAME, FILTER_NAME];
            
            query_stmt = [querySQL UTF8String];
            if (sqlite3_prepare_v2(filtersDB, query_stmt, -1, &statement, NULL) == SQLITE_OK)
            {
                while (sqlite3_step(statement) == SQLITE_ROW)
                {
                    NSString *filterId;
                    if (sqlite3_column_text(statement, 0) != nil)
                        filterId = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 0)];
                    
                    NSString *name;
                    if (sqlite3_column_text(statement, 1) != nil)
                        name = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 1)];
                    
                    NSString *filterByName;
                    if (sqlite3_column_text(statement, 2) != nil)
                        filterByName = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 2)];
                    
                    if (![map objectForKey:filterId])
                        [map setObject:[NSMapTable strongToStrongObjectsMapTable] forKey:filterId];
                    
                    if ([map objectForKey:filterId])
                    {
                        OAPOIUIFilter *filter = [[OAPOIUIFilter alloc] initWithName:name filterId:filterId acceptedTypes:[map objectForKey:filterId]];
                        filter.savedFilterByName = filterByName;
                        [list addObject:filter];
                    }
                }
                sqlite3_finalize(statement);
            }
            
            sqlite3_close(filtersDB);
        }
    });
    
    return [NSArray arrayWithArray:list];
}

- (BOOL) editFilter:(OAPOIUIFilter *)filter
{
    dispatch_async(dbQueue, ^{
        sqlite3_stmt    *statement;
        
        const char *dbpath = [databasePath UTF8String];
        
        if (sqlite3_open(dbpath, &filtersDB) == SQLITE_OK)
        {
            NSString *query = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@=?", CATEGORIES_NAME, CATEGORIES_FILTER_ID];
            
            const char *update_stmt = [query UTF8String];
            
            sqlite3_prepare_v2(filtersDB, update_stmt, -1, &statement, NULL);
            sqlite3_bind_text(statement, 1, [filter.filterId UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_step(statement);
            sqlite3_finalize(statement);
            
            sqlite3_close(filtersDB);
        }
    });
    [self addFilter:filter addOnlyCategories:YES];
    [self updateName:filter];
    return YES;
}

- (void) updateName:(OAPOIUIFilter *)filter
{
    dispatch_async(dbQueue, ^{
        sqlite3_stmt    *statement;
        
        const char *dbpath = [databasePath UTF8String];
        
        if (sqlite3_open(dbpath, &filtersDB) == SQLITE_OK)
        {
            NSString *query = [NSString stringWithFormat:@"UPDATE %@ SET %@=?, %@=? WHERE %@=?", FILTER_NAME, FILTER_COL_FILTERBYNAME, FILTER_COL_NAME, FILTER_COL_ID];
            
            const char *update_stmt = [query UTF8String];
            
            sqlite3_prepare_v2(filtersDB, update_stmt, -1, &statement, NULL);
            sqlite3_bind_text(statement, 1, [filter.filterByName UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 2, [filter.name UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 3, [filter.filterId UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_step(statement);
            sqlite3_finalize(statement);
            
            sqlite3_close(filtersDB);
        }
    });
}

- (BOOL) deleteFilter:(NSString *)filterId
{
    dispatch_async(dbQueue, ^{
        sqlite3_stmt    *statement;
        
        const char *dbpath = [databasePath UTF8String];
        
        if (sqlite3_open(dbpath, &filtersDB) == SQLITE_OK)
        {
            NSString *query = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@=?", FILTER_NAME, FILTER_COL_ID];
            
            const char *update_stmt = [query UTF8String];
            
            sqlite3_prepare_v2(filtersDB, update_stmt, -1, &statement, NULL);
            sqlite3_bind_text(statement, 1, [filterId UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_step(statement);
            sqlite3_finalize(statement);
            
            query = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@=?", CATEGORIES_NAME, CATEGORIES_FILTER_ID];
            
            update_stmt = [query UTF8String];
            
            sqlite3_prepare_v2(filtersDB, update_stmt, -1, &statement, NULL);
            sqlite3_bind_text(statement, 1, [filterId UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_step(statement);
            sqlite3_finalize(statement);
            
            sqlite3_close(filtersDB);
        }
    });
    return YES;
}

@end


@implementation OAPOIFiltersHelper
{
    OAPOIUIFilter *_searchByNamePOIFilter;
    OAPOIUIFilter *_customPOIFilter;
    OAPOIUIFilter *_showAllPOIFilter;
    OAPOIUIFilter *_topWikiPoiFilter;
    NSMutableArray<OAPOIUIFilter *> *_cacheTopStandardFilters;
    NSMutableSet<OAPOIUIFilter *> *_selectedPoiFilters;

    OAPOIFilterDbHelper *_helper;
    OAPOIHelper *_poiHelper;
    
    OAAutoObserverProxy *_applicationModeObserver;
}

+ (OAPOIFiltersHelper *)sharedInstance
{
    static dispatch_once_t once;
    static OAPOIFiltersHelper * sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _cacheTopStandardFilters = nil;
        _selectedPoiFilters = [NSMutableSet set];
        _helper = [[OAPOIFilterDbHelper alloc] init];
        _poiHelper = [OAPOIHelper sharedInstance];
        
        _applicationModeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                             withHandler:@selector(onApplicationModeChanged)
                                                              andObserve:OsmAndApp.instance.data.applicationModeChangedObservable];
    }
    return self;
}

- (void) onApplicationModeChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self hidePoiFilters];
        [self loadSelectedPoiFilters];
    });
}

- (OAPOIUIFilter *) getSearchByNamePOIFilter
{
    if (!_searchByNamePOIFilter)
    {
        OAPOIUIFilter *filter = [[OASearchByNameFilter alloc] init];
        filter.isStandardFilter = YES;
        _searchByNamePOIFilter = filter;
    }
    return _searchByNamePOIFilter;
}

- (OAPOIUIFilter *) getCustomPOIFilter
{
    if (!_customPOIFilter)
    {
        OAPOIUIFilter *filter = [[OAPOIUIFilter alloc] initWithName:OALocalizedString(@"poi_filter_custom_filter") filterId:CUSTOM_FILTER_ID acceptedTypes:[NSMapTable strongToStrongObjectsMapTable]];
        filter.isStandardFilter = YES;
        _customPOIFilter = filter;
    }
    return _customPOIFilter;
}

- (OAPOIUIFilter *) getTopWikiPoiFilter
{
    if (_topWikiPoiFilter == nil)
    {
        NSString *wikiFilterId = [STD_PREFIX stringByAppendingString:OSM_WIKI_CATEGORY];
        for (OAPOIUIFilter *filter in [self getTopDefinedPoiFilters])
        {
            if ([wikiFilterId isEqualToString:filter.getFilterId])
            {
                _topWikiPoiFilter = filter;
                break;
            }
        }
    }
    return _topWikiPoiFilter;
}

- (OAPOIUIFilter *) getShowAllPOIFilter
{
    if (!_showAllPOIFilter)
    {
        OAPOIUIFilter *filter = [[OAPOIUIFilter alloc] initWithBasePoiType:nil idSuffix:@""];
        filter.isStandardFilter = YES;
        _showAllPOIFilter = filter;
    }
    return _showAllPOIFilter;
}

- (void) hidePoiFilters
{
    [_selectedPoiFilters removeAllObjects];
}

- (OAPOIUIFilter *) getFilterById:(NSString *)filterId filters:(NSArray<OAPOIUIFilter *> *)filters
{
    if (!filterId)
        return nil;

    for (OAPOIUIFilter *pf in filters)
    {
        if (pf && pf.filterId && [pf.filterId isEqualToString:filterId])
            return pf;
    }
    return nil;
}

- (OAPOIUIFilter *) getFilterById:(NSString *)filterId
{
    return [self getFilterById:filterId includeDeleted:NO];
}

- (OAPOIUIFilter *) getFilterById:(NSString *)filterId includeDeleted:(BOOL)includeDeleted
{
    if (!filterId)
        return nil;

    for (OAPOIUIFilter *f in [self getTopDefinedPoiFilters:includeDeleted])
    {
        if ([f.filterId isEqualToString:filterId])
            return f;
    }
    OAPOIUIFilter *ff = [self getFilterById:filterId filters:@[[self getCustomPOIFilter], [self getSearchByNamePOIFilter],
                                                               [self getTopWikiPoiFilter], [self getShowAllPOIFilter]]];
    if (ff)
        return ff;

    if ([filterId hasPrefix:STD_PREFIX])
    {
        NSString *typeId = [filterId substringFromIndex:STD_PREFIX.length];
        OAPOIBaseType *tp = [_poiHelper getAnyPoiTypeByName:typeId];
        if (tp)
        {
            OAPOIUIFilter *lf = [[OAPOIUIFilter alloc] initWithBasePoiType:tp idSuffix:@""];;
            NSMutableArray<OAPOIUIFilter *> *copy = _cacheTopStandardFilters ? [NSMutableArray arrayWithArray:_cacheTopStandardFilters] : [NSMutableArray new];
            [copy addObject:lf];
            [copy sortUsingComparator:[OAPOIUIFilter getComparator]];
            _cacheTopStandardFilters = copy;
            return lf;
        }
        OAPOIBaseType *lt = [_poiHelper getAnyPoiAdditionalTypeByKey:typeId];
        if (lt)
        {
            OAPOIUIFilter *lf = [[OAPOIUIFilter alloc] initWithBasePoiType:lt idSuffix:@""];;
            NSMutableArray<OAPOIUIFilter *> *copy = _cacheTopStandardFilters ? [NSMutableArray arrayWithArray:_cacheTopStandardFilters] : [NSMutableArray new];
            [copy addObject:lf];
            [copy sortUsingComparator:[OAPOIUIFilter getComparator]];
            _cacheTopStandardFilters = copy;
            return lf;
        }
    }
    return nil;
}

- (void) reloadAllPoiFilters
{
    _showAllPOIFilter = nil;
    [self getShowAllPOIFilter];
    _cacheTopStandardFilters = nil;
    [self getTopDefinedPoiFilters];
}

- (NSArray<OAPOIUIFilter *> *) getUserDefinedPoiFilters:(BOOL)includeDeleted
{
    NSMutableArray<OAPOIUIFilter *> *userDefinedFilters = [NSMutableArray new];
    if (_helper != nil)
    {
        NSArray<OAPOIUIFilter *> *userDefined = [_helper getFilters:includeDeleted];
        [userDefinedFilters addObjectsFromArray:userDefined];
    }
    return userDefinedFilters;
}

- (NSArray<OAPOIUIFilter *> *) getSearchPoiFilters
{
    NSMutableArray<OAPOIUIFilter *> *result = [NSMutableArray array];
    NSArray<OAPOIUIFilter *> *filters = @[[self getCustomPOIFilter], /*getShowAllPOIFilter(),*/ [self getSearchByNamePOIFilter]];
    for (OAPOIUIFilter *f : filters)
    {
        if (f && ![f isEmpty])
            [result addObject:f];
    }
    return result;
}

- (NSArray<OAPOIUIFilter *> *) getTopDefinedPoiFilters
{
    return [self getTopDefinedPoiFilters:NO];
}

- (NSArray<OAPOIUIFilter *> *) getTopDefinedPoiFilters:(BOOL)includeDeleted
{
    NSMutableArray<OAPOIUIFilter *> *top = _cacheTopStandardFilters;
    if (!top)
    {
        top = [NSMutableArray new];
        // user defined
        [top addObjectsFromArray:[self getUserDefinedPoiFilters:YES]];
        // default
        for (OAPOIBaseType *t in [_poiHelper getTopVisibleFilters])
        {
            OAPOIUIFilter *f = [[OAPOIUIFilter alloc] initWithBasePoiType:t idSuffix:@""];
            [top addObject:f];
        }
        [OAPlugin registerCustomPoiFilters:top];
        [top sortUsingComparator:[OAPOIUIFilter getComparator]];
        _cacheTopStandardFilters = top;
    }
    NSMutableArray<OAPOIUIFilter *> *result = [NSMutableArray array];
    for (OAPOIUIFilter *filter in top)
    {
        if (includeDeleted || !filter.isDeleted)
            [result addObject:filter];
    }
    [result addObject:[self getShowAllPOIFilter]];
    return result;
}

- (NSArray<NSString *> *) getPoiFilterOrders:(BOOL)onlyActive
{
    NSMutableArray<NSString *> *filterOrders = [NSMutableArray new];
    for (OAPOIUIFilter *filter in [self getSortedPoiFilters:onlyActive])
         [filterOrders addObject:filter.getFilterId];
    return filterOrders;
}

- (NSArray<OAPOIUIFilter *> *) getSortedPoiFilters:(BOOL) onlyActive
{
    OAApplicationMode *selectedAppMode = OAAppSettings.sharedManager.applicationMode.get;
    return [self getSortedPoiFilters:selectedAppMode onlyActive:onlyActive];
}

- (NSArray<OAPOIUIFilter *> *) getSortedPoiFilters:(OAApplicationMode *)appMode onlyActive:(BOOL)onlyActive
{
    [self initPoiUIFiltersState:appMode];
    NSMutableArray<OAPOIUIFilter *> *allFilters = [NSMutableArray new];
    [allFilters addObjectsFromArray:[self getTopDefinedPoiFilters]];
    [allFilters addObjectsFromArray:[self getSearchPoiFilters]];
    [allFilters sortUsingComparator:[OAPOIUIFilter getComparator]];
    if (onlyActive)
    {
        NSMutableArray<OAPOIUIFilter *> *onlyActiveFilters = [NSMutableArray new];
        for (OAPOIUIFilter *f in allFilters)
        {
            if (f.isActive)
            {
                [onlyActiveFilters addObject:f];
            }
        }
        return onlyActiveFilters;
    }
    return allFilters;
}

- (void) initPoiUIFiltersState:(OAApplicationMode *) appMode
{
    NSMutableArray<OAPOIUIFilter *> *allFilters = [NSMutableArray new];
    [allFilters addObjectsFromArray:[self getTopDefinedPoiFilters]];
    [allFilters addObjectsFromArray:[self getSearchPoiFilters]];

    [self refreshPoiFiltersActivation:appMode filters:allFilters];
    [self refreshPoiFiltersOrder:appMode filters:allFilters];
    
    //set up the biggest order to custom filter
    OAPOIUIFilter *customFilter = [self getCustomPOIFilter];
    customFilter.isActive = YES;
    customFilter.order = (int) allFilters.count;
}

- (void) refreshPoiFiltersOrder:(OAApplicationMode *)appMode
                        filters:(NSArray<OAPOIUIFilter *> *)filters
{
    NSDictionary<NSString *, NSNumber *> *orders = [self getPoiFiltersOrder:appMode];
    NSMutableArray<OAPOIUIFilter *> *existedFilters = [NSMutableArray new];
    NSMutableArray<OAPOIUIFilter *> *newFilters = [NSMutableArray new];
    if (orders != nil)
    {
        //set up orders from settings
        for (OAPOIUIFilter *filter in filters)
        {
            NSNumber *order = orders[filter.getFilterId];
            if (order != nil) {
                filter.order = order.intValue;
                [existedFilters addObject:filter];
            }
            else
            {
                [newFilters addObject:filter];
            }
        }
        //make order values without spaces
        [existedFilters sortUsingComparator:[OAPOIUIFilter getComparator]];
        for (int i = 0; i < existedFilters.count; i++)
        {
            existedFilters[i].order = i;
        }
        //set up maximum orders for new poi filters
        [newFilters sortUsingComparator:[OAPOIUIFilter getComparator]];
        for (OAPOIUIFilter *filter in newFilters)
        {
            filter.order = (int) existedFilters.count;
            [existedFilters addObject:filter];
        }
    }
    else
    {
        for (OAPOIUIFilter *filter in filters)
        {
            filter.order = INVALID_ORDER;
        }
    }
}

- (void) refreshPoiFiltersActivation:(OAApplicationMode *)appMode
                                         filters:(NSArray<OAPOIUIFilter *> *)filters
{
    NSArray<NSString *> *inactiveFiltersIds = [self getInactivePoiFiltersIds:appMode];
    if (inactiveFiltersIds != nil)
    {
        for (OAPOIUIFilter *filter in filters)
        {
            filter.isActive = ![inactiveFiltersIds containsObject:filter.getFilterId];
        }
    } else {
        for (OAPOIUIFilter *filter in filters)
        {
            filter.isActive = YES;
        }
    }
}

- (void) saveFiltersOrder:(OAApplicationMode *)appMode filterIds:(NSArray<NSString *> *)filterIds
{
    [OAAppSettings.sharedManager.poiFiltersOrder set:filterIds mode:appMode];
}

- (void) saveInactiveFilters:(OAApplicationMode *)appMode filterIds:(NSArray<NSString *> *) filterIds
{
    [OAAppSettings.sharedManager.inactivePoiFilters set:filterIds mode:appMode];
}

- (NSDictionary<NSString *, NSNumber *> *) getPoiFiltersOrder:(OAApplicationMode *)appMode
{
    NSArray<NSString *> *ids = [OAAppSettings.sharedManager.poiFiltersOrder get:appMode];
    if (ids == nil)
        return nil;
    
    NSMutableDictionary<NSString *, NSNumber *> *result = [NSMutableDictionary new];
    for (int i = 0; i < ids.count; i++)
    {
        result[ids[i]] = @(i);
    }
    return result;
}

- (NSArray<NSString *> *) getInactivePoiFiltersIds:(OAApplicationMode *)appMode
{
    return [OAAppSettings.sharedManager.inactivePoiFilters get:appMode];
}

- (BOOL) removePoiFilter:(OAPOIUIFilter *)filter
{
    if ([filter.filterId isEqualToString:CUSTOM_FILTER_ID] ||
        [filter.filterId isEqualToString:BY_NAME_FILTER_ID] ||
        [filter.filterId hasPrefix:STD_PREFIX])
    {
        return NO;
    }
    
    BOOL res = [_helper deleteFilter:filter.filterId];
    if (res)
    {
        NSMutableArray<OAPOIUIFilter *> *copy = [NSMutableArray arrayWithArray:_cacheTopStandardFilters];
        [copy removeObject:filter];
        _cacheTopStandardFilters = copy;
    }
    return res;
}

- (BOOL) createPoiFilter:(OAPOIUIFilter *)filter
{
    BOOL res = [_helper deleteFilter:filter.filterId];
    NSMutableArray<OAPOIUIFilter *> *filtersToRemove = [NSMutableArray array];
    for (OAPOIUIFilter *f in _cacheTopStandardFilters)
    {
        if ([f.filterId isEqualToString:filter.filterId])
            [filtersToRemove addObject:f];
    }
    [_cacheTopStandardFilters removeObjectsInArray:filtersToRemove];
    
    res = [_helper addFilter:filter addOnlyCategories:NO];
    if (res)
    {
        NSMutableArray<OAPOIUIFilter *> *copy = [NSMutableArray arrayWithArray:_cacheTopStandardFilters];
        [copy addObject:filter];
        [copy sortUsingComparator:[OAPOIUIFilter getComparator]];
        _cacheTopStandardFilters = copy;
    }
    return res;
}

- (BOOL) editPoiFilter:(OAPOIUIFilter *)filter
{
    if ([filter.filterId isEqualToString:CUSTOM_FILTER_ID] ||
        [filter.filterId isEqualToString:BY_NAME_FILTER_ID] ||
        [filter.filterId hasPrefix:STD_PREFIX])
    {
        return NO;
    }

    return [_helper editFilter:filter];
}

- (NSSet<OAPOIUIFilter *> *) getSelectedPoiFilters
{
    return [NSSet setWithSet:_selectedPoiFilters];
}

- (void) addSelectedPoiFilter:(OAPOIUIFilter *)filter
{
    [_selectedPoiFilters addObject:filter];
    [OAPlugin onPrepareExtraTopPoiFilters:_selectedPoiFilters];
    [self saveSelectedPoiFilters];
}

- (void) removeSelectedPoiFilter:(OAPOIUIFilter *)filter
{
    [_selectedPoiFilters removeObject:filter];
    [self saveSelectedPoiFilters];
}

- (BOOL) isShowingAnyPoi
{
    return _selectedPoiFilters.count > 0;
}

- (void) clearSelectedPoiFilters
{
    [_selectedPoiFilters removeAllObjects];
    [self saveSelectedPoiFilters];
}

- (void)clearSelectedPoiFilters:(NSArray<OAPOIUIFilter *> *)filtersToExclude
{
    NSMutableSet<OAPOIUIFilter *> *selectedPoiFilters = [NSMutableSet setWithSet:_selectedPoiFilters];
    if (filtersToExclude && filtersToExclude.count > 0)
    {
        NSMutableArray *filtersToRemove = [NSMutableArray new];
        for (OAPOIUIFilter *selectedFilter in selectedPoiFilters)
        {
            BOOL skip = NO;
            for (OAPOIUIFilter *filterToExclude in filtersToExclude)
            {
                NSString *filterToExcludeId = filterToExclude.filterId;
                if (filterToExcludeId && [filterToExcludeId isEqualToString:selectedFilter.filterId])
                {
                    skip = YES;
                    break;
                }
            }
            if (!skip)
                [filtersToRemove addObject:selectedFilter];
        }
        if (filtersToRemove.count > 0)
        {
            for (OAPOIUIFilter *filterToRemove in filtersToRemove)
            {
                [selectedPoiFilters removeObject:filterToRemove];
            }
        }
    }
    else
    {
        [selectedPoiFilters removeAllObjects];
    }
    [self saveSelectedPoiFilters:selectedPoiFilters];
    [_selectedPoiFilters setSet:selectedPoiFilters];
}

- (NSString *) getFiltersName:(NSSet<OAPOIUIFilter *> *)filters
{
    if (filters.count == 0)
    {
        return OALocalizedString(@"map_settings_none");
    }
    else
    {
        NSMutableString *names = [NSMutableString string];
        for (OAPOIUIFilter *filter in filters)
        {
            if (names.length > 0)
                [names appendString:@", "];
            
            [names appendString:filter.name];
        }
        return [NSString stringWithString:names];
    }
}

- (OAPOIUIFilter *) combineSelectedFilters:(NSSet<OAPOIUIFilter *> *)selectedFilters
{
    if ([selectedFilters count] == 0) {
        return nil;
    }
    OAPOIUIFilter *result = nil;
    for (OAPOIUIFilter *filter in selectedFilters) {
        if (result == nil) {
            result = [[OAPOIUIFilter alloc] initWithFiltersToMerge:[[NSSet alloc] initWithObjects:filter, nil]];
        } else {
            [result combineWithPoiFilter:filter];
        }
        if (!result.filterByName && filter.filterByName)
            result.filterByName = filter.filterByName;
    }
    return result;
}

- (NSString *) getSelectedPoiFiltersName
{
    return [self getFiltersName:_selectedPoiFilters];
}

- (BOOL) isPoiFilterSelected:(OAPOIUIFilter *)filter
{
    return [_selectedPoiFilters containsObject:filter];
}

- (BOOL)isTopWikiFilterSelected
{
    NSString *wikiFilterId = [[self getTopWikiPoiFilter] getFilterId];
    for (OAPOIUIFilter *filter in _selectedPoiFilters)
    {
        if ([wikiFilterId isEqualToString:[filter getFilterId]])
            return YES;
    }
    return NO;
}

- (BOOL) isPoiFilterSelectedByFilterId:(NSString *)filterId
{
    for (OAPOIUIFilter *filter in _selectedPoiFilters)
    {
        if ([filter.filterId isEqualToString:filterId])
            return YES;
    }
    return NO;
}

- (void) loadSelectedPoiFilters
{
    NSString *storedString = [[OAAppSettings sharedManager].selectedPoiFilters get];
    if (storedString.length > 0)
    {
        NSArray<NSString *> *filters = [storedString componentsSeparatedByString:@","];
        for (NSString *f in filters)
        {
            OAPOIUIFilter *filter = [self getFilterById:f];
            if (filter)
                [_selectedPoiFilters addObject:filter];
        }
        [OAPlugin onPrepareExtraTopPoiFilters:_selectedPoiFilters];
    }
}

- (void) saveSelectedPoiFilters
{
    NSMutableString *filtersStr = [NSMutableString new];
    NSArray<OAPOIUIFilter *> *filters = _selectedPoiFilters.allObjects;
    for (NSInteger i = 0; i < filters.count; i++)
    {
        OAPOIUIFilter *f = filters[i];
        [filtersStr appendString:f.filterId];
        if (i != filters.count - 1)
            [filtersStr appendString:@","];
    }
    [[OAAppSettings sharedManager].selectedPoiFilters set:filtersStr];
}

- (void)saveSelectedPoiFilters:(NSSet<OAPOIUIFilter *> *)selectedPoiFilters
{
    NSMutableSet<NSString *> *filters = [NSMutableSet new];
    for (OAPOIUIFilter *filter in selectedPoiFilters)
    {
        [filters addObject:filter.filterId];
    }
    [[[OAAppSettings sharedManager] selectedPoiFilters] set:[filters.allObjects componentsJoinedByString:@","]];
}

@end

