//
//  OATspAnt.h
//  OsmAnd
//
//  Created by Alexey Kulish on 20/07/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface OATspAnt : NSObject

+ (NSMutableArray *)createBoolArray:(NSInteger)length;
+ (NSMutableArray *)createIntArray:(NSInteger)length;
+ (NSMutableArray *)createDoubleArray:(NSInteger)length;

- (void)readGraph:(NSArray *)intermediates  start:(CLLocation *)start end:(CLLocation *)end;
- (NSArray *)solve;

@end
