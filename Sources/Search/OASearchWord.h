//
//  OASearchWord.h
//  OsmAnd
//
//  Created by Alexey Kulish on 11/01/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//
//  revision 878491110c391829cc1f42eace8dc582cb35e08e

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
