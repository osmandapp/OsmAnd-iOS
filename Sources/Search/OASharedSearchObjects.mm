//
//  OASharedSearchObjects.mm
//  OsmAnd
//
//  Copyright © 2026 OsmAnd. All rights reserved.
//

#import "OASharedSearchObjects.h"
#import "OACity.h"
#import "OAStreet.h"
#import "OABuilding.h"
#import "OAAmenitySearcher.h"
#import "OAPOIHelper.h"
#import "OAPOIType.h"
#import "OAPOICategory.h"
#import "OAPOIFilter.h"
#import "OATopIndexFilter.h"
#import "OAAddress.h"
#import "OAPOI.h"
#import "OACustomSearchPoiFilter.h"
#import "OAResultMatcher.h"
#import "OsmAndSharedWrapper.h"

#import <CoreLocation/CoreLocation.h>
#import <objc/runtime.h>

@interface OASharedBlockResultMatcher () <OASResultMatcher>

@property (nonatomic, copy) BOOL (^publish)(id object);
@property (nonatomic, copy) BOOL (^cancelled)(void);

@end

@implementation OASharedBlockResultMatcher

+ (id<OASResultMatcher>)matcherWithPublish:(BOOL (^)(id))publish cancelled:(BOOL (^)(void))cancelled
{
    OASharedBlockResultMatcher *matcher = [[self alloc] init];
    matcher.publish = publish;
    matcher.cancelled = cancelled;
    return matcher;
}

- (BOOL)publishObj:(id)obj
{
    return self.publish(obj);
}

- (BOOL)isCancelled
{
    return self.cancelled();
}

@end

/**
 A poi filter of the app as the shared search calls it: the categories and types it accepts, and the
 matcher it puts around the one of the search, which takes the app's pois, and the types it accepts, by
 which the shared search looks its pois up in the name index.
 */
@interface OASharedPoiFilter : NSObject <OASCustomSearchPoiFilter>

@property (nonatomic, readonly) OACustomSearchPoiFilter *filter;

- (instancetype)initWithFilter:(OACustomSearchPoiFilter *)filter;

@end

@implementation OASharedPoiFilter
{
    NSMutableDictionary<NSString *, OAPOICategory *> *_categories;
}

- (instancetype)initWithFilter:(OACustomSearchPoiFilter *)filter
{
    self = [super init];
    if (self)
    {
        _filter = filter;
        _categories = [NSMutableDictionary dictionary];
    }
    return self;
}

- (BOOL)acceptType:(OASPoiCategory *)type subcategory:(NSString *)subcategory
{
    OAPOICategory *category = nil;
    if (type)
    {
        NSString *key = [type getKeyName];
        @synchronized (_categories)
        {
            category = _categories[key];
            if (!category)
            {
                category = [OAPOIHelper.sharedInstance getPoiCategoryByName:key];
                if (category)
                    _categories[key] = category;
            }
        }
    }
    return [_filter accept:category subcategory:subcategory];
}

- (BOOL)isEmpty
{
    return [_filter isEmpty];
}

// a whole category is NSNull, null to the shared search; the subtypes are a set of Kotlin's own,
// which the shared search takes for its LinkedHashSet
- (NSDictionary<OASPoiCategory *, id> *)getAcceptedTypes
{
    NSMapTable<OAPOICategory *, NSMutableSet<NSString *> *> *types = [_filter getAcceptedTypes];
    if (!types)
        return nil;

    OASMapPoiTypes *poiTypes = OAPOIHelper.sharedInstance.kPoiTypes;
    NSMutableDictionary<OASPoiCategory *, id> *acceptedTypes = [NSMutableDictionary dictionary];
    for (OAPOICategory *category in types)
    {
        OASPoiCategory *sharedCategory = [poiTypes getPoiCategoryByNameName:category.name];
        if (!sharedCategory)
            continue;
        NSMutableSet<NSString *> *subtypes = [types objectForKey:category];
        if ([OAPOIBaseType isNullSet:subtypes])
        {
            acceptedTypes[sharedCategory] = NSNull.null;
            continue;
        }
        OASMutableSet<NSString *> *sharedSubtypes = [[OASMutableSet alloc] init];
        for (NSString *subtype in subtypes)
            [sharedSubtypes addObject:subtype];
        acceptedTypes[sharedCategory] = sharedSubtypes;
    }
    return acceptedTypes;
}

- (OASSearchSettingsSortType *)getDefaultSearchType
{
    switch ([_filter getDefaultSearchType])
    {
        case OASearchSortTypeByRelevance:
            return OASSearchSettingsSortType.byRelevance;
        case OASearchSortTypeOnlyByDistance:
            return OASSearchSettingsSortType.onlyByDistance;
        case OASearchSortTypeIgnoreDistance:
            return OASSearchSettingsSortType.ignoreDistance;
        default:
            return nil;
    }
}

- (NSString *)getFilterId
{
    return [_filter getFilterId];
}

- (id)getIconResource
{
    return [_filter getIconResource];
}

- (NSString *)getName
{
    return [_filter getName];
}

// the filter takes the app's pois: each amenity goes through it as one, and on as itself
- (id<OASResultMatcher>)wrapResultMatcherMatcher:(id<OASResultMatcher>)matcher
{
    __block id current = nil;
    OAResultMatcher<OAPOI *> *inner = [[OAResultMatcher alloc] initWithPublishFunc:^BOOL(OAPOI *__autoreleasing *poi) {
        return [matcher publishObj:current];
    } cancelledFunc:^BOOL{
        return [matcher isCancelled];
    }];
    OAResultMatcher<OAPOI *> *wrapped = [_filter wrapResultMatcher:inner];
    if (!wrapped || wrapped == inner)
        return matcher;

    return [OASharedBlockResultMatcher matcherWithPublish:^BOOL(id object) {
        OAPOI *poi = [OASharedSearchObjects appObjectFor:object];
        if (![poi isKindOfClass:OAPOI.class])
            return NO;
        current = object;
        return [wrapped publish:poi];
    } cancelled:^BOOL{
        return [wrapped isCancelled];
    }];
}

@end

@implementation OASharedSearchObjects

+ (nullable id)appObjectFor:(nullable id)sharedObject
{
    if ([sharedObject isKindOfClass:OASCity.class])
        return [[OACity alloc] initWithSharedCity:sharedObject];
    if ([sharedObject isKindOfClass:OASStreet.class])
        return [[OAStreet alloc] initWithSharedStreet:sharedObject];
    if ([sharedObject isKindOfClass:OASBuilding.class])
        return [[OABuilding alloc] initWithSharedBuilding:sharedObject];
    if ([sharedObject isKindOfClass:OASAmenity.class])
        return [OAAmenitySearcher parsePOIBySharedAmenity:sharedObject];
    if ([sharedObject isKindOfClass:OASAbstractPoiType.class])
        return [self poiType:sharedObject];
    if ([sharedObject isKindOfClass:OASTopIndexFilter.class])
    {
        OASTopIndexFilter *filter = sharedObject;
        NSString *poiSubType = [OASMapPoiTypes.companion.TOP_INDEX_ADDITIONAL_PREFIX stringByAppendingString:[filter getTag]];
        return [[OATopIndexFilter alloc] initWithPoiSubType:poiSubType value:[filter getValue]];
    }
    if ([sharedObject isKindOfClass:OASKLatLon.class])
    {
        OASKLatLon *latLon = sharedObject;
        return [[CLLocation alloc] initWithLatitude:latLon.latitude longitude:latLon.longitude];
    }
    if ([sharedObject isKindOfClass:OASharedPoiFilter.class])
        return ((OASharedPoiFilter *) sharedObject).filter;
    return sharedObject;
}

+ (nullable id)sharedObjectFor:(nullable id)appObject
{
    if ([appObject isKindOfClass:OAAddress.class] && ((OAAddress *) appObject).sharedAddress)
        return ((OAAddress *) appObject).sharedAddress;
    if ([appObject isKindOfClass:OACustomSearchPoiFilter.class])
        return [self sharedPoiFilterFor:appObject];
    if ([appObject isKindOfClass:OAPOIBaseType.class])
        return [self sharedPoiType:appObject];
    if ([appObject isKindOfClass:OATopIndexFilter.class])
        return nil;
    if ([appObject isKindOfClass:CLLocation.class])
    {
        CLLocationCoordinate2D coordinate = ((CLLocation *) appObject).coordinate;
        return [[OASKLatLon alloc] initWithLatitude:coordinate.latitude longitude:coordinate.longitude];
    }
    return appObject;
}

+ (id<OASCustomSearchPoiFilter>)sharedPoiFilterFor:(OACustomSearchPoiFilter *)filter
{
    static char key;
    @synchronized (filter)
    {
        OASharedPoiFilter *shared = objc_getAssociatedObject(filter, &key);
        if (!shared)
        {
            shared = [[OASharedPoiFilter alloc] initWithFilter:filter];
            objc_setAssociatedObject(filter, &key, shared, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        return shared;
    }
}

// the shared poi type of the same key: a category, a filter of one, an additional type or a type
+ (nullable OASAbstractPoiType *)sharedPoiType:(OAPOIBaseType *)type
{
    OASMapPoiTypes *types = OAPOIHelper.sharedInstance.kPoiTypes;
    if ([type isKindOfClass:OAPOICategory.class])
        return [types getPoiCategoryByNameName:type.name];
    if ([type isKindOfClass:OAPOIFilter.class])
    {
        for (OASPoiCategory *category in [types getCategoriesIncludeMapCategory:YES])
        {
            for (OASPoiFilter *filter in [category getPoiFilters])
            {
                if ([[filter getKeyName] isEqualToString:type.name])
                    return filter;
            }
        }
        return nil;
    }
    if ([type isAdditional])
        return [types getAnyPoiAdditionalTypeByKeyName:type.name];
    return [types getPoiTypeByKeyName:type.name];
}

// the app's poi type of the same key: a category, a filter of one, an additional type or a type
+ (nullable OAPOIBaseType *)poiType:(OASAbstractPoiType *)type
{
    OAPOIHelper *helper = OAPOIHelper.sharedInstance;
    NSString *key = [type getKeyName];
    if ([type isKindOfClass:OASPoiCategory.class])
        return [helper getPoiCategoryByName:key];
    if ([type isKindOfClass:OASPoiFilter.class])
    {
        for (OAPOICategory *category in [helper getCategories:YES])
        {
            for (OAPOIFilter *filter in category.poiFilters)
            {
                if ([filter.name isEqualToString:key])
                    return filter;
            }
        }
        return nil;
    }
    if ([type isAdditional])
        return [helper getAnyPoiAdditionalTypeByKey:key];
    return [helper getPoiTypeByKey:key];
}

// the kinds of results of the app by the name of the same kind in the shared search; OAObjectType's
// names miss some, and its valueOf takes a name it does not know for a city
static NSDictionary<NSString *, NSNumber *> *appObjectTypesBySharedName()
{
    static NSDictionary<NSString *, NSNumber *> *types;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        types = @{
            @"CITY" : @(EOAObjectTypeCity),
            @"VILLAGE" : @(EOAObjectTypeVillage),
            @"BOUNDARY" : @(EOAObjectTypeBoundary),
            @"POSTCODE" : @(EOAObjectTypePostcode),
            @"STREET" : @(EOAObjectTypeStreet),
            @"HOUSE" : @(EOAObjectTypeHouse),
            @"STREET_INTERSECTION" : @(EOAObjectTypeStreetIntersection),
            @"POI_TYPE" : @(EOAObjectTypePoiType),
            @"POI" : @(EOAObjectTypePoi),
            @"LOCATION" : @(EOAObjectTypeLocation),
            @"PARTIAL_LOCATION" : @(EOAObjectTypePartialLocation),
            @"FAVORITE" : @(EOAObjectTypeFavorite),
            @"FAVORITE_GROUP" : @(EOAObjectTypeFavoriteGroup),
            @"WPT" : @(EOAObjectTypeWpt),
            @"RECENT_OBJ" : @(EOAObjectTypeRecentObj),
            @"GPX_TRACK" : @(EOAObjectTypeGpxTrack),
            @"REGION" : @(EOAObjectTypeRegion),
            @"SEARCH_STARTED" : @(EOAObjectTypeSearchStarted),
            @"SEARCH_FINISHED" : @(EOAObjectTypeSearchFinished),
            @"FILTER_FINISHED" : @(EOAObjectTypeFilterFinished),
            @"SEARCH_API_FINISHED" : @(EOAObjectTypeSearchApiFinished),
            @"SEARCH_API_REGION_FINISHED" : @(EOAObjectTypeSearchApiRegionFinished),
            @"UNKNOWN_NAME_FILTER" : @(EOAObjectTypeUnknownNameFilter),
            @"INDEX_ITEM" : @(EOAObjectTypeIndexItem),
        };
    });
    return types;
}

+ (EOAObjectType)appObjectType:(nullable OASObjectType *)type
{
    // a kind the app has no counterpart of, as an online search result, is undefined
    NSNumber *appType = type ? appObjectTypesBySharedName()[type.name] : nil;
    return appType ? (EOAObjectType) appType.integerValue : EOAObjectTypeUndefined;
}

+ (nullable OASObjectType *)sharedObjectType:(EOAObjectType)type
{
    static NSDictionary<NSNumber *, OASObjectType *> *sharedTypes;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        NSDictionary<NSString *, NSNumber *> *appTypes = appObjectTypesBySharedName();
        NSMutableDictionary<NSNumber *, OASObjectType *> *byAppType = [NSMutableDictionary dictionary];
        for (OASObjectType *t in OASObjectType.entries)
        {
            NSNumber *appType = appTypes[t.name];
            if (appType)
                byAppType[appType] = t;
        }
        sharedTypes = byAppType;
    });
    return sharedTypes[@(type)];
}

@end
