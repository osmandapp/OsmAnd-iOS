//
//  OAAbbreviations.h
//  OsmAnd Maps
//
//  Created by plotva on 30.04.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//
//  OsmAnd-java/src/main/java/net/osmand/binary/Abbreviations.java
//  git revision /54e26c5a6195beb371c210746c5d89674016b9f7

#ifndef OAAbbreviations_h
#define OAAbbreviations_h

#import <Foundation/Foundation.h>

@interface OAAbbreviations : NSObject

+ (NSString *) replace:(NSString *)word;
+ (NSString *) replaceAll:(NSString *)phrase;

@end

#endif /* OAAbbreviations_h */
