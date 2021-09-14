//
//  OAPOIUIFilter.m
//  OsmAnd
//
//  Created by Alexey Kulish on 21/12/2016.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OAPOIUIFilter.h"
#import "OAPOI.h"
#import "OAPOICategory.h"
#import "OAPOIType.h"
#import "OAPOIHelper.h"
#import "OsmAndApp.h"
#import "Localization.h"
#import "OAPOIFiltersHelper.h"
#import "OAResultMatcher.h"
#import "OAMapUtils.h"
#import "OAUtilities.h"
#import "OANameStringMatcher.h"
#import "OAOsmAndFormatter.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>
#include <openingHoursParser.h>

@implementation OAAmenityNameFilter

-(BOOL)accept:(OAPOI *)a
{
    if (_acceptFunction)
        return _acceptFunction(a);
    
    return NO;
}

- (instancetype)initWithAcceptFunc:(OAAmenityNameFilterAccept)aFunction
{
    self = [super init];
    if (self) {
        _acceptFunction = aFunction;
    }
    return self;
}

@end


@interface OAPOIUIFilter ()

@property (nonatomic) NSMapTable<OAPOICategory *, NSMutableSet<NSString *> *> *acceptedTypes;
@property (nonatomic) NSMapTable<OAPOICategory *, NSMutableSet<NSString *> *> *acceptedTypesOrigin;
@property (nonatomic) NSMapTable<NSString *, OAPOIType *> *poiAdditionals;

@end

@implementation OAPOIUIFilter
{
    OAPOIHelper *poiHelper;
    OAPOIFiltersHelper *filtersHelper;
    OsmAndAppInstance app;
}

@synthesize acceptedTypes, acceptedTypesOrigin, poiAdditionals, standardIconId, filterId, isStandardFilter, name, distanceInd, distanceToSearchValues, currentSearchResult;

// search by name standard
- (instancetype)init
{
    self = [super init];
    if (self)
    {
        standardIconId = @"";
        distanceInd = 0;
        distanceToSearchValues = @[@1, @2, @5, @10, @20, @50, @100, @200, @500];
        
        acceptedTypes = [NSMapTable strongToStrongObjectsMapTable];
        acceptedTypesOrigin = [NSMapTable strongToStrongObjectsMapTable];
        poiAdditionals = [NSMapTable strongToStrongObjectsMapTable];
        poiHelper = [OAPOIHelper sharedInstance];
        filtersHelper = [OAPOIFiltersHelper sharedInstance];
        app = [OsmAndApp instance];
        
        _isActive = YES;
        isStandardFilter = YES;
        filterId = STD_PREFIX;
    }
    return self;
}

// constructor for standard filters
- (instancetype)initWithBasePoiType:(OAPOIBaseType *)type idSuffix:(NSString *)idSuffix
{
    self = [self init];
    if (self)
    {
        isStandardFilter = YES;
        standardIconId = (!type ? nil : type.name);
        filterId = [[STD_PREFIX stringByAppendingString:(standardIconId ? standardIconId : @"")] stringByAppendingString:idSuffix];
        
        name = !type ? OALocalizedString(@"poi_filter_closest_poi") : ([type.nameLocalized stringByAppendingString:idSuffix]);
        if (!type)
        {
            [self initSearchAll];
            [self updatePoiAdditionals];
        }
        else
        {
            
            if (type.isAdditional)
                [self setSavedFilterByName:[type.name stringByReplacingOccurrencesOfString:@"_" withString:@":"]];

            [self updateTypesToAccept:type];
        }
    }
    return self;
}

// constructor for user defined filters
- (instancetype)initWithName:(NSString *)nm filterId:(NSString *)fId acceptedTypes:(NSMapTable<OAPOICategory *, NSMutableSet<NSString *> *> *)accTypes
{
    self = [self init];
    if (self)
    {
        isStandardFilter = NO;
        if (!fId)
            fId = [USER_PREFIX stringByAppendingString:[[nm stringByReplacingOccurrencesOfString:@" " withString:@"_"] lowercaseString]];

        filterId = fId;
        name = nm;
        if (!accTypes)
        {
            [self initSearchAll];
        }
        else
        {
            NSEnumerator<OAPOICategory *> *e = accTypes.keyEnumerator;
            for (OAPOICategory *c in e)
                [acceptedTypes setObject:[accTypes objectForKey:c] forKey:c];
        }
        
        [self updatePoiAdditionals];
        [self updateAcceptedTypeOrigins];
    }
    return self;
}

- (instancetype)initWithFiltersToMerge:(NSSet<OAPOIUIFilter *> *)filtersToMerge
{
    self = [self init];
    if (self)
    {
        [self combineWithPoiFilters:filtersToMerge];
        filterId = [STD_PREFIX stringByAppendingString:@"combined"];
        name = [filtersHelper getFiltersName:filtersToMerge];
    }
    return self;
}

- (instancetype)initWithFilter:(OAPOIUIFilter *)filter name:(NSString *)nm filterId:(NSString *)fId
{
    self = [self init];
    if (self)
    {
        isStandardFilter = NO;
        filterId = fId;
        name = nm;
        acceptedTypes = filter.acceptedTypes;
        poiAdditionals = filter.poiAdditionals;
        _filterByName = filter.filterByName;
        _savedFilterByName = filter.savedFilterByName;
        [self updateAcceptedTypeOrigins];
    }
    return self;
}

+ (NSComparator) getComparator
{
    static dispatch_once_t once;
    static NSComparator comparator;
    dispatch_once(&once, ^{
        comparator = ^NSComparisonResult(id obj1, id obj2)
        {
            OAPOIUIFilter *f1 = obj1;
            OAPOIUIFilter *f2 = obj2;
            if (f1.order != INVALID_ORDER && f2.order != INVALID_ORDER)
            {
                return (f1.order < f2.order) ? NSOrderedAscending : ((f1.order == f2.order) ? NSOrderedSame : NSOrderedDescending);
            }
            else if ([f2.filterId isEqualToString:f1.filterId])
            {
                NSString *f1FilterByName = !f1.filterByName ? @"" : f1.filterByName;
                NSString *f2FilterByName = !f2.filterByName ? @"" : f2.filterByName;
                return [f1FilterByName localizedCaseInsensitiveCompare:f2FilterByName];
            }
            else
            {
                return [f1.name localizedCaseInsensitiveCompare:f2.name];
            }
        };
    });
    return comparator;
}

- (void)setFilterByName:(NSString *)filter
{
    _filterByName = filter;
    [self updateFilterResults];
}

- (void)updateFilterResults
{
    NSArray<OAPOI *> *prev = currentSearchResult;
    if (prev)
    {
        OAAmenityNameFilter *nameFilter = [self getNameFilter:self.filterByName];
        NSMutableArray<OAPOI *> *newResults = [NSMutableArray array];
        for (OAPOI *a in prev)
        {
            if ([nameFilter accept:a])
                [newResults addObject:a];
        }
        currentSearchResult = newResults;
    }
}

-(void) removeUnsavedFilterByName
{
    _filterByName = _savedFilterByName;
    [self updateFilterResults];
}

- (BOOL)isWikiFilter
{
    return [self.filterId hasPrefix:[NSString stringWithFormat:@"%@%@", STD_PREFIX, @"wiki_place"]] || [self isTopWikiFilter];
}

- (BOOL)isTopWikiFilter
{
    return [self.filterId isEqualToString:[NSString stringWithFormat:@"%@%@", STD_PREFIX, OSM_WIKI_CATEGORY]];
}

-(void)setSavedFilterByName:(NSString *)savedFilterByName
{
    _savedFilterByName = savedFilterByName;
    _filterByName = savedFilterByName;
}

- (NSArray<OAPOI *> *) searchAgain:(double)lat lon:(double)lon
{
    NSArray<OAPOI *> *amenityList;
    if (currentSearchResult)
        amenityList = currentSearchResult;
    else
        amenityList = [self searchAmenities:lat lon:lon matcher:nil];
    
    return [OAMapUtils sortPOI:amenityList lat:lat lon:lon];
}

- (NSArray<OAPOI *> *) searchFurther:(double)latitude longitude:(double)longitude matcher:(OAResultMatcher<OAPOI *> *)matcher
{
    if (distanceInd < distanceToSearchValues.count - 1)
        distanceInd++;

    NSArray<OAPOI *> *amenityList = [self searchAmenities:latitude lon:longitude matcher:matcher];
    
    return [OAMapUtils sortPOI:amenityList lat:latitude lon:longitude];
}

- (void) initSearchAll
{
    for (OAPOICategory *t in poiHelper.poiCategoriesNoOther)
        [acceptedTypes setObject:[OAPOIBaseType nullSet] forKey:t];

    distanceToSearchValues = @[@0.5, @1, @2, @5, @10, @20, @50, @100];
}

- (BOOL) isSearchFurtherAvailable
{
    return distanceInd < (int) distanceToSearchValues.count - 1;
}

- (NSString *) getSearchArea:(BOOL)next
{
    int distInd = distanceInd;
    if (next && (distanceInd < distanceToSearchValues.count - 1))
    {
        //This is workaround for the SearchAmenityTask.onPreExecute() case
        distInd = distanceInd + 1;
    }
    double val = distanceToSearchValues[distInd].doubleValue;
    if (val >= 1) {
        return [@" < " stringByAppendingString:[OAOsmAndFormatter getFormattedDistance:(int)val * 1000]];
    } else {
        return [@" < " stringByAppendingString:[OAOsmAndFormatter getFormattedDistance:500]];
    }
}

- (void) clearPreviousZoom
{
    distanceInd = 0;
}

- (void) clearCurrentResults
{
    if (currentSearchResult)
        currentSearchResult = @[];
}

- (NSArray<OAPOI *> *) initializeNewSearch:(double)lat lon:(double)lon firstTimeLimit:(int)firstTimeLimit  matcher:(OAResultMatcher<OAPOI *> *)matcher
{
    [self clearPreviousZoom];
    NSMutableArray<OAPOI *> *amenityList = [[self searchAmenities:lat lon:lon matcher:matcher] mutableCopy];
    amenityList = [[OAMapUtils sortPOI:amenityList lat:lat lon:lon] mutableCopy];
    if (firstTimeLimit > 0)
    {
        while (amenityList.count > firstTimeLimit)
            [amenityList removeLastObject];
    }
    if (amenityList.count == 0 && [self isAutomaticallyIncreaseSearch])
    {
        int step = 5;
        while (amenityList.count == 0 && step-- > 0 && [self isSearchFurtherAvailable])
        {
            if (matcher && [matcher isCancelled])
                break;

            amenityList = [[self searchFurther:lat longitude:lon matcher:matcher] mutableCopy];
        }
    }
    return amenityList;
}

- (BOOL) isAutomaticallyIncreaseSearch
{
    return YES;
}

- (NSArray<OAPOI *> *) searchAmenities:(double)lat lon:(double)lon matcher:(OAResultMatcher<OAPOI *> *)matcher
{
    double baseDistY = OsmAnd::Utilities::distance(lon, lat, lon, lat - 1);
    double baseDistX = OsmAnd::Utilities::distance(lon, lat, lon - 1, lat);
    double distance = distanceToSearchValues[distanceInd].doubleValue * 1000;
    double topLatitude = MIN(lat + (distance / baseDistY), 84.);
    double bottomLatitude = MAX(lat - (distance / baseDistY), -84.);
    double leftLongitude = MAX(lon - (distance / baseDistX), -180);
    double rightLongitude = MIN(lon + (distance / baseDistX), 180);
    return [self searchAmenitiesInternal:lat lon:lon topLatitude:topLatitude bottomLatitude:bottomLatitude leftLongitude:leftLongitude rightLongitude:rightLongitude zoom:-1 matcher:matcher];
}

- (NSArray<OAPOI *> *) searchAmenities:(double)top left:(double)left bottom:(double)bottom right:(double)right zoom:(int)zoom matcher:(OAResultMatcher<OAPOI *> *)matcher
{
    NSMutableArray<OAPOI *> *results = [NSMutableArray array];
    NSArray<OAPOI *> *tempResults = currentSearchResult;
    if (tempResults)
    {
        for (OAPOI *a in tempResults)
        {
            if (a.latitude <= top && a.latitude >= bottom && a.longitude >= left
                && a.longitude <= right)
            {
                if (!matcher || [matcher publish:a])
                    [results addObject:a];
            }
        }
    }
    NSArray<OAPOI *> *amenities = [self searchAmenitiesInternal:top / 2 + bottom / 2 lon:left / 2 + right / 2 topLatitude:top bottomLatitude:bottom leftLongitude:left rightLongitude:right zoom:zoom matcher:matcher];
    [results addObjectsFromArray:amenities];
    return results;
}

- (NSArray<OAPOI *> *) searchAmenitiesOnThePath:(NSArray<CLLocation *> *)locs poiSearchDeviationRadius:(int)poiSearchDeviationRadius
{
    return [OAPOIHelper searchPOIsOnThePath:locs radius:poiSearchDeviationRadius filter:self matcher:[self wrapResultMatcher:nil]];
}

- (NSArray<OAPOI *> *) searchAmenitiesInternal:(double)lat lon:(double)lon topLatitude:(double)topLatitude bottomLatitude:(double)bottomLatitude leftLongitude:(double)leftLongitude rightLongitude:(double)rightLongitude zoom:(int)zoom matcher:(OAResultMatcher<OAPOI *> *)matcher
{
    return [OAPOIHelper findPOIsByFilter:self topLatitude:topLatitude leftLongitude:leftLongitude bottomLatitude:bottomLatitude rightLongitude:rightLongitude matcher:[self wrapResultMatcher:matcher]];
}

- (OAAmenityNameFilter *) getNameFilter:(NSString *)filter
{
    if (filter.length == 0)
    {
        return [[OAAmenityNameFilter alloc] initWithAcceptFunc:^BOOL(OAPOI *poi) {
            return YES;
        }];
    }
    NSMutableString *nmFilter = [NSMutableString string];
    NSArray<NSString *> *items = [filter componentsSeparatedByString:@" "];
    BOOL allTime = NO;
    BOOL open = NO;
    NSMutableArray<OAPOIType *> *poiAdditionalsFilter;
    for (NSString *str in items)
    {
        NSString *s = [str trim];
        if (s.length > 0)
        {
            if ([[self getNameToken24H] caseInsensitiveCompare:s] == 0)
            {
                allTime = YES;
            }
            else if ([[self getNameTokenOpen] caseInsensitiveCompare:s] == 0)
            {
                open = YES;
            }
            else if ([poiAdditionals objectForKey:[s lowercaseString]])
            {
                if (!poiAdditionalsFilter)
                    poiAdditionalsFilter = [NSMutableArray array];

                OAPOIType *pt = [poiAdditionals objectForKey:[s lowercaseString]];
                if (pt)
                    [poiAdditionalsFilter addObject:pt];
            }
            else
            {
                [nmFilter appendString:s];
                [nmFilter appendString:@" "];
            }
        }
    }
    return [self getNameFilterInternal:nmFilter allTime:allTime open:open poiAdditionals:poiAdditionalsFilter];
}

- (OAAmenityNameFilter *) getNameFilterInternal:(NSMutableString *)nmFilter allTime:(BOOL)allTime open:(BOOL)open poiAdditionals:(NSArray<OAPOIType *> *)poiAdds
{
    OANameStringMatcher __block *sm = nmFilter.length > 0 ?
				[[OANameStringMatcher alloc] initWithNamePart:[nmFilter trim] mode:CHECK_STARTS_FROM_SPACE] : nil;

    return [[OAAmenityNameFilter alloc] initWithAcceptFunc:^BOOL(OAPOI *poi) {

        if (sm)
        {
            NSString *lower = [poiHelper getPoiStringWithoutType:poi];
            if (![sm matches:lower] && ![sm matchesMap:poi.localizedNames.allValues])
                return NO;
        }
        if (poiAdds)
        {
            NSMapTable<OAPOIType *, OAPOIType *> *textPoiAdditionalsMap = [NSMapTable strongToStrongObjectsMapTable];
            NSMapTable<NSString *, NSMutableArray<OAPOIType *> *> *poiAdditionalCategoriesMap = [NSMapTable strongToStrongObjectsMapTable];
            for (OAPOIType *pt in poiAdds)
            {
                NSString *category = pt.poiAdditionalCategory;
                if (!category)
                    category = @"";
                NSMutableArray<OAPOIType *> *types = [poiAdditionalCategoriesMap objectForKey:category];
                if (!types)
                    types = [NSMutableArray array];
                
                [types addObject:pt];
                [poiAdditionalCategoriesMap setObject:types forKey:category];

                NSString *osmTag = pt.tag;
                if (osmTag.length < pt.name.length)
                {
                    OAPOIType *textPoiType = [poiHelper getTextPoiAdditionalByKey:osmTag];
                    if (!textPoiType)
                        [textPoiAdditionalsMap setObject:textPoiType forKey:pt];
                }
            }
            for (NSMutableArray<OAPOIType *> *types in poiAdditionalCategoriesMap.objectEnumerator)
            {
                BOOL acceptedAnyInCategory = NO;
                for (OAPOIType *p in types)
                {
                    NSString *inf = [poi.values objectForKey:p.name];
                    if (inf)
                    {
                        acceptedAnyInCategory = YES;
                        break;
                    }
                    else
                    {
                        OAPOIType *textPoiType = [textPoiAdditionalsMap objectForKey:p];
                        if (textPoiType)
                        {
                            inf = [poi.values objectForKey:textPoiType.name];
                            if (inf.length > 0)
                            {
                                NSArray<NSString *> *items = [inf componentsSeparatedByString:@";"];
                                NSString *val = [[p.value trim] lowerCase];
                                for (NSString *item in items)
                                {
                                    if ([[[item trim] lowerCase] isEqualToString:val])
                                    {
                                        acceptedAnyInCategory = YES;
                                        break;
                                    }
                                }
                                if (acceptedAnyInCategory)
                                    break;
                            }
                        }
                    }
                }
                if (!acceptedAnyInCategory)
                    return NO;
            }
        }
        if (allTime)
        {
            if (!poi.openingHours || (![@"24/7" isEqualToString:poi.openingHours] && ![@"Mo-Su 00:00-24:00" isEqualToString:poi.openingHours]))
                return NO;
        }
        if (open)
        {
            if (!poi.openingHours)
            {
                return NO;
            }
            else
            {
                auto parser = OpeningHoursParser::parseOpenedHours([poi.openingHours UTF8String]);
                if (!parser || !parser->isOpened())
                    return NO;
            }
        }
        return YES;
    }];
}

- (NSString *) getNameToken24H
{
    return [[OALocalizedString(@"shared_string_is_open_24_7") stringByReplacingOccurrencesOfString:@" " withString:@"_"] lowerCase];
}

- (NSString *) getNameTokenOpen
{
    return [[OALocalizedString(@"shared_string_is_open") stringByReplacingOccurrencesOfString:@" " withString:@"_"] lowerCase];
}

- (NSObject *) getIconResource
{
    return [self getIconId];
}

- (OAResultMatcher<OAPOI *> *) wrapResultMatcher:(OAResultMatcher<OAPOI *> *)matcher
{
    OAAmenityNameFilter *nm = [self getNameFilter:self.filterByName];
    return [[OAResultMatcher<OAPOI *> alloc] initWithPublishFunc:^BOOL(OAPOI *__autoreleasing *poi) {
        if ([nm accept:*poi] && (!matcher || [matcher publish:*poi]))
            return YES;
        else
            return NO;
            
    } cancelledFunc:^BOOL{
        return matcher && [matcher isCancelled];
    }];
}

- (NSString *) getName
{
    return self.name;
}

- (NSString *) getFilterId
{
    return self.filterId;
}

- (NSString *) getGeneratedName:(int)chars
{
    if (![filterId isEqualToString:CUSTOM_FILTER_ID] ||
        [self areAllTypesAccepted] || acceptedTypes.count == 0)
    {
        return [self getName];
    }
    NSMutableString *res = [NSMutableString string];
    for (OAPOICategory *p in [acceptedTypes keyEnumerator])
    {
        NSMutableSet<NSString *> *set = [acceptedTypes objectForKey:p];
        if (!set)
        {
            if (res.length > 0)
                [res appendString:@", "];

            [res appendString:p.nameLocalized];
        }
        if (res.length > chars)
            return res;
    }
    for (OAPOICategory *p in [acceptedTypes keyEnumerator])
    {
        NSMutableSet<NSString *> *set = [acceptedTypes objectForKey:p];
        if (set)
        {
            for (NSString *st in set)
            {
                if (res.length > 0)
                    [res appendString:@", "];

                OAPOIType *pt = [poiHelper getPoiTypeByName:st];
                if (pt)
                {
                    [res appendString:pt.nameLocalized];
                    if (res.length > chars)
                        return res;
                }
            }
        }
    }
    return res;
}

/**
 * @param type
 * @return nullSet if all subtypes are accepted/ empty list if type is not accepted at all
 */
- (NSSet<NSString *> *) getAcceptedSubtypes:(OAPOICategory *)type
{
    NSMutableSet<NSString *> *set = [acceptedTypes objectForKey:type];
    if (!set)
        return [NSSet set];

    return set;
}

- (BOOL) isTypeAccepted:(OAPOICategory *)t
{
    return [acceptedTypes objectForKey:t] != nil;
}

- (void) clearFilter
{
    acceptedTypes = [NSMapTable strongToStrongObjectsMapTable];
    [poiAdditionals removeAllObjects];
    _filterByName = nil;
    [self clearCurrentResults];
}

- (BOOL) areAllTypesAccepted
{
    if (poiHelper.poiCategoriesNoOther.count == acceptedTypes.count)
    {
        for (OAPOICategory *a in [acceptedTypes keyEnumerator])
        {
            if ([acceptedTypes objectForKey:a] != [OAPOIBaseType nullSet])
                return NO;
        }
        return YES;
    }
    return NO;
}

- (void) updateTypesToAccept:(OAPOIBaseType *)pt
{
    _baseType = pt;
    [pt putTypes:acceptedTypes];
    if ([pt isKindOfClass:[OAPOIType class]] && [((OAPOIType *) pt) isAdditional] && ((OAPOIType *) pt).parentType)
        [self fillPoiAdditionals:((OAPOIType *) pt).parentType allFromCategory:YES];
    else
        [self fillPoiAdditionals:pt allFromCategory:YES];
    
    [self addOtherPoiAdditionals];
}

- (void) fillPoiAdditionals:(OAPOIBaseType *)pt allFromCategory:(BOOL)allFromCategory
{
    for (OAPOIType *add in pt.poiAdditionals)
    {
        [poiAdditionals setObject:add forKey:[[add.name stringByReplacingOccurrencesOfString:@"_" withString:@":"] stringByReplacingOccurrencesOfString:@" " withString:@":"]];
        [poiAdditionals setObject:add forKey:[[add.nameLocalized stringByReplacingOccurrencesOfString:@" " withString:@":"] lowerCase]];
    }
    if ([pt isKindOfClass:[OAPOICategory class]] && allFromCategory)
    {
        for (OAPOIFilter *pf in ((OAPOICategory *) pt).poiFilters)
        {
            [self fillPoiAdditionals:pf allFromCategory:YES];
        }
        for (OAPOIType *ps in ((OAPOICategory *) pt).poiTypes)
        {
            [self fillPoiAdditionals:ps allFromCategory:NO];
        }
    }
    else if ([pt isKindOfClass:[OAPOIFilter class]])
    {
        for (OAPOIType *ps in ((OAPOIFilter *) pt).poiTypes)
        {
            [self fillPoiAdditionals:ps allFromCategory:NO];
        }
    }
}

- (void) updatePoiAdditionals
{
    [poiAdditionals removeAllObjects];
    for (OAPOICategory *category in acceptedTypes.keyEnumerator)
    {
        NSMutableSet<NSString *> *set = [acceptedTypes objectForKey:category];
        [self fillPoiAdditionals:category allFromCategory:set == [OAPOIBaseType nullSet]];
        if (set != [OAPOIBaseType nullSet])
        {
            for (NSString *s in set)
            {
                OAPOIType *subtype = [poiHelper getPoiTypeByName:s];
                if (subtype)
                    [self fillPoiAdditionals:subtype allFromCategory:NO];
            }
        }
    }
    [self addOtherPoiAdditionals];
}

- (void) addOtherPoiAdditionals
{
    for (OAPOIType *add in poiHelper.otherMapCategory.poiAdditionalsCategorized)
    {
        [poiAdditionals setObject:add forKey:[[add.name stringByReplacingOccurrencesOfString:@"_" withString:@":"] stringByReplacingOccurrencesOfString:@" " withString:@":"]];
        [poiAdditionals setObject:add forKey:[[add.nameLocalized stringByReplacingOccurrencesOfString:@" " withString:@":"] lowerCase]];
    }
}

- (void) combineWithPoiFilter:(OAPOIUIFilter *)f
{
    [self putAllAcceptedTypes:f.acceptedTypes];

    for (NSString *key in f.poiAdditionals.keyEnumerator)
        [poiAdditionals setObject:[f.poiAdditionals objectForKey:key] forKey:key];
}

- (void) putAllAcceptedTypes:(NSMapTable<OAPOICategory *, NSMutableSet<NSString *> *> *)types
{
    for (OAPOICategory *key in types.keyEnumerator)
    {
        NSMutableSet<NSString *> *typesSet = [types objectForKey:key];
        NSMutableSet<NSString *> *existingTypes = [acceptedTypes objectForKey:key];
        if (existingTypes)
        {
            if (typesSet != nil)
                [existingTypes unionSet:typesSet];
            else
                [acceptedTypes setObject:nil forKey:key];
        }
        else
        {
            if (typesSet != nil)
                [acceptedTypes setObject:[typesSet mutableCopy] forKey:key];
            else
                [acceptedTypes setObject:nil forKey:key];
        }
    }
}

- (void) combineWithPoiFilters:(NSSet<OAPOIUIFilter *> *)filters
{
    for (OAPOIUIFilter *f in filters)
        [self combineWithPoiFilter:f];
}

+ (void) combineStandardPoiFilters:(NSMutableSet<OAPOIUIFilter *> *)filters
{
    NSMutableSet<OAPOIUIFilter *> *standardFilters = [NSMutableSet set];
    for (OAPOIUIFilter *filter in filters)
    {
        if (((filter.isStandardFilter && [filter.filterId hasPrefix:STD_PREFIX])
             || [filter.filterId hasPrefix:CUSTOM_FILTER_ID])
            && !filter.filterByName
            && !filter.savedFilterByName)
        {
            [standardFilters addObject:filter];
        }
    }
    if (standardFilters.count > 1)
    {
        OAPOIUIFilter *standardFiltersCombined = [[OAPOIUIFilter alloc] initWithFiltersToMerge:standardFilters];
        for (OAPOIUIFilter *f in standardFilters)
            [filters removeObject:f];
        
        [filters addObject:standardFiltersCombined];
    }
}

- (void) replaceWithPoiFilter:(OAPOIUIFilter *)f
{
    [self clearFilter];
    [self combineWithPoiFilter:f];
}

- (int) getAcceptedTypesCount
{
    return (int)acceptedTypes.count;
}

- (NSMapTable<OAPOICategory *, NSMutableSet<NSString *> *> *) getAcceptedTypes
{
    return acceptedTypes;
}

- (NSMapTable<OAPOICategory *, NSMutableSet<NSString *> *> *) getAcceptedTypesOrigin
{
    return acceptedTypesOrigin;
}

- (void) selectSubTypesToAccept:(OAPOICategory *)t accept:(NSMutableSet<NSString *> *)accept
{
    [acceptedTypes setObject:accept forKey:t];
    [self updatePoiAdditionals];
    [self updateAcceptedTypeOrigins];
}

- (void) setTypeToAccept:(OAPOICategory *)poiCategory b:(BOOL)b
{
    if (b)
        [acceptedTypes setObject:[OAPOIBaseType nullSet] forKey:poiCategory];
    else
        [acceptedTypes removeObjectForKey:poiCategory];

    [self updatePoiAdditionals];
    [self updateAcceptedTypeOrigins];
}

- (NSMapTable<NSString *, OAPOIType *> *) getPoiAdditionals
{
    return poiAdditionals;
}

- (NSString *) getIconId
{
    if ([filterId hasPrefix:STD_PREFIX])
        return standardIconId;
    else if ([filterId hasPrefix:USER_PREFIX])
        return [[filterId substringFromIndex:USER_PREFIX.length] lowerCase];

    return filterId;
}

- (BOOL) accept:(OAPOICategory *)type subcategory:(NSString *)subcategory
{
    if (!type)
        return YES;

    if (![poiHelper isRegisteredType:type])
        type = poiHelper.otherPoiCategory;

    if ([[acceptedTypes keyEnumerator].allObjects containsObject:type])
    {
        NSMutableSet<NSString *> *acceptedTypesSet = [acceptedTypes objectForKey:type];
        if (!acceptedTypesSet || [acceptedTypesSet containsObject:subcategory])
            return YES;
    }
    if ([[acceptedTypesOrigin keyEnumerator].allObjects containsObject:type])
    {
        NSMutableSet<NSString *> *acceptedTypesSet = [acceptedTypesOrigin objectForKey:type];
        if (acceptedTypesSet || [acceptedTypesSet containsObject:subcategory])
            return YES;
    }
    return NO;
}

- (BOOL) isEmpty
{
    return acceptedTypes.count == 0 && currentSearchResult.count == 0;
}

+ (UIImage *) getUserIcon
{
    UIImage *img = [UIImage imageNamed:[OAUtilities drawablePath:@"mx_user_defined"]];
    return [OAUtilities applyScaleFactorToImage:img];
}

- (BOOL) isEqual:(id)object
{
    if (object == self) {
        return YES;
    } else if ([object isKindOfClass:[OAPOIUIFilter class]]) {
        return [filterId isEqualToString:((OAPOIUIFilter *)object).filterId];
    }
    return NO;
}

- (NSUInteger) hash
{
    return [filterId hash];
}

- (void)updateAcceptedTypeOrigins
{
    NSMapTable<OAPOICategory *, NSMutableSet<NSString *> *> *newAcceptedTypesOrigin = [NSMapTable strongToStrongObjectsMapTable];

    for (OAPOICategory *key in acceptedTypes)
    {
        NSMutableSet<NSString *> *values = [acceptedTypes objectForKey:key];
        if (values)
        {
            for (NSString *s in values)
            {
                OAPOIBaseType *subtype = [[OAPOIHelper sharedInstance] getPoiTypeByKey:s];
                if (subtype)
                {
                    OAPOICategory *c = [(OAPOIFilter *)subtype category];
                    NSString *typeName = subtype.name;
                    NSMutableSet<NSString *> *acceptedSubtypes = [[self getAcceptedSubtypes:c] mutableCopy];
                    if (acceptedSubtypes && ![acceptedSubtypes containsObject:typeName])
                    {
                        NSMutableSet<NSString *> *typeNames = [newAcceptedTypesOrigin objectForKey:c];
                        if (!typeNames)
                        {
                            typeNames = [NSMutableSet new];
                            [newAcceptedTypesOrigin setObject:typeNames forKey:c];
                        }
                        [typeNames addObject:typeName];
                    }
                }
            }
        }
    }
    acceptedTypesOrigin = newAcceptedTypesOrigin;
}

@end
