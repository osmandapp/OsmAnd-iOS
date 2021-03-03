//
//  OAMapInfoController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 08/10/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol OAMapInfoControllerProtocol
@required

- (void) leftWidgetsLayoutDidChange:(UIView *)leftWidgetsView animated:(BOOL)animated;

@end

@class OAMapHudViewController, OATextInfoWidget, OAWidgetState, OAMapWidgetRegInfo, OARulerWidget;

@interface OAMapInfoController : NSObject

@property (nonatomic, weak) id<OAMapInfoControllerProtocol> delegate;

- (instancetype) initWithHudViewController:(OAMapHudViewController *)mapHudViewController;

- (OAMapWidgetRegInfo *) registerSideWidget:(OATextInfoWidget *)widget imageId:(NSString *)imageId message:(NSString *)message key:(NSString *)key left:(BOOL)left priorityOrder:(int)priorityOrder;
- (void) registerSideWidget:(OATextInfoWidget *)widget widgetState:(OAWidgetState *)widgetState key:(NSString *)key left:(BOOL)left priorityOrder:(int)priorityOrder;
- (void) removeSideWidget:(OATextInfoWidget *)widget;

- (CGFloat) getLeftBottomY;

- (void) recreateControls;
- (void) updateInfo;
- (void) expandClicked:(id)sender;

- (void) updateRuler;

@end
