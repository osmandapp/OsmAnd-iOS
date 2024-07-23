//
//  OAPOIUIFilter.m
//  OsmAnd
//
//  Created by Alexey Kulish on 21/12/2016.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OAPOIUIFilter.h"
#import "OAAmenityExtendedNameFilter.h"
#import "OAPOI.h"
#import "OAPOICategory.h"
#import "OAPOIType.h"
#import "OAPOIHelper.h"
#import "OsmAndApp.h"
#import "Localization.h"
#import "OAPOIFiltersHelper.h"
#import "OAPOIFilter.h"
#import "OAResultMatcher.h"
#import "OAMapUtils.h"
#import "OAUtilities.h"
#import "OANameStringMatcher.h"
#import "OAOsmAndFormatter.h"
#import "OASvgHelper.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>
#include <openingHoursParser.h>
#include <OsmAndCore/Data/ObfPoiSectionInfo.h>
#include <OsmAndCore/Data/ObfMapObject.h>

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
    return [self.filterId hasPrefix:[NSString stringWithFormat:@"%@%@", STD_PREFIX, WIKI_PLACE]] || [self isTopWikiFilter];
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
    if (!filter || filter.length == 0)
    {
        return [[OAAmenityNameFilter alloc] initWithAcceptFunc:^BOOL(OAPOI *poi) {
            return YES;
        }];
    }
    NSMutableArray<NSString *> *unknownFilters = [NSMutableArray array];
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
                [unknownFilters addObject:s];
            }
        }
    }
    return [self getNameFilterInternal:unknownFilters allTime:allTime open:open poiAdditionals:poiAdditionalsFilter];
}

- (OAAmenityExtendedNameFilter *) getNameAmenityFilter:(NSString *)filter
{
    if (filter.length == 0)
    {
        return [[OAAmenityExtendedNameFilter alloc] initWithAcceptAmenityFunc:^BOOL(std::shared_ptr<const OsmAnd::Amenity> amenity, QHash<QString, QString> values, OAPOIType *type) {
            return YES;
        }];
    }
    NSMutableArray<NSString *> *unknownFilters = [NSMutableArray array];
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
                [unknownFilters addObject:s];
            }
        }
    }
    return [self getNameAmenityFilterInternal:unknownFilters allTime:allTime open:open poiAdditionals:poiAdditionalsFilter];
}

- (OAAmenityNameFilter *) getNameFilterInternal:(NSArray<NSString *> *)unknownFilters
                                        allTime:(BOOL)allTime
                                           open:(BOOL)open
                                 poiAdditionals:(NSArray<OAPOIType *> *)selectedFilters
{
    return [[OAAmenityNameFilter alloc] initWithAcceptFunc:^BOOL(OAPOI *amenity) {
        if (allTime)
        {
            if (!amenity.openingHours
                    || (![@"24/7" isEqualToString:amenity.openingHours]&& ![@"Mo-Su 00:00-24:00" isEqualToString:amenity.openingHours]))
                return NO;
        }

        if (open)
        {
            if (!amenity.openingHours)
            {
                return NO;
            }
            else
            {
                auto parser = OpeningHoursParser::parseOpenedHours([amenity.openingHours UTF8String]);
                if (!parser || !parser->isOpened())
                    return NO;
            }
        }

        NSString *nameFilter = [self extractNameFilterForPoi:amenity unknownFilters:unknownFilters];
        if (![self matchesAnyName:amenity nameFilter:nameFilter])
            return NO;

        return [self acceptedAnyFilterOfEachCategory:amenity selectedFilters:selectedFilters];
    }];
}

- (OAAmenityExtendedNameFilter *) getNameAmenityFilterInternal:(NSArray<NSString *> *)unknownFilters
                                               allTime:(BOOL)allTime
                                                  open:(BOOL)open
                                        poiAdditionals:(NSArray<OAPOIType *> *)selectedFilters
{
    return [[OAAmenityExtendedNameFilter alloc] initWithAcceptAmenityFunc:^BOOL(std::shared_ptr<const OsmAnd::Amenity> amenity, QHash<QString, QString> values, OAPOIType *type) {
        
        auto openingHours = values[QString::fromNSString(OPENING_HOURS_TAG)];
        if (allTime)
        {
            if (openingHours.isNull() || (openingHours != QStringLiteral("24/7") && openingHours != QStringLiteral("Mo-Su 00:00-24:00")) )
                return NO;
        }
        
        if (open)
        {
            if (openingHours.isNull())
            {
                return NO;
            }
            else
            {
                auto parser = OpeningHoursParser::parseOpenedHours(openingHours.toStdString());
                if (!parser || !parser->isOpened())
                    return NO;
            }
        }
        
        NSString *nameFilter = [self extractNameFilter:amenity unknownFilters:unknownFilters];
        if (![self matchesAnyAmenityName:amenity type:type nameFilter:nameFilter])
            return NO;
        
        return [self acceptedAmeintyAnyFilterOfEachCategory:amenity values:values selectedFilters:selectedFilters];
    }];
}

- (BOOL) matchesAnyName:(OAPOI *)amenity nameFilter:(NSString *)nameFilter
{
    if (nameFilter.length == 0)
        return YES;
    
    OANameStringMatcher *sm = [[OANameStringMatcher alloc] initWithNamePart:[nameFilter trim] mode:CHECK_CONTAINS];
    
    NSString *lower = [poiHelper getPoiStringWithoutType:amenity];
    return [sm matches:lower] || [sm matchesMap:amenity.localizedNames.allValues];
}

- (BOOL) matchesAnyAmenityName:(const std::shared_ptr<const OsmAnd::Amenity> &)amenity type:(OAPOIType *)type nameFilter:(NSString *)nameFilter
{
    if (nameFilter.length == 0)
        return YES;
    
    OANameStringMatcher *sm = [[OANameStringMatcher alloc] initWithNamePart:[nameFilter trim] mode:CHECK_CONTAINS];
    
    
    NSString *name = amenity->nativeName.toNSString();;
    NSString *typeName = [[OAPOIHelper sharedInstance] getPhrase:type];
    NSString *poiStringWithoutType;

    if (typeName && [name indexOf:typeName] != -1)
    {
        poiStringWithoutType = name;
    }
    if (name.length == 0)
        poiStringWithoutType = typeName;
    poiStringWithoutType = [NSString stringWithFormat:@"%@ %@", typeName, name];

    NSMutableArray *names = [NSMutableArray array];
    for (const auto& entry : OsmAnd::rangeOf(amenity->localizedNames))
    {
        [names addObject:entry.value().toNSString()];
    }

    return [sm matches:poiStringWithoutType] || [sm matchesMap:names];
}

- (NSString *) extractNameFilterForPoi:(OAPOI *)amenity unknownFilters:(NSArray<NSString *> *)unknownFilters
{
    if (!unknownFilters)
        return @"";
    
    NSMutableString *nameFilter = [NSMutableString string];
    for (NSString *filter in unknownFilters)
    {
        NSString *formattedFilter = [filter stringByReplacingOccurrencesOfString:@":" withString:@"_"].lowerCase;
        if (!amenity.getAdditionalInfo[formattedFilter])
        {
            [nameFilter appendString:filter];
            [nameFilter appendString:@" "];
        }
    }
    return nameFilter;
}

- (NSString *) extractNameFilter:(const std::shared_ptr<const OsmAnd::Amenity> &)amenity unknownFilters:(NSArray<NSString *> *)unknownFilters
{
    if (!unknownFilters)
        return @"";
    
    NSMutableString *nameFilter = [NSMutableString string];
    NSMutableDictionary *additionalInfo = [NSMutableDictionary dictionary];
    [OAPOIHelper processDecodedValues:amenity->getDecodedValues() content:nil values:additionalInfo];
    for (NSString *filter in unknownFilters)
    {
        NSString *formattedFilter = [filter stringByReplacingOccurrencesOfString:@":" withString:@"_"].lowerCase;
        if (!additionalInfo[formattedFilter])
        {
            [nameFilter appendString:filter];
            [nameFilter appendString:@" "];
        }
    }
    
    return nameFilter;
}

- (BOOL)acceptedAnyFilterOfEachCategory:(OAPOI *)amenity
                        selectedFilters:(NSArray<OAPOIType *> *)selectedFilters
{
    if (!selectedFilters)
        return YES;

    NSMutableDictionary<NSString *, NSMutableArray<OAPOIType *> *> *filterCategories = [NSMutableDictionary dictionary];
    NSMapTable <OAPOIType *, OAPOIType *> *textFilters = [NSMapTable strongToStrongObjectsMapTable];

    [self fillFilterCategories:selectedFilters filterCategories:filterCategories textFilters:textFilters];

    for (NSMutableArray<OAPOIType *> *category in filterCategories.allValues)
    {
        if (![self acceptedAnyFilterOfCategory:amenity category:category textFilters:textFilters])
            return NO;
    }

    return YES;
}

- (BOOL)acceptedAmeintyAnyFilterOfEachCategory:(std::shared_ptr<const OsmAnd::Amenity>)amenity
                                        values:(QHash<QString, QString>)values
                        selectedFilters:(NSArray<OAPOIType *> *)selectedFilters
{
    if (!selectedFilters)
        return YES;

    NSMutableDictionary<NSString *, NSMutableArray<OAPOIType *> *> *filterCategories = [NSMutableDictionary dictionary];
    NSMapTable <OAPOIType *, OAPOIType *> *textFilters = [NSMapTable strongToStrongObjectsMapTable];

    [self fillFilterCategories:selectedFilters filterCategories:filterCategories textFilters:textFilters];

    for (NSMutableArray<OAPOIType *> *category in filterCategories.allValues)
    {
        if (![self acceptedAmenityAnyFilterOfCategory:amenity values:values category:category textFilters:textFilters])
            return NO;
    }

    return YES;
}

- (void)fillFilterCategories:(NSArray<OAPOIType *> *)selectedFilters
            filterCategories:(NSMutableDictionary<NSString *, NSMutableArray<OAPOIType *> *> *)filterCategories
                 textFilters:(NSMapTable <OAPOIType *, OAPOIType *> *)textFilters
{
    for (OAPOIType *filter in selectedFilters)
    {
        NSString *category = filter.poiAdditionalCategory;
        NSMutableArray<OAPOIType *> *filtersOfCategory = filterCategories[category ? category : @""];
        if (!filtersOfCategory)
        {
            filtersOfCategory = [NSMutableArray array];
            filterCategories[category ? category : @""] = filtersOfCategory;
        }
        [filtersOfCategory addObject:filter];

        NSString *osmTag = [filter getOsmTag];
        if (osmTag.length < filter.name.length)
        {
            OAPOIType *textFilter = [poiHelper getTextPoiAdditionalByKey:osmTag];
            if (!textFilter)
                [textFilters setObject:textFilter forKey:filter];
        }
    }
}

- (BOOL)acceptedAnyFilterOfCategory:(OAPOI *)amenity
                           category:(NSMutableArray<OAPOIType *> *)category
                        textFilters:(NSMapTable <OAPOIType *, OAPOIType *> *)textFilters
{
    for (OAPOIType *filter in category)
    {
        if ([self acceptedFilter:amenity filter:filter textFilterCategories:textFilters])
            return YES;
    }

    return NO;
}

- (BOOL)acceptedAmenityAnyFilterOfCategory:(std::shared_ptr<const OsmAnd::Amenity>)amenity
                                    values:(QHash<QString, QString>)values
                           category:(NSMutableArray<OAPOIType *> *)category
                        textFilters:(NSMapTable <OAPOIType *, OAPOIType *> *)textFilters
{
    for (OAPOIType *filter in category)
    {
        if ([self acceptedAmenityFilter:amenity values:values filter:filter textFilterCategories:textFilters])
            return YES;
    }

    return NO;
}

- (BOOL)acceptedFilter:(OAPOI *)amenity
                filter:(OAPOIType *)filter
  textFilterCategories:(NSMapTable <OAPOIType *, OAPOIType *> *)textFilterCategories
{
    NSString *filterValue = [amenity getAdditionalInfo][filter.name];

    if (filterValue)
        return YES;

    OAPOIType *textPoiType = [textFilterCategories objectForKey:filter];
    if (!textPoiType)
        return NO;

    filterValue = [amenity getAdditionalInfo][textPoiType.name];
    if (!filterValue || filterValue.length == 0)
        return NO;

    NSArray<NSString *> *items = [filterValue componentsSeparatedByString:@";"];
    NSString *val = [[filter getOsmValue] trim].lowercaseString;
    for (NSString *item in items)
    {
        if ([[item trim].lowercaseString isEqualToString:val])
            return YES;
    }

    return NO;
}

- (BOOL)acceptedAmenityFilter:(std::shared_ptr<const OsmAnd::Amenity>)amenity
                       values:(QHash<QString, QString>)values
                filter:(OAPOIType *)filter
  textFilterCategories:(NSMapTable <OAPOIType *, OAPOIType *> *)textFilterCategories
{
    QString filterName = QString::fromNSString(filter.name);
    QString filterValue = values[filterName];
    if (filterValue != nullptr)
        return YES;
    
    OAPOIType *textPoiType = [textFilterCategories objectForKey:filter];
    if (!textPoiType)
        return NO;
    
    filterName = QString::fromNSString(textPoiType.name);
    filterValue = values[filterName];
    
    if (filterValue == nullptr || filterValue.size() == 0)
        return NO;
    
    QStringList items = filterValue.split(";");
    QString val = QString::fromNSString([[filter getOsmValue] trim].lowercaseString);
    for (int i = 0; i < items.length(); i++)
    {
        if (items.value(i).trimmed().toLower() == val)
            return YES;
    }
    
    return NO;
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
    NSString *iconName;
    if ([filterId hasPrefix:STD_PREFIX])
        iconName = standardIconId;
    else if ([filterId hasPrefix:USER_PREFIX])
        iconName = [[filterId substringFromIndex:USER_PREFIX.length] lowerCase];
    if ([OASvgHelper hasMxMapImageNamed:iconName])
    {
        return iconName;
    }
    else
    {
        iconName = [self.class getCustomFilterIconName:self];
        return iconName && [OASvgHelper hasMxMapImageNamed:iconName] ? iconName : filterId;
    }
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
    return [UIImage svgImageNamed:@"map-icons-svg/mx_user_defined"];
}

+ (NSString *)getCustomFilterIconName:(OAPOIUIFilter *)filter
{
    if (filter)
    {
        NSMapTable<OAPOICategory *, NSMutableSet<NSString *> *> *acceptedTypes = [filter getAcceptedTypes];
        NSArray<OAPOICategory *> *categories = acceptedTypes.keyEnumerator.allObjects;
        if (categories.count == 1)
        {
            OAPOICategory *category = categories[0];
            NSMutableSet<NSString *> *filters = [acceptedTypes objectForKey:category];
            if (!filters || filters.count > 1)
                return [category iconName];
            else
                return [self getPoiTypeIconName:[category getPoiTypeByKeyName:filters.allObjects.firstObject]];
        }
    }
    return nil;
}

+ (NSString *)getPoiTypeIconName:(OAPOIBaseType *)abstractPoiType
{
    if (abstractPoiType != nil && [OASvgHelper hasMxMapImageNamed:abstractPoiType.iconName])
    {
        return abstractPoiType.iconName;
    }
    else if ([abstractPoiType isKindOfClass:OAPOIType.class])
    {
        OAPOIType *poiType = (OAPOIType *) abstractPoiType;
        NSString *iconId = [NSString stringWithFormat:@"%@_%@", poiType.getOsmTag, poiType.getOsmValue];
        if ([OASvgHelper hasMxMapImageNamed:iconId])
            return iconId;
        else if (poiType.parent != nil)
            return [self getPoiTypeIconName:poiType.parent.type];
    }
    return nil;
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
