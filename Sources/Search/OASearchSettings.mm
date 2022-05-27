//
//  OASearchSettings.m
//  OsmAnd
//
//  Created by Alexey Kulish on 11/01/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OASearchSettings.h"
#import "OAObjectType.h"
#import "OAMapUtils.h"

#define MIN_DISTANCE_REGION_LANG_RECALC 10000.0

@interface OASearchSettings ()

@property (nonatomic) int pRadiusLevel;
@property (nonatomic) CLLocation *pOriginalLocation;
@property (nonatomic) OAWorldRegion *pRegions;
@property (nonatomic) NSString *pRegionLang;
@property (nonatomic) int pTotalLimit;
@property (nonatomic) NSString *pLang;
@property (nonatomic) BOOL pTransliterateIfMissing;
@property (nonatomic) NSArray<OAObjectType *> *pSearchTypes;
@property (nonatomic) BOOL pEmptyQueryAllowed;
@property (nonatomic) BOOL pSortByName;
@property (nonatomic) BOOL pAddressSearch;

@end

@implementation OASearchSettings
{
    NSArray<NSString *> *_resourceIds;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.pRadiusLevel = 1;
        self.pTotalLimit = -1;
    }
    return self;
}

- (instancetype)initWithSettings:(OASearchSettings *)s
{
    self = [self init];
    if (self)
    {
        if (s)
        {
            self.pRadiusLevel = s.pRadiusLevel;
            self.pLang = s.pLang;
            self.pTransliterateIfMissing = s.pTransliterateIfMissing;
            self.pTotalLimit = s.pTotalLimit;
            self.pOriginalLocation = s.pOriginalLocation;
            self.pRegions = s.pRegions;
            self.pRegionLang = s.pRegionLang;
            [self setOfflineIndexes:[s getOfflineIndexes]];
            if (s.pSearchTypes)
                self.pSearchTypes = [NSArray arrayWithArray:s.pSearchTypes];
            self.pEmptyQueryAllowed = s.pEmptyQueryAllowed;
            self.pSortByName = s.pSortByName;
            self.pAddressSearch = s.pAddressSearch;
        }
    }
    return self;
}

- (instancetype)initWithIndexes:(NSArray<NSString *> *)resourceIds;
{
    self = [self init];
    if (self)
    {
        [self setOfflineIndexes:resourceIds];
    }
    return self;
}

- (NSArray<NSString *> *) getOfflineIndexes;
{
    return _resourceIds;
}

- (void) setOfflineIndexes:(NSArray<NSString *> *)resourceIds;
{
    _resourceIds = resourceIds;
}

- (int) getRadiusLevel
{
    return self.pRadiusLevel;
}

- (NSString *) getLang
{
    return self.pLang;
}

- (OASearchSettings *) setLang:(NSString *)lang transliterateIfMissing:(BOOL)transliterateIfMissing
{
    OASearchSettings *s = [[OASearchSettings alloc] initWithSettings:self];
    s.pLang = lang;
    s.pTransliterateIfMissing = transliterateIfMissing;
    return s;
}

- (OASearchSettings *) setRadiusLevel:(int)radiusLevel
{
    OASearchSettings *s = [[OASearchSettings alloc] initWithSettings:self];
    s.pRadiusLevel = radiusLevel;
    return s;
}

- (int) getTotalLimit
{
    return self.pTotalLimit;
}

- (OASearchSettings *) setTotalLimit:(int)totalLimit
{
    OASearchSettings *s = [[OASearchSettings alloc] initWithSettings:self];
    s.pTotalLimit = totalLimit;
    return s;
}

- (CLLocation *) getOriginalLocation
{
    return self.pOriginalLocation;
}

- (OASearchSettings *) setOriginalLocation:(CLLocation *)l
{
    OASearchSettings *s = [[OASearchSettings alloc] initWithSettings:self];
    double distance = _pOriginalLocation == nil ? -1 :  [OAMapUtils getDistance:l.coordinate second:_pOriginalLocation.coordinate];
    s.pRegionLang = (distance > MIN_DISTANCE_REGION_LANG_RECALC || distance == -1 || !_pRegionLang ) ? [self calculateRegionLang:l] : _pRegionLang;
    s.pOriginalLocation = l;
    return s;
}

- (BOOL) isTransliterate
{
    return self.pTransliterateIfMissing;
}

- (NSArray<OAObjectType *> *)getSearchTypes
{
    return self.pSearchTypes;
}

- (BOOL) isCustomSearch
{
    return self.pSearchTypes != nil;
}

- (OASearchSettings *) setSearchTypes:(NSArray<OAObjectType *> *)searchTypes
{
    OASearchSettings *s = [[OASearchSettings alloc] initWithSettings:self];
    s.pSearchTypes = searchTypes;
    return s;
}

- (OASearchSettings *) resetSearchTypes
{
    OASearchSettings *s = [[OASearchSettings alloc] initWithSettings:self];
    s.pSearchTypes = nil;
    return s;
}

- (BOOL) isEmptyQueryAllowed
{
    return self.pEmptyQueryAllowed;
}

- (OASearchSettings *) setEmptyQueryAllowed:(BOOL)emptyQueryAllowed
{
    OASearchSettings *s = [[OASearchSettings alloc] initWithSettings:self];
    s.pEmptyQueryAllowed = emptyQueryAllowed;
    return s;
}

- (BOOL) isSortByName
{
    return self.pSortByName;
}

- (OASearchSettings *) setSortByName:(BOOL)sortByName
{
    OASearchSettings *s = [[OASearchSettings alloc] initWithSettings:self];
    s.pSortByName = sortByName;
    return s;
}

- (BOOL) isInAddressSearch
{
    return self.pAddressSearch;
}

- (OASearchSettings *) setAddressSearch:(BOOL)addressSearch
{
    OASearchSettings *s = [[OASearchSettings alloc] initWithSettings:self];
    s.pAddressSearch = addressSearch;
    return s;
}

- (NSString *) getRegionLang
{
    return _pRegionLang;
}

- (OAWorldRegion *)getRegions
{
    return _pRegions;
}

- (void) setRegions:(OAWorldRegion *)regions
{
    _pRegions = regions;
}

- (NSString *) calculateRegionLang:(CLLocation *)l
{
    OAWorldRegion *region = [_pRegions findAtLat:l.coordinate.latitude lon:l.coordinate.longitude];
    if (region)
    {
        return region.regionLang;
    }
    return nil;
}

+ (OASearchSettings *) parseJSON:(NSDictionary *)json
{
    OASearchSettings *s = [[OASearchSettings alloc] initWithIndexes:@[]];
    if (json[@"lat"] && json[@"lon"])
    {
        s.pOriginalLocation = [[CLLocation alloc] initWithLatitude:[json[@"lat"] doubleValue] longitude:[json[@"lon"] doubleValue]];
    }
    s.pRadiusLevel = [json[@"radiusLevel"] intValue];
    s.pTotalLimit = [json[@"totalLimit"] intValue];
    s.pTransliterateIfMissing = [json[@"transliterateIfMissing"] boolValue];
    s.pEmptyQueryAllowed = [json[@"emptyQueryAllowed"] boolValue];
    s.pSortByName = [json[@"sortByName"] boolValue];
    if (json[@"lang"])
        s.pLang = json[@"lang"];
    if (json[@"regionLang"])
        s.pRegionLang = json[@"regionLang"];
    
    if (json[@"searchTypes"])
    {
        NSArray *searchTypesArr = json[@"searchTypes"];
        NSMutableArray<OAObjectType *> *searchTypes = [NSMutableArray new];
        for (NSInteger i = 0; i < searchTypesArr.count; i++)
        {
            NSString *name = searchTypesArr[i];
            searchTypes[i] = [OAObjectType valueOf:name];
        }
        s.pSearchTypes = searchTypes;
    }
    return s;
}

@end
