//
//  OAParkingPositionPlugin.h
//  OsmAnd
//
//  Created by Alexey Kulish on 01/11/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAPlugin.h"

@class CLLocation;

@interface OAParkingPositionPlugin : OAPlugin

- (BOOL) getParkingType;
- (BOOL) isParkingEventAdded;
- (void) addOrRemoveParkingEvent:(BOOL)added;
- (long) getParkingTime;
- (long) getStartParkingTime;
- (BOOL) clearParkingPosition;
- (BOOL) setParkingPosition:(double)latitude longitude:(double)longitude;
- (BOOL) setParkingType:(BOOL)limited;
- (BOOL) setParkingTime:(long)timeInMillis;
- (BOOL) setParkingStartTime:(long)timeInMillis;
- (CLLocation *)getParkingPosition;

- (void) setEventIdentifier:(NSString *)eventId;
- (NSString *) getEventIdentifier;

- (void) setParkingPosition:(double)latitude longitude:(double)longitude limited:(BOOL)limited;


@end
