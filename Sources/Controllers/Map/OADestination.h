//
//  OADestination.h
//  OsmAnd
//
//  Created by Alexey Kulish on 01/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OADestination : NSObject <NSCoding>

@property (nonatomic) NSString *desc;
@property (nonatomic) UIColor *color;
@property (nonatomic) double latitude;
@property (nonatomic) double longitude;
@property (nonatomic) NSString *markerResourceName;

@property (nonatomic) NSInteger index;

@property (nonatomic) BOOL hidden;
@property (nonatomic) BOOL manual;

@property (nonatomic) NSDate *creationDate;

- (instancetype)initWithDesc:(NSString *)desc latitude:(double)latitude longitude:(double)longitude;
- (double) distance:(double)latitude longitude:(double)longitude;
- (NSString *) distanceStr:(double)latitude longitude:(double)longitude;

@end
