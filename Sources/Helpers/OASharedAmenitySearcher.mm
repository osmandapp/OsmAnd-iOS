//
//  OASharedAmenitySearcher.mm
//  OsmAnd
//
//  Copyright © 2026 OsmAnd. All rights reserved.
//

#import "OASharedAmenitySearcher.h"
#import "OAAmenitySearcher.h"
#import "OASharedSearchObjects.h"
#import "OAPOI.h"
#import "OAPOIType.h"
#import "OAPOICategory.h"
#import "OAPOIHelper.h"
#import "OARenderedObject.h"
#import "OAAddress.h"
#import "OASearchPoiTypeFilter.h"
#import "OATopIndexFilter.h"
#import "OAAppSettings.h"
#import "OAResultMatcher.h"
#import "OsmAndSharedWrapper.h"
#import "OsmAnd_Maps-Swift.h"

@interface OAAmenityTypeFilterAdapter : NSObject <OASSearchPoiTypeFilter>
@property (nonatomic) OASearchPoiTypeFilter *filter;
@end

@implementation OAAmenityTypeFilterAdapter
- (BOOL)acceptType:(OASPoiCategory *)type subcategory:(NSString *)subcategory
{
    OAPOICategory *category = type ? [OAPOIHelper.sharedInstance getPoiCategoryByName:type.keyName] : nil;
    return [self.filter accept:category subcategory:subcategory];
}
- (BOOL)isEmpty { return !self.filter || self.filter.isEmpty; }
@end

@implementation OASharedAmenitySearcher

+ (OASAmenitySearcherSettings *)settings
{
    OAAppSettings *settings = OAAppSettings.sharedManager;
    return [[OASAmenitySearcherSettings alloc] initWithLanguage:^NSString * {
        return settings.settingPrefMapLanguage.get;
    } transliterate:^OASBoolean * {
        return [[OASBoolean alloc] initWithBool:settings.settingMapLanguageTranslit.get];
    } fileVisibility:nil];
}

+ (OASKLatLon *)sharedLocation:(CLLocation *)location
{
    return location ? [[OASKLatLon alloc] initWithLatitude:location.coordinate.latitude longitude:location.coordinate.longitude] : nil;
}

+ (OASAmenitySearcherRequest *)sharedRequest:(OAAmenitySearcherRequest *)request
{
    OASEntityType *type = [request.type isEqualToString:kEntityTypeRelation] ? OASEntityType.relation
        : [request.type isEqualToString:kEntityTypeWay] ? OASEntityType.way
        : [request.type isEqualToString:kEntityTypeNode] ? OASEntityType.node : nil;
    return [[OASAmenitySearcherRequest alloc] initWithLatLon:[self sharedLocation:request.latLon]
        osmId:request.osmId type:type wikidata:request.wikidata names:[request.names copy]
        tags:[request.tags copy] mainAmenityType:request.mainAmenityType checkOriginName:NO];
}

+ (void)copyMapObject:(OAMapObject *)source to:(OASMapObject *)target
{
    [target setIdId:source.isValidObfId ? [[OASLong alloc] initWithLongLong:source.getSignedId] : nil];
    if ([source isKindOfClass:OAPOI.class] && [target isKindOfClass:OASAmenity.class])
        [(OAPOI *)source copyNamesToSharedAmenity:(OASAmenity *)target];
    else
    {
        [target setNameName:source.name];
        [target setEnNameEnName:source.enName];
        [target setNamesName:[source.localizedNames copy]];
    }
    [target setLocationLoc:[self sharedLocation:source.getLocation]];
}

+ (OASAmenity *)sharedAmenity:(OAPOI *)poi
{
    OASAmenity *amenity = [[OASAmenity alloc] init];
    [self copyMapObject:poi to:amenity];
    [amenity setTypeType:[OAPOIHelper.sharedInstance.kPoiTypes getPoiCategoryByNameName:poi.type.category.name ?: @"other"]];
    [amenity setSubTypeSubType:poi.subType ?: poi.type.name ?: @""];
    [amenity setRegionNameRegionName:poi.regionName];
    [amenity setMapIconNameMapIconName:poi.mapIconName];
    [amenity setWikiIconUrlWikiIconUrl:poi.wikiIconUrl];
    [amenity setWikiImageStubUrlWikiImageStubUrl:poi.wikiImageStubUrl];
    for (NSString *key in poi.values)
        [amenity setAdditionalInfoTag:key value:poi.values[key]];
    for (NSString *lang in poi.localizedContent)
        [amenity setAdditionalInfoTag:lang.length ? [@"content:" stringByAppendingString:lang] : @"content" value:poi.localizedContent[lang]];
    [amenity updateContentLocalesLocales:[poi getSupportedContentLocales]];
    OASKTIntArrayList *xx = [amenity getX];
    OASKTIntArrayList *yy = [amenity getY];
    for (NSUInteger i = 0; i < MIN(poi.x.count, poi.y.count); i++)
    {
        [xx addValue:poi.x[i].intValue];
        [yy addValue:poi.y[i].intValue];
    }
    if (poi.sharedAmenity)
    {
        NSDictionary *groups = [poi.sharedAmenity getTagGroups];
        for (OASInt *key in groups)
            [amenity addTagGroupId:key.intValue tagValues:groups[key]];
        [amenity setBbox31Bbox31:[poi.sharedAmenity getBbox31]];
    }
    if (poi.routePoint)
    {
        OASAmenityRoutePoint *point = [[OASAmenityRoutePoint alloc] init];
        point.deviateDistance = poi.routePoint.deviateDistance;
        point.deviationDirectionRight = poi.routePoint.deviationDirectionRight;
        if (poi.routePoint.pointA)
            point.pointA = [[OASKLocation alloc] initWithProvider:nil latitude:poi.routePoint.pointA.coordinate.latitude longitude:poi.routePoint.pointA.coordinate.longitude];
        if (poi.routePoint.pointB)
            point.pointB = [[OASKLocation alloc] initWithProvider:nil latitude:poi.routePoint.pointB.coordinate.latitude longitude:poi.routePoint.pointB.coordinate.longitude];
        [amenity setRoutePointRoutePoint:point];
    }
    return amenity;
}

+ (OASMapObject *)sharedMapObject:(OAMapObject *)object
{
    if ([object isKindOfClass:OAPOI.class])
        return [self sharedAmenity:(OAPOI *)object];
    if ([object isKindOfClass:OAAddress.class])
    {
        id shared = [OASharedSearchObjects sharedObjectFor:object];
        if ([shared isKindOfClass:OASMapObject.class])
            return shared;
    }
    if ([object isKindOfClass:OARenderedObject.class])
    {
        OARenderedObject *source = (OARenderedObject *)object;
        OASRenderedObject *target = [[OASRenderedObject alloc] init];
        [self copyMapObject:source to:target];
        for (NSString *key in source.tags)
            [target putTagT:key v:source.tags[key]];
        for (NSUInteger i = 0; i < MIN(source.x.count, source.y.count); i++)
            [target addLocationX:source.x[i].intValue y:source.y[i].intValue];
        [target setLabelLatLonLabelLatLon:[self sharedLocation:source.labelLatLon]];
        [target setLabelXLabelX:(int32_t)source.labelX];
        [target setLabelYLabelY:(int32_t)source.labelY];
        [target setBboxLeft:(int32_t)source.bboxLeft top:(int32_t)source.bboxTop right:(int32_t)source.bboxRight bottom:(int32_t)source.bboxBottom];
        [target setIconResIconRes:source.iconRes];
        [target setOrderOrder:(int32_t)source.order];
        [target setVisibleVisible:source.visible];
        [target setDrawOnPathDrawOnPath:source.drawOnPath];
        [target markAsPolygonIsPolygon:source.isPolygon];
        return target;
    }
    return nil;
}

+ (BaseDetailsObject *)appDetails:(OASBaseDetailsObject *)details originals:(NSMapTable *)originals
{
    if (!details)
        return nil;
    NSMutableArray *objects = [NSMutableArray array];
    for (id object in [details getObjects])
    {
        id appObject = [originals objectForKey:object];
        if (!appObject && [object isKindOfClass:OASAmenity.class])
            appObject = [OAAmenitySearcher parsePOIBySharedAmenity:object filterTypes:NO];
        if (!appObject)
            appObject = [OASharedSearchObjects appObjectFor:object];
        if (appObject)
            [objects addObject:appObject];
    }
    OAPOI *amenity = [OAAmenitySearcher parsePOIBySharedAmenity:[details getSyntheticAmenity] filterTypes:NO];
    return [[BaseDetailsObject alloc] initWithObjects:objects amenity:amenity lang:[details getLang] ?: @""
        full:[details isObjectFull] combined:[details isObjectCombined]];
}

+ (BaseDetailsObject *)searchDetailedRequest:(OAAmenitySearcherRequest *)request
{
    OASBaseDetailsObject *details = [OASharedObfResources.shared.amenitySearcher
        searchDetailedObjectRequest:[self sharedRequest:request] settings:self.settings matcher:nil];
    return [self appDetails:details originals:nil];
}

+ (BaseDetailsObject *)searchDetailedObject:(id)object
{
    if ([object isKindOfClass:OAAmenitySearcherRequest.class])
        return [self searchDetailedRequest:object];
    NSMapTable *originals = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory | NSPointerFunctionsObjectPointerPersonality
                                               valueOptions:NSPointerFunctionsStrongMemory];
    OASAmenitySearcher *searcher = OASharedObfResources.shared.amenitySearcher;
    id shared = nil;
    if ([object isKindOfClass:BaseDetailsObject.class])
    {
        BaseDetailsObject *details = object;
        NSMutableArray<OASMapObject *> *objects = [NSMutableArray array];
        for (id item in details.objects)
        {
            OASMapObject *converted = [item isKindOfClass:OAMapObject.class] ? [self sharedMapObject:item] : nil;
            if (!converted && [item isKindOfClass:OATransportStop.class] && ((OATransportStop *)item).poi)
                converted = [self sharedAmenity:((OATransportStop *)item).poi];
            if (converted)
            {
                [objects addObject:converted];
                [originals setObject:item forKey:converted];
            }
        }
        if (objects.count == 0)
            return details;
        OASBaseDetailsObjectObjectCompleteness *completeness = details.isObjectEmpty
            ? OASBaseDetailsObjectObjectCompleteness.empty
            : details.isObjectCombined ? OASBaseDetailsObjectObjectCompleteness.combined
            : OASBaseDetailsObjectObjectCompleteness.full;
        shared = [[OASBaseDetailsObject alloc] initWithMapObjects:objects
            amenity:[self sharedAmenity:details.syntheticAmenity] lang:details.lang completeness:completeness];
    }
    else if ([object isKindOfClass:OAMapObject.class])
    {
        shared = [self sharedMapObject:object];
        if (shared)
            [originals setObject:object forKey:shared];
        else
        {
            // Public transport models remain native; the query crosses as object attributes.
            OAAmenitySearcherRequest *request = [[OAAmenitySearcherRequest alloc] initWithMapObject:object];
            shared = [searcher searchDetailedObjectRequest:[self sharedRequest:request] settings:self.settings matcher:nil];
        }
    }
    if (!shared)
        return nil;
    OASBaseDetailsObject *result = [searcher searchDetailedObjectObj:shared settings:self.settings];
    if (result == shared && [object isKindOfClass:BaseDetailsObject.class])
    {
        BaseDetailsObject *details = object;
        OAPOI *geometry = [OAAmenitySearcher parsePOIBySharedAmenity:[result getSyntheticAmenity] filterTypes:NO];
        [details setX:geometry.x];
        [details setY:geometry.y];
        return details;
    }
    return [self appDetails:result originals:originals];
}

+ (id<OASSearchPoiTypeFilter>)typeFilter:(OASearchPoiTypeFilter *)filter
{
    OAAmenityTypeFilterAdapter *adapter = [[OAAmenityTypeFilterAdapter alloc] init];
    adapter.filter = filter;
    return adapter;
}

+ (id<OASSearchPoiAdditionalFilter>)additionalFilter:(OATopIndexFilter *)filter
{
    if (!filter)
        return nil;
    OASPoiSubType *type = [[OASPoiSubType alloc] init];
    type.name = filter.poiSubType;
    return [[OASTopIndexFilter alloc] initWithPoiSubType:type types:OAPOIHelper.sharedInstance.kPoiTypes value:filter.value];
}

+ (NSArray<OAPOI *> *)appAmenities:(NSArray<OASAmenity *> *)amenities
{
    NSMutableArray<OAPOI *> *pois = [NSMutableArray arrayWithCapacity:amenities.count];
    for (OASAmenity *amenity in amenities)
    {
        OAPOI *poi = [OAAmenitySearcher parsePOIBySharedAmenity:amenity];
        if (poi)
            [pois addObject:poi];
    }
    return pois;
}

+ (NSArray<OAPOI *> *)searchAmenities:(OASearchPoiTypeFilter *)filter additionalFilter:(OATopIndexFilter *)additionalFilter
                         topLatitude:(double)top leftLongitude:(double)left bottomLatitude:(double)bottom rightLongitude:(double)right
                       includeTravel:(BOOL)includeTravel
                             matcher:(OAResultMatcher<OAPOI *> *)matcher publish:(BOOL (^)(OAPOI *))publish
{
    __block BOOL stopped = NO;
    NSMapTable *converted = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory | NSPointerFunctionsObjectPointerPersonality
                                               valueOptions:NSPointerFunctionsStrongMemory];
    id<OASResultMatcher> sharedMatcher = [OASharedBlockResultMatcher matcherWithPublish:^BOOL(OASAmenity *amenity) {
        if (stopped || (matcher && matcher.isCancelled))
            return NO;
        OAPOI *poi = [OAAmenitySearcher parsePOIBySharedAmenity:amenity];
        if (!poi)
            return NO;
        if (matcher && ![matcher publish:poi])
            return NO;
        if (publish)
        {
            stopped = publish(poi);
            return NO;
        }
        [converted setObject:poi forKey:amenity];
        return YES;
    } cancelled:^BOOL { return stopped || (matcher && matcher.isCancelled); }];
    NSArray<OASAmenity *> *amenities = [OASharedObfResources.shared.amenitySearcher searchAmenitiesFilter:[self typeFilter:filter]
        additionalFilter:[self additionalFilter:additionalFilter] topLatitude:top leftLongitude:left bottomLatitude:bottom rightLongitude:right
        zoom:-1 includeTravel:includeTravel travelFileVisibility:nil matcher:sharedMatcher];
    NSMutableArray<OAPOI *> *result = [NSMutableArray arrayWithCapacity:amenities.count];
    for (OASAmenity *amenity in amenities)
    {
        OAPOI *poi = [converted objectForKey:amenity];
        if (poi)
            [result addObject:poi];
    }
    return result;
}

+ (id<OASResultMatcher>)matcher:(OAResultMatcher<OAPOI *> *)matcher objects:(NSMapTable *)objects
{
    return [OASharedBlockResultMatcher matcherWithPublish:^BOOL(OASAmenity *amenity) {
        if (matcher && matcher.isCancelled)
            return NO;
        OAPOI *poi = [OAAmenitySearcher parsePOIBySharedAmenity:amenity];
        if (!poi || (matcher && ![matcher publish:poi]))
            return NO;
        [objects setObject:poi forKey:amenity];
        return YES;
    } cancelled:^BOOL { return matcher && matcher.isCancelled; }];
}

+ (NSArray<OAPOI *> *)appAmenities:(NSArray<OASAmenity *> *)amenities objects:(NSMapTable *)objects
{
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:amenities.count];
    for (OASAmenity *amenity in amenities)
    {
        OAPOI *poi = [objects objectForKey:amenity];
        if (poi)
            [result addObject:poi];
    }
    return result;
}

+ (NSMapTable *)objectMap
{
    return [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory | NSPointerFunctionsObjectPointerPersonality
                               valueOptions:NSPointerFunctionsStrongMemory];
}

+ (NSArray<OAPOI *> *)searchByName:(NSString *)name topLatitude:(double)top leftLongitude:(double)left
                  bottomLatitude:(double)bottom rightLongitude:(double)right matcher:(OAResultMatcher<OAPOI *> *)matcher
{
    NSMapTable *objects = self.objectMap;
    NSArray *amenities = [OASharedObfResources.shared.amenitySearcher searchAmenitiesByNameSearchQuery:name
        topLatitude:top leftLongitude:left bottomLatitude:bottom rightLongitude:right lat:(top + bottom) / 2 lon:(left + right) / 2
        matcher:[self matcher:matcher objects:objects]];
    return [self appAmenities:amenities objects:objects];
}

+ (NSArray<OAPOI *> *)searchByName:(NSString *)name resourceId:(NSString *)resourceId
                        location:(CLLocation *)location matcher:(OAResultMatcher<OAPOI *> *)matcher
{
    id<OASAmenityIndexRepository> repository = [OASharedObfResources.shared amenityRepositoryForResourceId:resourceId];
    if (!repository)
        return @[];
    OASSearchRequest<OASAmenity *> *request = [OASSearchRequest.companion buildSearchPoiRequestX:
        location ? [OASKMapUtils.shared get31TileNumberXLongitude:location.coordinate.longitude] : 0
        y:location ? [OASKMapUtils.shared get31TileNumberYLatitude:location.coordinate.latitude] : 0
        nameFilter:name sleft:0 sright:INT_MAX stop:0 sbottom:INT_MAX poiTypeFilter:nil resultMatcher:[self matcher:matcher objects:nil] rawDataCollector:nil];
    [request setMatcherModeMode:OASKStringMatcherMode.checkEquals];
    NSArray *result = [repository searchPoiByNameSearchRequest:request];
    // This resource-scoped API delivers through the matcher when one is supplied.
    return matcher ? @[] : [self appAmenities:result];
}

+ (NSArray<OAPOI *> *)searchOnPath:(NSArray<CLLocation *> *)locations radius:(double)radius
                          filter:(OASearchPoiTypeFilter *)filter matcher:(OAResultMatcher<OAPOI *> *)matcher
{
    NSMutableArray<OASKLocation *> *path = [NSMutableArray arrayWithCapacity:locations.count];
    for (CLLocation *location in locations)
        [path addObject:[[OASKLocation alloc] initWithProvider:nil latitude:location.coordinate.latitude longitude:location.coordinate.longitude]];
    NSMapTable *objects = self.objectMap;
    NSArray *amenities = [OASharedObfResources.shared.amenitySearcher searchAmenitiesOnThePathLocations:path
        radius:radius filter:[self typeFilter:filter] matcher:[self matcher:matcher objects:objects]];
    return [self appAmenities:amenities objects:objects];
}

+ (NSArray<OAPOI *> *)mergeAmenities:(NSArray<OAPOI *> *)pois
{
    if (pois.count < 2)
        return pois;
    NSMutableArray *amenities = [NSMutableArray arrayWithCapacity:pois.count];
    NSMapTable *objects = self.objectMap;
    for (OAPOI *poi in pois)
    {
        OASAmenity *amenity = [self sharedAmenity:poi];
        [amenities addObject:amenity];
        [objects setObject:poi forKey:amenity];
    }
    NSArray *merged = [OASharedObfResources.shared.amenitySearcher mergeAmenitiesAmenities:amenities settings:self.settings];
    if (merged.count == pois.count)
        return pois;
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:merged.count];
    for (OASAmenity *amenity in merged)
    {
        OAPOI *source = [objects objectForKey:amenity];
        OAPOI *poi = [OAAmenitySearcher parsePOIBySharedAmenity:amenity filterTypes:NO];
        poi.distanceMeters = source.distanceMeters;
        poi.distance = source.distance;
        poi.direction = source.direction;
        poi.desc = source.desc;
        poi.buildingNumber = source.buildingNumber;
        poi.isPlace = source.isPlace;
        if (poi)
            [result addObject:poi];
    }
    return result;
}

@end
