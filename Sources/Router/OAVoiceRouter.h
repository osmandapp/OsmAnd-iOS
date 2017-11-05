//
//  OAVoiceRouter.h
//  OsmAnd
//
//  Created by Alexey Kulish on 15/07/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@class OARoutingHelper;

@interface OAVoiceRouter : NSObject

- (instancetype)initWithHelper:(OARoutingHelper *)router;
- (void) updateAppMode;

- (void) arrivedIntermediatePoint:(NSString *)name;
- (void) arrivedDestinationPoint:(NSString *)name;
- (void) updateStatus:(CLLocation *)currentLocation repeat:(BOOL)repeat;
- (void) interruptRouteCommands;
- (void) announceOffRoute:(double)dist;
- (void) newRouteIsCalculated:(BOOL)newRoute;
- (void) announceBackOnRoute;
- (void) announceCurrentDirection:(CLLocation *)currentLocation;
- (int) calculateImminent:(float)dist loc:(CLLocation *)loc;

- (void) setMute:(BOOL) mute;
- (BOOL) isMute;


@end
