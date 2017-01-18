//
//  OASearchSettings.h
//  OsmAnd
//
//  Created by Alexey Kulish on 11/01/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//
//  revision 878491110c391829cc1f42eace8dc582cb35e08e

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "OASearchResult.h"

@interface OASearchSettings : NSObject

- (instancetype)initWithSettings:(OASearchSettings *)s;
- (instancetype)initWithIndexes:(QList<std::shared_ptr<LocalResource>>)offlineIndexes;

- (QList<std::shared_ptr<LocalResource>>) getOfflineIndexes;
- (void) setOfflineIndexes:(QList<std::shared_ptr<LocalResource>>)offlineIndexes;

- (int) getRadiusLevel;
- (NSString *) getLang;
- (OASearchSettings *) setLang:(NSString *)lang transliterateIfMissing:(BOOL)transliterateIfMissing;
- (OASearchSettings *) setRadiusLevel:(int)radiusLevel;
- (int) getTotalLimit;
- (OASearchSettings *) setTotalLimit:(int)totalLimit;
- (CLLocation *) getOriginalLocation;
- (OASearchSettings *) setOriginalLocation:(CLLocation *)l;
- (BOOL) isTransliterate;


@end
