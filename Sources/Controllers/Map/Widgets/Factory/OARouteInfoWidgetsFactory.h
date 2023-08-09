//
//  OARouteInfoWidgetsFactory.h
//  OsmAnd
//
//  Created by Alexey Kulish on 08/10/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//
//  OsmAnd/src/net/osmand/plus/views/mapwidgets/RouteInfoWidgetsFactory.java
//  git revision 24f59ca8abdaffe133d2a5cd8068e71a8b481125

#import <Foundation/Foundation.h>
#import "OAWidgetState.h"

@class OATextInfoWidget, OANextTurnWidget, OALanesControl, OAAlarmWidget, OARulerWidget;

@interface OAIntermediateTimeControlWidgetState : OAWidgetState

@end

@interface OARouteInfoWidgetsFactory : NSObject

//TODO remove

- (OATextInfoWidget *) createTimeControl:(BOOL)intermediate;
- (OATextInfoWidget *) createPlainTimeControl;
- (OATextInfoWidget *) createBatteryControl;
- (OATextInfoWidget *) createMaxSpeedControl;
- (OATextInfoWidget *) createSpeedControl;
- (OATextInfoWidget *) createDistanceControl;
- (OATextInfoWidget *) createBearingControl;
- (OATextInfoWidget *) createIntermediateDistanceControl;
- (OANextTurnWidget *) createNextInfoControl:(BOOL)horisontalMini;
- (OANextTurnWidget *) createNextNextInfoControl:(BOOL)horisontalMini;

- (OARulerWidget *) createRulerControl;
- (OALanesControl *) createLanesControl;
- (OAAlarmWidget *) createAlarmInfoControl;
- (OATextInfoWidget *) createMapMarkerControl:(BOOL)firstMarker;

@end
