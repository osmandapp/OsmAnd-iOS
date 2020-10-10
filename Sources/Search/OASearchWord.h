//
//  OASearchWord.h
//  OsmAnd
//
//  Created by Alexey Kulish on 11/01/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//
//  OsmAnd-java/src/main/java/net/osmand/search/core/SearchWord.java
//  git revision db3b280a26eaf721222ec918e8c0baf4dca9b1fd

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "OAObjectType.h"

@class OASearchResult;

@interface OASearchWord : NSObject

@property (nonatomic, readonly) NSString *word;
@property (nonatomic, readonly) OASearchResult *result;


- (instancetype)initWithWord:(NSString *)word res:(OASearchResult *)res;

- (EOAObjectType) getType;
- (void) syncWordWithResult;
- (CLLocation *) getLocation;
- (NSString  *) toString;

@end
