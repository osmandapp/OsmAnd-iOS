//
//  OARouteInfoWidgetsFactory.h
//  OsmAnd
//
//  Created by Alexey Kulish on 08/10/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OAWidgetState.h"

@class OATextInfoWidget, OANextTurnInfoWidget, OALanesControl, OAAlarmWidget, OARulerWidget;

@interface OATimeControlWidgetState : OAWidgetState

@end

@interface OAIntermediateTimeControlWidgetState : OAWidgetState

@end

@interface OABearingWidgetState : OAWidgetState

@end

@interface OARouteInfoWidgetsFactory : NSObject

- (OATextInfoWidget *) createTimeControl:(BOOL)intermediate;
- (OATextInfoWidget *) createPlainTimeControl;
- (OATextInfoWidget *) createBatteryControl;
- (OATextInfoWidget *) createMaxSpeedControl;
- (OATextInfoWidget *) createSpeedControl;
- (OATextInfoWidget *) createDistanceControl;
- (OATextInfoWidget *) createBearingControl;
- (OATextInfoWidget *) createIntermediateDistanceControl;
- (OANextTurnInfoWidget *) createNextInfoControl:(BOOL)horisontalMini;
- (OANextTurnInfoWidget *) createNextNextInfoControl:(BOOL)horisontalMini;

- (OARulerWidget *) createRulerControl;
- (OALanesControl *) createLanesControl;
- (OAAlarmWidget *) createAlarmInfoControl;

@end
