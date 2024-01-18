//
//  OADistanceToPointInfoControl.h
//  OsmAnd
//
//  Created by Alexey Kulish on 01/11/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//
//  OsmAnd-java/src/net/osmand/plus/views/mapwidgets/widgets/DistanceToPointWidget.java
//  git revision 2966d87dd5e7515f2356cd3d2646ccdffd311849

#import "OASimpleWidget.h"
#import <CoreLocation/CoreLocation.h>

@class OAWidgetType;

@interface OADistanceToPointWidget : OASimpleWidget

- (instancetype) initWithIcon:(NSString *)iconId widgetType:(OAWidgetType *)widgetType;

- (void) click;
- (CLLocation *) getPointToNavigate;
- (CLLocationDistance) getDistance;

@end
