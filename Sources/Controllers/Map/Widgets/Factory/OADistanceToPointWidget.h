//
//  OADistanceToPointInfoControl.h
//  OsmAnd
//
//  Created by Alexey Kulish on 01/11/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//
//  OsmAnd-java/src/net/osmand/plus/views/mapwidgets/widgets/DistanceToPointWidget.java
//  git revision 2966d87dd5e7515f2356cd3d2646ccdffd311849

#import "OATextInfoWidget.h"
#import <CoreLocation/CoreLocation.h>

@interface OADistanceToPointWidget : OATextInfoWidget

- (instancetype) initWithIcons:(NSString *)dayIconId nightIconId:(NSString *)nightIconId;

- (void) click;
- (BOOL) updateInfo;
- (CLLocation *) getPointToNavigate;
- (CLLocationDistance) getDistance;

@end
