//
//  OADistanceToPointInfoControl.h
//  OsmAnd
//
//  Created by Alexey Kulish on 01/11/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OATextInfoWidget.h"
#import <CoreLocation/CoreLocation.h>

@interface OADistanceToPointInfoControl : OATextInfoWidget

- (instancetype) initWithIcons:(NSString *)dayIconId nightIconId:(NSString *)nightIconId;

- (void) click;
- (CLLocation *) getPointToNavigate;
- (CLLocationDistance) getDistance;

@end
