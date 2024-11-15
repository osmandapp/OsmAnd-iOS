//
//  OAFileNameTranslationHelper.h
//  OsmAnd
//
//  Created by Alexey Kulish on 02/09/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSString *WORLD_SEAMARKS_KEY = @"world_seamarks";
static NSString *WORLD_SEAMARKS_OLD_KEY = @"world_seamarks_basemap";

@interface OAFileNameTranslationHelper : NSObject

+ (NSString *) getFileNameWithRegion:(NSString *)fileName;
+ (NSString *) getFileName:(NSString *)fileName divider:(NSString *)divider includingParent:(BOOL)includingParent reversed:(BOOL)reversed;
+ (NSString *) getTerrainName:(NSString *)basename terrainName:(NSString *)terrainName;
+ (NSString *) getWikiName:(NSString *)basename;
+ (NSString *) getWikivoyageName:(NSString *)basename;
+ (NSString *) getWeatherName:(NSString *)basename;
+ (NSString *) getVoiceName:(NSString *)fileName;
+ (NSArray<NSString *> *) getVoiceNames:(NSArray *)languageCodes;
+ (NSString *) getBasename:(NSString *)fileName;

+ (NSString *) getMapName:(NSString *)fileName;
+ (NSString *) getStandardMapName:(NSString *)basename;

@end
