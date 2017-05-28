//
//  OASearchPhrase.h
//  OsmAnd
//
//  Created by Alexey Kulish on 11/01/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//
//  OsmAnd-java/src/net/osmand/search/core/SearchPhrase.java
//  git revision 5da5d0d41d977acc31473eb7051b4ff0f4f8d118

#import <Foundation/Foundation.h>
#import "OANameStringMatcher.h"
#import "OAObjectType.h"
#import <CoreLocation/CoreLocation.h>
#import "OASearchResult.h"

#include <OsmAndCore/Data/DataCommonTypes.h>

typedef NS_ENUM(NSInteger, EOASearchPhraseDataType)
{
    P_DATA_TYPE_MAP = 0,
    P_DATA_TYPE_ADDRESS,
    P_DATA_TYPE_ROUTING,
    P_DATA_TYPE_POI
};

@class OASearchSettings, OASearchPhrase, QuadRect, OASearchWord;

@interface OASearchPhrase : NSObject

- (instancetype)initWithSettings:(OASearchSettings *)settings;

- (OASearchPhrase *) generateNewPhrase:(NSString *)text settings:(OASearchSettings *)settings;
- (NSMutableArray<OASearchWord *> *) getWords;
- (BOOL) isUnknownSearchWordComplete;
- (BOOL) isLastUnknownSearchWordComplete;
- (NSMutableArray<NSString *> *) getUnknownSearchWords;
- (NSMutableArray<NSString *> *) getUnknownSearchWords:(NSSet<NSString *> *)exclude;
- (NSString *) getUnknownSearchWord;
- (NSString *) getUnknownSearchPhrase;
- (BOOL) isUnknownSearchWordPresent;
- (int) getUnknownSearchWordLength;
- (QuadRect *) getRadiusBBoxToSearch:(int)radius;
- (QuadRect *) get1km31Rect;
- (OASearchSettings *) getSettings;
- (int) getRadiusLevel;
- (OASearchPhrase *) selectWord:(OASearchResult *)res;
- (OASearchPhrase *) selectWord:(OASearchResult *)res unknownWords:(NSArray<NSString *> *)unknownWords lastComplete:(BOOL)lastComplete;
- (BOOL) isLastWord:(EOAObjectType)p;
- (OAObjectType *) getExclusiveSearchType;
- (OANameStringMatcher *) getNameStringMatcher;
- (OANameStringMatcher *) getNameStringMatcher:(NSString *)word complete:(BOOL)complete;
- (BOOL) hasObjectType:(EOAObjectType)p;
- (void) syncWordsWithResults;
- (NSString *) getText:(BOOL)includeLastWord;
- (NSString *) getTextWithoutLastWord;
- (NSString *) getStringRerpresentation;
- (NSString *) toString;
- (BOOL) isNoSelectedType;
- (BOOL) isEmpty;
- (OASearchWord *) getLastSelectedWord;
- (CLLocation *) getWordLocation;
- (CLLocation *) getLastTokenLocation;
- (void) countUnknownWordsMatch:(OASearchResult *)sr;
- (void) countUnknownWordsMatch:(OASearchResult *)sr localeName:(NSString *)localeName otherNames:(NSMutableArray<NSString *> *)otherNames;
- (int) getRadiusSearch:(int)meters;
- (NSArray<OAObjectType *> *) getSearchTypes;
- (BOOL) isCustomSearch;
- (BOOL) isSearchTypeAllowed:(EOAObjectType)searchType;
- (BOOL) isEmptyQueryAllowed;
- (BOOL) isSortByName;
- (BOOL) isInAddressSearch;
- (NSString *) getUnknownWordToSearchBuilding;
- (NSString *) getUnknownWordToSearch;

- (NSArray<NSString *> *) getRadiusOfflineIndexes:(int)meters dt:(EOASearchPhraseDataType)dt;
- (NSArray<NSString *> *) getOfflineIndexes:(QuadRect *)rect dt:(EOASearchPhraseDataType)dt;
- (NSArray<NSString *> *) getOfflineIndexes;

- (void) selectFile:(NSString *)resourceId;
- (void) sortFiles;

+ (NSComparisonResult) icompare:(int)x y:(int)y;


@end
