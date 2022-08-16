//
//  OASearchSettings.h
//  OsmAnd
//
//  Created by Alexey Kulish on 11/01/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//
//  OsmAnd-java/src/net/osmand/search/core/SearchSettings.java
//  git revision d9a90a3ae40bcdee0c7ffde2a9fd860665ac95ba

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "OAWorldRegion.h"

@class OAObjectType;

@interface OASearchSettings : NSObject

- (instancetype)initWithSettings:(OASearchSettings *)s;
- (instancetype)initWithIndexes:(NSArray<NSString *> *)resourceIds;

- (NSArray<NSString *> *) getOfflineIndexes;
- (void) setOfflineIndexes:(NSArray<NSString *> *)resourceIds;

- (int) getRadiusLevel;
- (NSString *) getLang;
- (OASearchSettings *) setLang:(NSString *)lang transliterateIfMissing:(BOOL)transliterateIfMissing;
- (OASearchSettings *) setRadiusLevel:(int)radiusLevel;
- (int) getTotalLimit;
- (OASearchSettings *) setTotalLimit:(int)totalLimit;
- (CLLocation *) getOriginalLocation;
- (OASearchSettings *) setOriginalLocation:(CLLocation *)l;
- (QuadRect *) getSearchBBox31;
- (OASearchSettings *) setSearchBBox31:(QuadRect *)searchBBox31;
- (BOOL) isTransliterate;

- (NSArray<OAObjectType *> *)getSearchTypes;
- (BOOL) isCustomSearch;
- (OASearchSettings *) setSearchTypes:(NSArray<OAObjectType *> *)searchTypes;
- (OASearchSettings *) resetSearchTypes;
- (BOOL) isEmptyQueryAllowed;
- (OASearchSettings *) setEmptyQueryAllowed:(BOOL)emptyQueryAllowed;
- (BOOL) isSortByName;
- (OASearchSettings *) setSortByName:(BOOL)sortByName;
- (BOOL) isInAddressSearch;
- (OASearchSettings *) setAddressSearch:(BOOL)addressSearch;
- (NSString *) getRegionLang;
- (OAWorldRegion *)getRegions;
- (void) setRegions:(OAWorldRegion *)regions;

+ (OASearchSettings *) parseJSON:(NSDictionary *)json;

@end
