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
            
            NSDictionary<OAPOICategory *, NSSet<NSString *> *> *types = [p getAcceptedTypes];
            for (OAPOICategory *a in types.allKeys)
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

- (NSArray<OAPOIUIFilter *> *) getFilters
{
    NSMutableArray<OAPOIUIFilter *> *list = [NSMutableArray array];
    
    dispatch_sync(dbQueue, ^{
        
        const char *dbpath = [databasePath UTF8String];
        sqlite3_stmt *statement;
        
        if (sqlite3_open(dbpath, &filtersDB) == SQLITE_OK)
        {
            NSString *querySQL = [NSString stringWithFormat:@"SELECT %@, %@, %@ FROM %@", CATEGORIES_FILTER_ID, CATEGORIES_COL_CATEGORY, CATEGORIES_COL_SUBCATEGORY, CATEGORIES_NAME];
            
            NSMutableDictionary<NSString *, NSMutableDictionary<OAPOICategory *, NSMutableSet<NSString *> *> *> *map = [NSMutableDictionary dictionary];
            
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
                        [map setObject:[NSMutableDictionary dictionary] forKey:filterId];
                    
                    NSMutableDictionary<OAPOICategory *, NSMutableSet<NSString *> *> *m = [map objectForKey:filterId];
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
                        [map setObject:[NSMutableDictionary dictionary] forKey:filterId];
                    
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
    OAPOIUIFilter *_localWikiPoiFilter;
    NSMutableArray<OAPOIUIFilter *> *_cacheTopStandardFilters;
    NSMutableSet<OAPOIUIFilter *> *_selectedPoiFilters;
    
    OAPOIFilterDbHelper *_helper;
    OAPOIHelper *_poiHelper;
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
        _cacheTopStandardFilters = [NSMutableArray array];
        _selectedPoiFilters = [NSMutableSet set];
        _helper = [[OAPOIFilterDbHelper alloc] init];
        _poiHelper = [OAPOIHelper sharedInstance];
    }
    return self;
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
        OAPOIUIFilter *filter = [[OAPOIUIFilter alloc] initWithName:OALocalizedString(@"poi_filter_custom_filter") filterId:CUSTOM_FILTER_ID acceptedTypes:[NSDictionary dictionary]];
        filter.isStandardFilter = YES;
        _customPOIFilter = filter;
    }
    return _customPOIFilter;
}

- (OAPOIUIFilter *) getLocalWikiPOIFilter
{
    if (!_localWikiPoiFilter)
    {
        OAPOIType *place = [_poiHelper getPoiTypeByName:@"wiki_place"];
        if (place)
        {
            OAPOIUIFilter *filter = [[OAPOIUIFilter alloc] initWithBasePoiType:place idSuffix:[@" " stringByAppendingString:[OAUtilities translatedLangName:[OAUtilities currentLang]]]];
            filter.savedFilterByName = [@"wiki:lang:" stringByAppendingString:[OAUtilities currentLang]];
            filter.isStandardFilter = YES;
            _localWikiPoiFilter = filter;
        }
    }
    return _localWikiPoiFilter;
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


- (OAPOIUIFilter *) getFilterById:(NSString *)filterId filters:(NSArray<OAPOIUIFilter *> *)filters
{
    for (OAPOIUIFilter *pf in filters)
    {
        if ([pf.filterId isEqualToString:filterId])
            return pf;
    }
    return nil;
}

- (OAPOIUIFilter *) getFilterById:(NSString *)filterId
{
    if (!filterId)
        return nil;

    for (OAPOIUIFilter *f in [self getTopDefinedPoiFilters])
    {
        if ([f.filterId isEqualToString:filterId])
            return f;
    }
    OAPOIUIFilter *ff = [self getFilterById:filterId filters:@[[self getCustomPOIFilter], [self getSearchByNamePOIFilter],
                                                               [self getLocalWikiPOIFilter], [self getShowAllPOIFilter]]];
    if (!ff)
        return ff;

    if ([filterId hasPrefix:STD_PREFIX])
    {
        NSString *typeId = [filterId substringFromIndex:STD_PREFIX.length];
        OAPOIBaseType *tp = [_poiHelper getAnyPoiTypeByName:typeId];
        if (tp)
        {
            OAPOIUIFilter *lf = [[OAPOIUIFilter alloc] initWithBasePoiType:tp idSuffix:@""];;
            NSMutableArray<OAPOIUIFilter *> *copy = [NSMutableArray arrayWithArray:_cacheTopStandardFilters];
            [copy addObject:lf];
            [copy sortUsingComparator:[OAPOIUIFilter getComparator]];
            _cacheTopStandardFilters = copy;
            return lf;
        }
        OAPOIBaseType *lt = [_poiHelper getAnyPoiAdditionalTypeByKey:typeId];
        if (lt)
        {
            OAPOIUIFilter *lf = [[OAPOIUIFilter alloc] initWithBasePoiType:lt idSuffix:@""];;
            NSMutableArray<OAPOIUIFilter *> *copy = [NSMutableArray arrayWithArray:_cacheTopStandardFilters];
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

- (NSArray<OAPOIUIFilter *> *) getUserDefinedPoiFilters
{
    NSMutableArray<OAPOIUIFilter *> *userDefinedFilters = [NSMutableArray array];
    NSArray<OAPOIUIFilter *> *userDefined = [_helper getFilters];
    [userDefinedFilters addObjectsFromArray:userDefined];
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
    if (!_cacheTopStandardFilters)
    {
        NSMutableArray<OAPOIUIFilter *> *top = [NSMutableArray array];
        // user defined
        [top addObjectsFromArray:[self getUserDefinedPoiFilters]];
        if ([self getLocalWikiPOIFilter])
            [top addObject:[self getLocalWikiPOIFilter]];

        // default
        for (OAPOIBaseType *t in [_poiHelper getTopVisibleFilters])
        {
            OAPOIUIFilter *f = [[OAPOIUIFilter alloc] initWithBasePoiType:t idSuffix:@""];
            [top addObject:f];
        }
        [top sortUsingComparator:[OAPOIUIFilter getComparator]];
        _cacheTopStandardFilters = top;
    }
    NSMutableArray<OAPOIUIFilter *> *result = [NSMutableArray array];
    [result addObjectsFromArray:_cacheTopStandardFilters];
    [result addObject:[self getShowAllPOIFilter]];
    return result;
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

- (NSString *) getSelectedPoiFiltersName
{
    return [self getFiltersName:_selectedPoiFilters];
}

- (BOOL) isPoiFilterSelected:(OAPOIUIFilter *)filter
{
    return [_selectedPoiFilters containsObject:filter];
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
    NSArray<NSString *> *filters = [OAAppSettings sharedManager].selectedPoiFilters;
    for (NSString *f in filters)
    {
        OAPOIUIFilter *filter = [self getFilterById:f];
        if (filter)
            [_selectedPoiFilters addObject:filter];
    }
}

- (void) saveSelectedPoiFilters
{
    NSMutableArray<NSString *> *filters = [NSMutableArray array];
    for (OAPOIUIFilter *f in _selectedPoiFilters)
    {
        [filters addObject:f.filterId];
    }
    [[OAAppSettings sharedManager] setSelectedPoiFilters:filters];
}

@end

