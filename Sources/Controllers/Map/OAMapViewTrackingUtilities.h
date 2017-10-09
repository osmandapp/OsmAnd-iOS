//
//  OAMapViewTrackingUtilities.h
//  OsmAnd
//
//  Created by Alexey Kulish on 25/08/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OAMapViewTrackingUtilities : NSObject

@property (nonatomic, readonly) BOOL isMapLinkedToLocation;

+ (OAMapViewTrackingUtilities *)instance;

- (void) switchToRoutePlanningMode;

@end
