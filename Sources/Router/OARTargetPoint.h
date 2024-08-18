//
//  OARTargetPoint.h
//  OsmAnd
//
//  Created by Alexey Kulish on 16/07/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OALocationPoint.h"

@class OAPointDescription;

@interface OARTargetPoint : NSObject<NSCoding, OALocationPoint>

@property (nonatomic) CLLocation *point;
@property (nonatomic, readonly) OAPointDescription *pointDescription;
@property (nonatomic) int index;
@property (nonatomic) BOOL intermediate;
@property (nonatomic) BOOL start;

- (instancetype) initWithPoint:(CLLocation *)point name:(OAPointDescription *)name;
- (instancetype) initWithPoint:(CLLocation *)point name:(OAPointDescription *)name index:(int)index;

- (NSString *) getOnlyName;
- (BOOL) isSearchingAddress;

+ (OARTargetPoint *) create:(CLLocation *)point name:(OAPointDescription *)name;
+ (OARTargetPoint *) createStartPoint:(CLLocation *)point name:(OAPointDescription *)name;

@end
