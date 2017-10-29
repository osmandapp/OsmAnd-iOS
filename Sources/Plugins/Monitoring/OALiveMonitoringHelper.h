//
//  OALiveMonitoringHelper.h
//  OsmAnd
//
//  Created by Alexey Kulish on 29/10/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface OALiveMonitoringHelper : NSObject

- (BOOL) isLiveMonitoringEnabled;
- (void) updateLocation:(CLLocation *)location;

@end
