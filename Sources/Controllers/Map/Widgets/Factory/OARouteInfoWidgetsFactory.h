//
//  OARouteInfoWidgetsFactory.h
//  OsmAnd
//
//  Created by Alexey Kulish on 08/10/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OAWidgetState.h"

@class OATextInfoWidget, OANextTurnInfoWidget, OALanesControl;

@interface OATimeControlWidgetState : OAWidgetState

@end

@interface OARouteInfoWidgetsFactory : NSObject

- (OATextInfoWidget *) createTimeControl;
- (OATextInfoWidget *) createPlainTimeControl;
- (OATextInfoWidget *) createBatteryControl;
- (OATextInfoWidget *) createMaxSpeedControl;
- (OATextInfoWidget *) createSpeedControl;
- (OATextInfoWidget *) createDistanceControl;
- (OATextInfoWidget *) createIntermediateDistanceControl;
- (OANextTurnInfoWidget *) createNextInfoControl:(BOOL)horisontalMini;
- (OANextTurnInfoWidget *) createNextNextInfoControl:(BOOL)horisontalMini;

- (OALanesControl *) createLanesControl;

@end
