//
//  OASearchUICore.m
//  OsmAnd
//
//  Created by Alexey Kulish on 11/01/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//
//  OsmAnd-java/src/net/osmand/search/core/SearchUICore.java
//  git revision 5bcaa01259c937fa29741117b23f89776a1098c6

#import "OASearchUICore.h"

#import "OASearchPhrase.h"
#import "OASearchWord.h"
#import "OASearchSettings.h"
#import "OAAtomicInteger.h"
#import "OASearchCoreAPI.h"
#import "OAPOIHelper.h"
#import "OAUtilities.h"
#import "OASearchResultMatcher.h"
#import "OASearchCoreFactory.h"
#import "OACustomSearchPoiFilter.h"
#import "OAPOIBaseType.h"
#import "OAStreet.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/ICU.h>

static const int SEARCH_PRIORITY_COEF = 10;
static const double TIMEOUT_BETWEEN_CHARS = 0.7;  // seconds
static const double TIMEOUT_BEFORE_SEARCH = 0.05; // seconds
static const double TIMEOUT_BEFORE_FILTER = 0.02; // seconds
static const int DEPTH_TO_CHECK_SAME_SEARCH_RESULTS = 20;
static const NSSet<NSString *> *FILTER_DUPLICATE_POI_SUBTYPE = [NSSet setWithArray: @[@"building", @"internet_access_yes"]];

typedef NS_ENUM(NSInteger, EOAResultCompareStep) {
    EOATopVisible = 0,
    EOAFoundWordCount, // more is better (top)
    EOAUnknownPhraseMatchWeight, // more is better (top)
    EOACompareAmenityTypeAdditional,
    EOASearchDistanceIfNotByName,
    EOACompareFirstNumberInName,
    EOACompareDistanceToParentSearchResult, // makes sense only for inner subqueries
    EOACompareByName,
    EOACompareByDistance,
    EOAAmenityLastAndSortBySubtype
};

@interface OASearchUICore ()

@end

const static NSArray<NSNumber *> *compareStepValues = @[@(EOATopVisible), @(EOAFoundWordCount), @(EOAUnknownPhraseMatchWeight),
                                                         @(EOACompareAmenityTypeAdditional), @(EOASearchDistanceIfNotByName), @(EOACompareFirstNumberInName),
                                                         @(EOACompareDistanceToParentSearchResult), @(EOACompareByName), @(EOACompareByDistance), @(EOAAmenityLastAndSortBySubtype)];

@interface OASearchResultComparator ()

@property (nonatomic) NSComparator comparator;
@property (nonatomic) OASearchPhrase *phrase;
@property (nonatomic) CLLocation *loc;
@property (nonatomic) BOOL sortByName;

@end

@implementation OASearchResultComparator

- (instancetype) initWithPhrase:(OASearchPhrase *)phrase
{
    self = [super init];
    if (self)
    {
        _phrase = phrase;
        _loc = [phrase getLastTokenLocation];
        _sortByName = [phrase isSortByName];
    
        __weak OASearchResultComparator *weakSelf = self;
        _comparator = ^NSComparisonResult(OASearchResult * _Nonnull o1, OASearchResult * _Nonnull o2)
        {
            for(NSNumber *stepN in compareStepValues)
            {
                EOAResultCompareStep step = (EOAResultCompareStep) stepN.integerValue;
                NSComparisonResult r = [weakSelf compare:o1 o2:o2 comparator:weakSelf step:step];
                if(r != NSOrderedSame)
                {
                    return r;
                }
            }
            return NSOrderedSame;
        };
    }
    return self;
}

// -1 - means 1st is less (higher) than 2nd
-(NSComparisonResult) compare:(OASearchResult *)o1 o2:(OASearchResult *)o2 comparator:(OASearchResultComparator *)c step:(EOAResultCompareStep)step
{
    switch(step)
    {
        case EOATopVisible:
        {
            BOOL topVisible1 = [OAObjectType isTopVisible:o1.objectType];
            BOOL topVisible2 = [OAObjectType isTopVisible:o2.objectType];
            if (topVisible1 != topVisible2)
            {
                // NSOrderedAscending - means 1st is less than 2nd
                return topVisible1 ? NSOrderedAscending : NSOrderedDescending;
            }
            break;
        }
        case EOAFoundWordCount:
        {
            if (o1.getFoundWordCount != o2.getFoundWordCount)
            {
                return [OAUtilities compareInt:o2.getFoundWordCount y:o1.getFoundWordCount];
            }
            break;
        }
        case EOAUnknownPhraseMatchWeight:
        {
            // here we check how much each sub search result matches the phrase
            // also we sort it by type house -> street/poi -> city/postcode/village/other
            
            OASearchPhrase *ph = o1.requiredSearchPhrase;
            double o1PhraseWeight = o1.unknownPhraseMatchWeight;
            double o2PhraseWeight = o2.unknownPhraseMatchWeight;
            if (o1PhraseWeight == o2PhraseWeight && o1PhraseWeight / SEARCH_PRIORITY_COEF > 1)
            {
                if (!![[ph getUnknownWordToSearchBuildingNameMatcher] matches:o1.localeName])
                    o1PhraseWeight--;
                if (![[ph getUnknownWordToSearchBuildingNameMatcher] matches:o2.localeName])
                    o2PhraseWeight--;
            }
            
            if (o1.unknownPhraseMatchWeight != o2.unknownPhraseMatchWeight)
            {
                return [OAUtilities compareDouble:o2.unknownPhraseMatchWeight y:o1.unknownPhraseMatchWeight];
            }
            break;
        }
        case EOASearchDistanceIfNotByName:
        {
            if (!c.sortByName) {
                double s1F = [o1 getSearchDistanceFloored:c.loc];
                double s2F = [o2 getSearchDistanceFloored:c.loc];
                double s1R = [o1 getSearchDistanceRound:c.loc];
                double s2R = [o2 getSearchDistanceRound:c.loc];
                if (s1F == s2F || s1R == s2R)
                    break;
                else
                    return [OAUtilities compareDouble:fmax(s1F, s1R) y:fmax(s2F, s2R)];
            }
            break;
        }
        case EOACompareFirstNumberInName:
        {
            NSString *localeName1 = o1.localeName == nil ? @"" : o1.localeName;
            NSString *localeName2 = o2.localeName == nil ? @"" : o2.localeName;
            int st1 = [OAUtilities extractFirstIntegerNumber:localeName1];
            int st2 = [OAUtilities extractFirstIntegerNumber:localeName2];
            if (st1 != st2)
                return [OAUtilities compareInt:st1 y:st2];
            break;
        }
        case EOACompareAmenityTypeAdditional:
        {
            if([o1.object isKindOfClass:OAPOIBaseType.class] && [o2.object isKindOfClass:OAPOIBaseType.class]) {
                BOOL additional1 = ((OAPOIBaseType *) o1.object).isAdditional;
                BOOL additional2 = ((OAPOIBaseType *) o2.object).isAdditional;
                if (additional1 != additional2)
                {
                    // NSOrderedAscending - means 1st is less than 2nd
                    return additional1 ? NSOrderedDescending : NSOrderedAscending;
                }
            }
            break;
        }
        case EOACompareDistanceToParentSearchResult:
        {
            double s1F = o1.parentSearchResult == nil ? 0 : [o1.parentSearchResult getSearchDistanceFloored:c.loc];
            double s2F = o2.parentSearchResult == nil ? 0 : [o2.parentSearchResult getSearchDistanceFloored:c.loc];
            double s1R = o1.parentSearchResult == nil ? 0 : [o1.parentSearchResult getSearchDistanceRound:c.loc];
            double s2R = o2.parentSearchResult == nil ? 0 : [o2.parentSearchResult getSearchDistanceRound:c.loc];
            if (s1F == s2F || s1R == s2R)
                break;
            else
                return [OAUtilities compareDouble:fmax(s1F, s1R) y:fmax(s2F, s2R)];
        }
        case EOACompareByName:
        {
            NSString *localeName1 = o1.localeName == nil ? @"" : o1.localeName;
            NSString *localeName2 = o2.localeName == nil ? @"" : o2.localeName;
            int cmp = OsmAnd::ICU::ccompare(QString::fromNSString(localeName1), QString::fromNSString(localeName2));
            if (cmp != 0)
                return (NSComparisonResult)cmp;
            break;
        }
        case EOACompareByDistance:
        {
            double s1F = [o1 getSearchDistanceFloored:c.loc pd:1];
            double s2F = [o2 getSearchDistanceFloored:c.loc pd:1];
            double s1R = [o1 getSearchDistanceRound:c.loc pd:1];
            double s2R = [o2 getSearchDistanceRound:c.loc pd:1];
            if (s1F == s2F || s1R == s2R)
                break;
            else
                return [OAUtilities compareDouble:fmax(s1F, s1R) y:fmax(s2F, s2R)];
        }
        case EOAAmenityLastAndSortBySubtype:
        {
            BOOL am1 = std::dynamic_pointer_cast<const OsmAnd::Amenity>(o1.amenity) != nullptr;
            BOOL am2 = std::dynamic_pointer_cast<const OsmAnd::Amenity>(o2.amenity) != nullptr;
            if (am1 != am2)
            {
                return am1 ? NSOrderedDescending : NSOrderedAscending;
            }
            else if (am1 && am2)
            {
                // here 2 points are amenity
                const auto& a1 = std::dynamic_pointer_cast<const OsmAnd::Amenity>(o1.amenity);
                const auto& a2 = std::dynamic_pointer_cast<const OsmAnd::Amenity>(o2.amenity);
                
                NSComparisonResult cmp = NSOrderedSame;
                BOOL subtypeFilter1 = [FILTER_DUPLICATE_POI_SUBTYPE containsObject:a1->subType.toNSString()];
                BOOL subtypeFilter2 = [FILTER_DUPLICATE_POI_SUBTYPE containsObject:a2->subType.toNSString()];
                if (subtypeFilter1 != subtypeFilter2)
                {
                    // to filter second
                    return subtypeFilter1 ? NSOrderedDescending : NSOrderedAscending;
                }
                
                cmp = (NSComparisonResult)OsmAnd::ICU::ccompare(a1->type, a2->type);
                if (cmp != NSOrderedSame)
                    return cmp;
                
                cmp = (NSComparisonResult)OsmAnd::ICU::ccompare(a1->subType, a2->subType);
                if (cmp != NSOrderedSame)
                    return cmp;
            }
            break;
        }
    }
    return NSOrderedSame;
}

@end


@interface OASearchResultCollection ()

@end

@implementation OASearchResultCollection
{
    NSMutableArray<OASearchResult *> *_searchResults;
}

- (instancetype)initWithPhrase:(OASearchPhrase *)phrase
{
    self = [super init];
    if (self)
    {
        _searchResults = [NSMutableArray array];
        _phrase = phrase;
        
    }
    return self;
}

- (NSMutableArray<OASearchResult *> *) getSearchResults
{
    return _searchResults;
}

- (OASearchResultCollection *) combineWithCollection:(OASearchResultCollection *)collection resort:(BOOL)resort removeDuplicates:(BOOL)removeDuplicates
{
    OASearchResultCollection *src = [[OASearchResultCollection alloc] initWithPhrase:_phrase];
    [src addSearchResults:_searchResults resortAll:false removeDuplicates:false];
    [src addSearchResults:[collection getSearchResults] resortAll:resort removeDuplicates:removeDuplicates];
    return src;
}

- (OASearchResultCollection *) addSearchResults:(NSArray<OASearchResult *> *)sr resortAll:(BOOL)resortAll removeDuplicates:(BOOL)removeDuplicates
{
    if (resortAll)
    {
        [_searchResults addObjectsFromArray:sr];
        [self sortSearchResults];
        if (removeDuplicates)
            [self filterSearchDuplicateResults];
    }
    else
    {
        if (!removeDuplicates)
        {
            [_searchResults addObjectsFromArray:sr];
        }
        else
        {
            NSMutableArray<OASearchResult *> *addedResults = [NSMutableArray arrayWithArray:sr];
            OASearchResultComparator *cmp = [[OASearchResultComparator alloc] initWithPhrase:_phrase];
            [addedResults sortUsingComparator:cmp.comparator];
            [self filterSearchDuplicateResults:addedResults];
            int i = 0;
            int j = 0;
            while(j < addedResults.count)
            {
                OASearchResult *addedResult = addedResults[j];
                if (i >= _searchResults.count)
                {
                    int k = 0;
                    bool same = false;
                    while (_searchResults.count > k && k < DEPTH_TO_CHECK_SAME_SEARCH_RESULTS)
                    {
                        if ([self sameSearchResult:addedResult r2:_searchResults[_searchResults.count - k - 1]])
                        {
                            same = true;
                            break;
                        }
                        k++;
                    }
                    if (!same)
                        [_searchResults addObject:addedResult];
                    
                    j++;
                    continue;
                }
                OASearchResult *existingResult = _searchResults[i];
                if ([self sameSearchResult:addedResult r2:existingResult])
                {
                    j++;
                    continue;
                }
                int compare = cmp.comparator(existingResult, addedResult);
                if (compare == 0)
                {
                    // existingResult == addedResult
                    j++;
                }
                else if(compare > 0)
                {
                    // existingResult > addedResult
                    [_searchResults addObject:addedResults[j]];
                    j++;
                }
                else
                {
                    // existingResult < addedResult
                    i++;
                }
            }
        }
    }
    return self;
}

- (NSArray<OASearchResult *> *) getCurrentSearchResults
{
    return [NSArray arrayWithArray:_searchResults];
}

- (void) sortSearchResults
{
    OASearchResultComparator *cmp = [[OASearchResultComparator alloc] initWithPhrase:_phrase];
    [_searchResults sortUsingComparator:cmp.comparator];
}

- (void) filterSearchDuplicateResults
{
    [self filterSearchDuplicateResults:_searchResults];
}

- (void) filterSearchDuplicateResults:(NSMutableArray<OASearchResult *> *)lst
{
    NSMutableArray<OASearchResult *> *remove = [NSMutableArray array];
    NSMutableArray<OASearchResult *> *lstUnique = [NSMutableArray array];
    for (OASearchResult *r in lst)
    {
        bool same = false;
        for (OASearchResult *rs in lstUnique)
        {
            same = [self sameSearchResult:rs r2:r];
            if (same)
                break;
        }
        if (same)
        {
            [remove addObject:r];
        }
        else
        {
            [lstUnique addObject:r];
            if (lstUnique.count > DEPTH_TO_CHECK_SAME_SEARCH_RESULTS)
                [lstUnique removeObjectAtIndex:0];
        }
    }
    [lst removeObjectsInArray:remove];
}

- (BOOL) sameSearchResult:(OASearchResult *)r1 r2:(OASearchResult *)r2
{
    if (r1.location && r2.location && ![OAObjectType isTopVisible:r1.objectType] && ![OAObjectType isTopVisible:r2.objectType])
    {
        if (r1.objectType == r2.objectType && r1.objectType == STREET)
        {
            OAStreet *st1 = (OAStreet *) r1.object;
            OAStreet *st2 = (OAStreet *) r2.object;
            
            return fabs(st1.latitude - st2.latitude) < 0.00001 && fabs(st1.longitude - st2.longitude) < 0.00001;
        }
        std::shared_ptr<const OsmAnd::Amenity> a1;
        if (r1.objectType == POI)
            a1 = r1.amenity;

        std::shared_ptr<const OsmAnd::Amenity> a2;
        if (r2.objectType == POI)
            a2 = r2.amenity;

        if ([r1.localeName isEqualToString:r2.localeName])
        {
            double similarityRadius = 30;
            if (a1 && a2)
            {
                // here 2 points are amenity
                BOOL isEqualId = a1->id.id == a2->id.id;
                if (isEqualId && ([FILTER_DUPLICATE_POI_SUBTYPE containsObject:a1->subType.toNSString()] || [FILTER_DUPLICATE_POI_SUBTYPE containsObject:a2->subType.toNSString()]))
                    return true;
                else if (a1->type != a2->type)
                    return false;
                
                if (a1->type == QStringLiteral("natural"))
                {
                    similarityRadius = 50000;
                }
                else if (a1->subType == a2->subType)
                {
                    if (a1->subType.contains(QStringLiteral("cn_ref")) || a1->subType.contains(QStringLiteral("wn_ref"))
                        || (a1->subType.startsWith(QStringLiteral("route_hiking_")) && a1->subType.endsWith(QStringLiteral("n_poi"))))
                    {
                        similarityRadius = 50000;
                    }
                }
            }
            else if([OAObjectType isAddress:r1.objectType] && [OAObjectType isAddress:r2.objectType])
            {
                similarityRadius = 100;
            }
            return [r1.location distanceFromLocation:r2.location] < similarityRadius;
        }
    }
    else if (r1.object && r2.object)
    {
        return r1.object == r2.object;
    }
    return false;
}

@end


@implementation OASearchUICore
{
    OASearchPhrase *_phrase;
    OASearchResultCollection *_currentSearchResult;
    
    dispatch_queue_t _taskQueue;
    OAAtomicInteger *_requestNumber;
    int totalLimit; // -1 unlimited - not used
    
    NSMutableArray<OASearchCoreAPI *> *_apis;
    OASearchSettings *_searchSettings;
    OAPOIHelper *_poiTypes;
}

- (instancetype)initWithLang:(NSString *)lang transliterate:(BOOL)transliterate
{
    self = [super init];
    if (self)
    {
        _taskQueue = dispatch_queue_create("OASearchUICore_taskQueue", DISPATCH_QUEUE_SERIAL);
        _requestNumber = [OAAtomicInteger atomicInteger:0];
        totalLimit = -1;
        _apis = [NSMutableArray array];
        _poiTypes = [OAPOIHelper sharedInstance];
        
        _searchSettings = [[OASearchSettings alloc] init];
        _searchSettings = [_searchSettings setLang:lang transliterateIfMissing:transliterate];
        _phrase = [OASearchPhrase emptyPhrase:_searchSettings];
        _currentSearchResult = [[OASearchResultCollection alloc] initWithPhrase:_phrase];
    }
    return self;
}

- (OASearchCoreAPI *) getApiByClass:(Class)cl
{
    for (OASearchCoreAPI *a in _apis)
        if ([a isKindOfClass:cl])
            return a;

    return nil;
}

- (OASearchResultCollection *) shallowSearch:(Class)cl text:(NSString *)text matcher:(OAResultMatcher<OASearchResult *> *)matcher
{
    return [self shallowSearch:cl text:text matcher:matcher resortAll:YES removeDuplicates:YES];
}

- (OASearchResultCollection *) shallowSearch:(Class)cl text:(NSString *)text matcher:(OAResultMatcher<OASearchResult *> *)matcher resortAll:(BOOL)resortAll removeDuplicates:(BOOL)removeDuplicates
{
    OASearchCoreAPI *api = [self getApiByClass:cl];
    if (api)
    {
        OASearchPhrase *sphrase = [_phrase generateNewPhrase:text settings:_searchSettings];
        [self preparePhrase:sphrase];
        OAAtomicInteger *ai = [OAAtomicInteger atomicInteger:0];
        OASearchResultMatcher *rm = [[OASearchResultMatcher alloc] initWithMatcher:matcher phrase:sphrase request:[ai get] requestNumber:ai totalLimit:totalLimit];
        [api search:sphrase resultMatcher:rm];
        
        OASearchResultCollection *collection = [[OASearchResultCollection alloc] initWithPhrase:sphrase];
        [collection addSearchResults:[rm getRequestResults] resortAll:resortAll removeDuplicates:removeDuplicates];

        NSLog(@">> Shallow Search phrase %@ %d", [_phrase toString], (int)([rm getRequestResults].count));

        return collection;
    }
    return nil;
}

- (OASearchResultCollection *) searchAmenity:(NSString *)text matcher:(OAResultMatcher<OASearchResult *> *)matcher resortAll:(BOOL)resortAll removeDuplicates:(BOOL)removeDuplicates
{
    OASearchAddressByNameAPI *api = (OASearchAddressByNameAPI *)[self getApiByClass:OASearchAmenityByNameAPI.class];
    if (api)
    {
        OASearchPhrase *sphrase = [_phrase generateNewPhrase:text settings:_searchSettings];
        [self preparePhrase:sphrase];
        OAAtomicInteger *ai = [OAAtomicInteger atomicInteger:0];
        OASearchResultMatcher *rm = [[OASearchResultMatcher alloc] initWithMatcher:matcher phrase:sphrase request:[ai get] requestNumber:ai totalLimit:totalLimit];
        [api search:sphrase fullArea:YES resultMatcher:rm];
        
        OASearchResultCollection *collection = [[OASearchResultCollection alloc] initWithPhrase:sphrase];
        [collection addSearchResults:[rm getRequestResults] resortAll:resortAll removeDuplicates:removeDuplicates];

        return collection;
    }
    return nil;
}

- (void) initApi
{
    [_apis addObject:[[OASearchLocationAndUrlAPI alloc] init]];
    OASearchAmenityTypesAPI *searchAmenityTypesAPI = [[OASearchAmenityTypesAPI alloc] init];
    [_apis addObject:searchAmenityTypesAPI];
    [_apis addObject:[[OASearchAmenityByTypeAPI alloc] initWithTypesAPI:searchAmenityTypesAPI]];
    [_apis addObject:[[OASearchAmenityByNameAPI alloc] init]];
    OASearchBuildingAndIntersectionsByStreetAPI *streetsApi = [[OASearchBuildingAndIntersectionsByStreetAPI alloc] init];
    [_apis addObject:streetsApi];
    OASearchStreetByCityAPI *cityApi = [[OASearchStreetByCityAPI alloc] initWithAPI:streetsApi];
    [_apis addObject:cityApi];
    [_apis addObject:[[OASearchAddressByNameAPI alloc] initWithCityApi:cityApi streetsApi:streetsApi]];
}

- (void) clearCustomSearchPoiFilters
{
    for (OASearchCoreAPI *capi in _apis)
        if ([capi isKindOfClass:[OASearchAmenityTypesAPI class]])
            [((OASearchAmenityTypesAPI *) capi) clearCustomFilters];
}

- (void) addCustomSearchPoiFilter:(OACustomSearchPoiFilter *)poiFilter  priority:(int)priority
{
    for (OASearchCoreAPI *capi in _apis)
        if ([capi isKindOfClass:[OASearchAmenityTypesAPI class]])
            [((OASearchAmenityTypesAPI *) capi) addCustomFilter:poiFilter priority:priority];
}

- (void) setActivePoiFiltersByOrder:(NSArray<NSString *> *)filterOrders
{
    for (OASearchCoreAPI *capi : _apis)
    {
        if ([capi isKindOfClass:[OASearchAmenityTypesAPI class]])
            [((OASearchAmenityTypesAPI *) capi) setActivePoiFiltersByOrder:filterOrders];
    }
}

- (void) registerAPI:(OASearchCoreAPI *)api
{
    [_apis addObject:api];
}


- (OASearchResultCollection *) getCurrentSearchResult
{
    return _currentSearchResult;
}

- (OASearchPhrase *) getPhrase
{
    return _phrase;
}

- (OASearchSettings *) getSearchSettings
{
    return _searchSettings;
}

- (void) updateSettings:(OASearchSettings *)settings
{
    _searchSettings = settings;
}

- (void) filterCurrentResults:(OASearchPhrase *)phrase matcher:(OAResultMatcher<OASearchResult *> *)matcher
{
    if (!matcher)
        return;
    
    NSArray<OASearchResult *> *l = [_currentSearchResult getSearchResults];
    for (OASearchResult *r in l)
    {
        if ([self filterOneResult:r phrase:phrase])
            [matcher publish:r];
        
        if ([matcher isCancelled])
            return;
    }
}

- (BOOL) filterOneResult:(OASearchResult *)object phrase:(OASearchPhrase *)phrase
{
    OANameStringMatcher *nameStringMatcher = [phrase getFirstUnknownNameStringMatcher];
    return [nameStringMatcher matches:object.localeName] || [nameStringMatcher matchesMap:object.otherNames];
}

- (BOOL) selectSearchResult:(OASearchResult *)r
{
    _phrase = [_phrase selectWord:r];
    return YES;
}

- (OASearchPhrase *) resetPhrase
{
    _phrase = [_phrase generateNewPhrase:@"" settings:_searchSettings];
    return _phrase;
}

- (OASearchPhrase *) resetPhrase:(NSString *)text
{
    _phrase = [_phrase generateNewPhrase:text settings:_searchSettings];
    return _phrase;
}

- (void) cancelSearch
{
    [_requestNumber incrementAndGet];
}

- (void) search:(NSString *)text delayedExecution:(BOOL)delayedExecution matcher:(OAResultMatcher<OASearchResult *> *)matcher
{
    int request = [_requestNumber incrementAndGet];
    OASearchPhrase *phrase = [_phrase generateNewPhrase:text settings:_searchSettings];
    _phrase = phrase;
    NSLog(@"> Search phrase %@", [_phrase toString]);
    
    dispatch_async(_taskQueue, ^{
        try
        {
            if (_onSearchStart)
                _onSearchStart();
            
            OASearchResultMatcher *rm = [[OASearchResultMatcher alloc] initWithMatcher:matcher phrase:phrase request:request requestNumber:_requestNumber totalLimit:totalLimit];
            [rm searchStarted:phrase];
            if (delayedExecution)
            {
                NSTimeInterval startTime = CACurrentMediaTime();
                BOOL filtered = NO;
                while (CACurrentMediaTime() - startTime <= TIMEOUT_BETWEEN_CHARS)
                {
                    if ([rm isCancelled])
                        return;
                    
                    [NSThread sleepForTimeInterval:TIMEOUT_BEFORE_FILTER];
                    
                    if (!filtered)
                    {
                        OASearchResultCollection *quickRes = [[OASearchResultCollection alloc] initWithPhrase:phrase];
                        [self filterCurrentResults:phrase matcher:[[OAResultMatcher alloc] initWithPublishFunc:^BOOL(OASearchResult *__autoreleasing *searchResult) {
                            [[quickRes getSearchResults] addObject:*searchResult];
                            return YES;
                        } cancelledFunc:^BOOL{
                            return [rm isCancelled];
                        }]];
                        
                        if (![rm isCancelled])
                        {
                            _currentSearchResult = quickRes;
                            [rm filterFinished:phrase];
                        }
                        filtered = YES;
                    }
                }
            }
            else
            {
                [NSThread sleepForTimeInterval:TIMEOUT_BEFORE_SEARCH];
            }
            
            if ([rm isCancelled])
                return;
            
            [self searchInBackground:phrase matcher:rm];
            if (![rm isCancelled])
            {
                OASearchResultCollection *collection = [[OASearchResultCollection alloc] initWithPhrase:phrase];
                [collection addSearchResults:[rm getRequestResults] resortAll:YES removeDuplicates:YES];
                NSLog(@">> Search phrase %@ %d", [phrase toString], (int)([rm getRequestResults].count));
                _currentSearchResult = collection;
                [rm searchFinished:phrase];
                if (_onResultsComplete)
                    _onResultsComplete();
            }
        }
        catch (NSException *e)
        {
            NSLog(@"OASearchUICore.search error %@", e);
        }
    });
}

- (BOOL) isSearchMoreAvailable:(OASearchPhrase *)phrase
{
    for (OASearchCoreAPI *api in _apis)
        if ([api isSearchAvailable:phrase] && [api getSearchPriority:phrase] >= 0 && [api isSearchMoreAvailable:phrase])
            return YES;

    return NO;
}

- (int) getMinimalSearchRadius:(OASearchPhrase *)phrase
{
    int radius = INT_MAX;
    for (OASearchCoreAPI *api in _apis)
    {
        if ([api isSearchAvailable:phrase] && [api getSearchPriority:phrase] != -1)
        {
            int apiMinimalRadius = [api getMinimalSearchRadius:phrase];
            if (apiMinimalRadius > 0 && apiMinimalRadius < radius)
                radius = apiMinimalRadius;
        }
    }
    return radius;
}

- (int) getNextSearchRadius:(OASearchPhrase *)phrase
{
    int radius = INT_MAX;
    for (OASearchCoreAPI *api in _apis)
    {
        if ([api isSearchAvailable:phrase] && [api getSearchPriority:phrase] != -1)
        {
            int apiNextSearchRadius = [api getNextSearchRadius:phrase];
            if (apiNextSearchRadius > 0 && apiNextSearchRadius < radius)
                radius = apiNextSearchRadius;
        }
    }
    return radius;
}
    
- (OAPOIBaseType *) getUnselectedPoiType
{
    for (OASearchCoreAPI *capi in _apis)
    {
        if ([capi isKindOfClass:OASearchAmenityByTypeAPI.class]) {
            return [((OASearchAmenityByTypeAPI *) capi) getUnselectedPoiType];
        }
    }
    return nil;
}

- (NSString *) getCustomNameFilter
{
    for (OASearchCoreAPI *capi : _apis)
    {
        if ([capi isKindOfClass:OASearchAmenityByTypeAPI.class]) {
            return [((OASearchAmenityByTypeAPI *) capi) getNameFilter];
        }
    }
    return nil;
}

- (void) searchInBackground:(OASearchPhrase *)phrase matcher:(OASearchResultMatcher *)matcher
{
    [self preparePhrase:phrase];
    NSMutableArray<OASearchCoreAPI *> *lst = [NSMutableArray arrayWithArray:_apis];
    [lst sortUsingComparator:^NSComparisonResult(OASearchCoreAPI * _Nonnull o1, OASearchCoreAPI * _Nonnull o2) {
        return [OAUtilities compareInt:[o1 getSearchPriority:phrase] y:[o2 getSearchPriority:phrase]];
    }];

    for (OASearchCoreAPI *api in lst)
    {
        if ([matcher isCancelled])
            break;
        
        if (![api isSearchAvailable:phrase] || [api getSearchPriority:phrase] == -1)
            continue;
        
        try
        {
            [api search:phrase resultMatcher:matcher];
            
            if (![matcher isCancelled])
                [matcher apiSearchFinished:api phrase:phrase];
        }
        catch (NSException *e)
        {
            NSLog(@"OASearchUICore.searchInBackground error %@", e);
        }
    }
}

- (void) preparePhrase:(OASearchPhrase *)phrase
{
    for (OASearchWord *sw in [phrase getWords])
        if (sw.result && sw.result.resourceId)
            [phrase selectFile:sw.result.resourceId];

    [phrase sortFiles];
}

@end
