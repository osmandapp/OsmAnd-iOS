//
//  OADestinationsListViewController+cpp.h
//  OsmAnd
//
//  Created by Skalii on 07.09.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OADestinationItem, OATableDataModel;

@interface OADistanceAndDirectionsUpdater : NSObject

+ (void)updateDistanceAndDirections:(OATableDataModel *)data
                         indexPaths:(NSArray<NSIndexPath *> *)indexPaths
                            itemKey:(NSString *)itemKey;

+ (CGFloat)directionAngleFromLocation:(CLLocation *)currentLocation
                toDestinationLatitude:(CGFloat)destinationLatitude
                 destinationLongitude:(CGFloat)destinationLongitude;

+ (CGFloat)directionAngleFromLocation:(CLLocation *)sourceLocation
                      sourceDirection:(CLLocationDirection)sourceDirection
                toDestinationLatitude:(CGFloat)destinationLatitude
                 destinationLongitude:(CGFloat)destinationLongitude;

+ (CGFloat)distanceFromLocation:(CLLocation *)currentLocation
          toDestinationLatitude:(CGFloat)destinationLatitude
           destinationLongitude:(CGFloat)destinationLongitude;

@end
