//
//  OARouteInfoWidgetsFactory.h
//  OsmAnd
//
//  Created by Alexey Kulish on 08/10/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OAWidgetState.h"

@class OATextInfoWidget;

@interface OATimeControlWidgetState : OAWidgetState

@end

@interface OARouteInfoWidgetsFactory : NSObject

- (OATextInfoWidget *) createTimeControl;
- (OATextInfoWidget *) createPlainTimeControl;
- (OATextInfoWidget *) createBatteryControl;
- (OATextInfoWidget *) createMaxSpeedControl;
- (OATextInfoWidget *) createSpeedControl;

@end
