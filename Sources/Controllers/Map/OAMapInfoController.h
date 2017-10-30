//
//  OAMapInfoController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 08/10/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OAMapHudViewController, OATextInfoWidget, OAWidgetState, OAMapWidgetRegInfo;

@interface OAMapInfoController : NSObject

- (instancetype) initWithHudViewController:(OAMapHudViewController *)mapHudViewController;

- (OAMapWidgetRegInfo *) registerSideWidget:(OATextInfoWidget *)widget imageId:(NSString *)imageId message:(NSString *)message key:(NSString *)key left:(BOOL)left priorityOrder:(int)priorityOrder;
- (void) registerSideWidget:(OATextInfoWidget *)widget widgetState:(OAWidgetState *)widgetState key:(NSString *)key left:(BOOL)left priorityOrder:(int)priorityOrder;
- (void) removeSideWidget:(OATextInfoWidget *)widget;

- (void) recreateControls;
- (void) expandClicked:(id)sender;

@end
