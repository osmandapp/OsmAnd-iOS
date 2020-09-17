//
//  OASearchSettings.h
//  OsmAnd
//
//  Created by Alexey Kulish on 11/01/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//
//  OsmAnd-java/src/net/osmand/search/core/SearchSettings.java
//  git revision 4c2cfb9c97778b99d64fc73ba71dc3cc39ddbfdd

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

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

+ (OASearchSettings *) parseJSON:(NSDictionary *)json;

@end
