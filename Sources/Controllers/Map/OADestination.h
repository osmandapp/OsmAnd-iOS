//
//  OADestination.h
//  OsmAnd
//
//  Created by Alexey Kulish on 01/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OADestination : NSObject

@property (nonatomic) NSString *desc;
@property (nonatomic) UIColor *color;
@property (nonatomic) double latitude;
@property (nonatomic) double longitude;

- (instancetype)initWithDesc:(NSString *)desc latitude:(double)latitude longitude:(double)longitude;
- (NSString *) distanceStr:(double)latitude longitude:(double)longitude;

@end
