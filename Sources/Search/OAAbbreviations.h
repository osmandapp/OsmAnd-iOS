//
//  OAAbbreviations.h
//  OsmAnd Maps
//
//  Created by plotva on 30.04.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//
//  OsmAnd-java/src/main/java/net/osmand/binary/Abbreviations.java
//  git revision 383f15bc221f56ee5a60072f8226898221c20076

#import <Foundation/Foundation.h>

@interface OAAbbreviations : NSObject

+ (BOOL) likelyPartOfRef:(NSString *)word wordSplit:(NSSet<NSString *> *)wordSplit;
+ (BOOL) likelyPartOfBuilding:(NSString *)word wordSplit:(NSSet<NSString *> *)wordSplit;
+ (NSDictionary<NSString *, NSString *> *) getSearchAbbreviations;
+ (BOOL) isCommonSkipOtherCnt:(NSString *)lowerCase;
+ (NSString *) replace:(NSString *)word;
+ (NSString *) replaceAll:(NSString *)phrase;
+ (NSDictionary<NSString *, NSString *> *) getAbbreviations;
+ (BOOL) isConjunction:(NSString *)lowerCase;

@end
