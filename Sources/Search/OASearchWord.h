//
//  OASearchWord.h
//  OsmAnd
//
//  Created by Alexey Kulish on 11/01/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//
//  OsmAnd-java/src/net/osmand/search/core/SearchWord.java
//  git revision 5da5d0d41d977acc31473eb7051b4ff0f4f8d118

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
