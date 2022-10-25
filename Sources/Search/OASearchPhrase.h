//
//  OASearchPhrase.h
//  OsmAnd
//
//  Created by Alexey Kulish on 11/01/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//
//  OsmAnd-java/src/net/osmand/search/core/SearchPhrase.java
//  git revision aea6f3ff8842b91fda4b471e24015e4142c52d13

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

@class OASearchSettings, OASearchPhrase, QuadRect, OASearchWord, OAPOIBaseType;

@interface OASearchPhrase : NSObject

+ (OASearchPhrase *) emptyPhrase;
+ (OASearchPhrase *) emptyPhrase:(OASearchSettings *)settings;

- (OASearchPhrase *) generateNewPhrase:(NSString *)text settings:(OASearchSettings *)settings;
- (NSMutableArray<OASearchWord *> *) getWords;
- (int) countWords:(NSString *)word;

- (BOOL) isMainUnknownSearchWordComplete;
- (BOOL) isLastUnknownSearchWordComplete;
- (BOOL) hasMoreThanOneSearchWord;

- (NSMutableArray<NSString *> *) getUnknownSearchWords;
- (NSString *) getFirstUnknownSearchWord;
- (BOOL) isFirstUnknownSearchWordComplete;

- (NSString *) getFullSearchPhrase;
- (NSString *) getUnknownSearchPhrase;
- (BOOL) isUnknownSearchWordPresent;

- (QuadRect *) getRadiusBBoxToSearch:(int)radius;
- (QuadRect *) get1km31Rect;
- (OASearchSettings *) getSettings;
- (int) getRadiusLevel;

- (OASearchPhrase *) selectWord:(OASearchResult *)res;
- (OASearchPhrase *) selectWord:(OASearchResult *)res unknownWords:(NSArray<NSString *> *)unknownWords lastComplete:(BOOL)lastComplete;
- (BOOL) isLastWord:(EOAObjectType)p;
- (OAObjectType *) getExclusiveSearchType;

- (BOOL) hasObjectType:(EOAObjectType)p;
- (void) syncWordsWithResults;

- (NSString *) getText:(BOOL)includeUnknownPart;
- (NSString *) getTextWithoutLastWord;
- (NSString *) getStringRerpresentation;
- (NSString *) toString;

- (BOOL) isNoSelectedType;
- (BOOL) isEmpty;

- (OASearchWord *) getLastSelectedWord;
- (CLLocation *) getWordLocation;
- (CLLocation *) getLastTokenLocation;
- (NSString *) getLastUnknownSearchWord;
- (NSInteger) countUnknownWordsMatchMainResult:(OASearchResult *)sr;
- (NSInteger) countUnknownWordsMatchMainResult:(OASearchResult *) sr matchingWordsCount:(NSInteger)matchingWordsCount;
- (NSInteger) countUnknownWordsMatch:(OASearchResult *)sr localeName:(NSString *)localeName otherNames:(NSMutableArray<NSString *> *)otherNames matchingWordsCount:(NSInteger)matchingWordsCount;

- (int) getRadiusSearch:(int)meters;
- (int) getNextRadiusSearch:(int) meters;

- (NSArray<OAObjectType *> *) getSearchTypes;
- (BOOL) isCustomSearch;
- (BOOL) isSearchTypeAllowed:(EOAObjectType)searchType;
- (BOOL) isSearchTypeAllowed:(EOAObjectType)searchType exclusive:(BOOL)exclusive;
- (BOOL) isEmptyQueryAllowed;
- (BOOL) isSortByName;
- (BOOL) isInAddressSearch;

- (OANameStringMatcher *) getMainUnknownNameStringMatcher;
- (OANameStringMatcher *) getFirstUnknownNameStringMatcher;
- (OANameStringMatcher *) getUnknownNameStringMatcher;
- (OANameStringMatcher *) getFullNameStringMatcher;
- (OANameStringMatcher *) getUnknownWordToSearchBuildingNameMatcher;

- (NSString *) getUnknownWordToSearchBuilding;
- (NSString *) getUnknownWordToSearch;

- (NSArray<NSString *> *) getRadiusOfflineIndexes:(int)meters dt:(EOASearchPhraseDataType)dt;
- (NSArray<NSString *> *) getOfflineIndexes:(QuadRect *)rect dt:(EOASearchPhraseDataType)dt;
- (NSArray<NSString *> *) getOfflineIndexes;

- (void) selectFile:(NSString *)resourceId;
- (void) sortFiles;

- (BOOL) hasMoreThanOneUnknownSearchWord;

+ (NSComparisonResult) icompare:(int)x y:(int)y;

+ (OAPOIBaseType*) unselectedPoiType;
+ (NSMutableArray<NSString *> *) splitWords:(NSString *)w ws:(NSMutableArray<NSString *> *)ws delimiters:(NSString *)delimiters;

- (OAPOIBaseType *) getUnselectedPoiType;
- (void) setUnselectedPoiType:(OAPOIBaseType *)unselectedPoiType;
+ (NSString *) getDelimiter;


@end
