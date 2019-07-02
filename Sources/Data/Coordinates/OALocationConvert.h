//
//  OALocationConvert.h
//  OsmAnd
//
//  Created by Paul on 6/29/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OALocationConvert : NSObject

+ (double) convert:(NSString *)coordinate;
+ (NSString *) convert:(double) coordinate outputType:(NSInteger)outputType;
+ (NSString *) convertLatitude:(double) latitude outputType:(NSInteger)outType addCardinalDirection:(BOOL)addCardinalDirection;
+ (NSString *) convertLongitude:(double) longitude outputType:(NSInteger)outType addCardinalDirection:(BOOL)addCardinalDirection;

@end

