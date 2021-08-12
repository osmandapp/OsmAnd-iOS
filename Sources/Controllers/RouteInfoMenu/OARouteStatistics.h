//
//  OARouteStatistics.h
//  OsmAnd
//
//  Created by Paul on 18.12.2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OARouteSegmentAttribute : NSObject

@property (nonatomic, readonly) NSInteger color;
@property (nonatomic, readonly) NSString *propertyName;
@property (nonatomic, readonly) NSInteger slopeIndex;
@property (nonatomic) float distance;
@property (nonatomic) NSString *userPropertyName;

- (instancetype) initWithPropertyName:(NSString *) propertyName color:(NSInteger) color slopeIndex:(NSInteger) slopeIndex boundariesClass:(NSArray<NSString *> *)boundariesClass;
- (instancetype) initWithSegmentAttribute:(OARouteSegmentAttribute *) segmentAttribute;
    
- (NSString *) getUserPropertyName;
- (void) incrementDistanceBy:(float) distance;
- (NSString *) toNSString;

@end

@interface OARouteStatistics : NSObject

@property (nonatomic, readonly) NSArray<OARouteSegmentAttribute *> *elements;
@property (nonatomic, readonly) NSDictionary<NSString *, OARouteSegmentAttribute *> *partition;
@property (nonatomic, readonly) float totalDistance;
@property (nonatomic, readonly) NSString *name;

- (instancetype) initWithName:(NSString *)name elements:(NSArray<OARouteSegmentAttribute *> *)elements partition:(NSDictionary<NSString *, OARouteSegmentAttribute *> *) partition totalDistance:(float)totalDistance;

- (NSString *) toNSString;

@end
