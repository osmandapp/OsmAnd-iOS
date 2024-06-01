//
//  OAMapInfoController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 08/10/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OAWidgetPanelViewController;

@protocol OAWidgetListener;

@protocol OAMapInfoControllerProtocol

@required

- (void) widgetsLayoutDidChange:(BOOL)animated;

@end

@class OAMapHudViewController, OATextInfoWidget, OAWidgetState, OAMapWidgetRegInfo, OARulerWidget;

@interface OATextState : NSObject

@property (nonatomic) BOOL textBold;
@property (nonatomic) BOOL night;
@property (nonatomic) UIColor *textColor;
@property (nonatomic) UIColor *unitColor;
@property (nonatomic) UIColor *dividerColor;
@property (nonatomic) UIColor *titleColor;
@property (nonatomic) UIColor *textOutlineColor;
@property (nonatomic) int boxTop;
@property (nonatomic) UIColor *leftColor;
@property (nonatomic) NSString *expand;
@property (nonatomic) int boxFree;
@property (nonatomic) float textOutlineWidth;

@end

@interface OAMapInfoController : NSObject <OAWidgetListener>

@property (nonatomic, weak) id<OAMapInfoControllerProtocol> delegate;
@property (nonatomic) BOOL weatherToolbarVisible;

@property (nonatomic) OAWidgetPanelViewController *topPanelController;
@property (nonatomic) OAWidgetPanelViewController *leftPanelController;
@property (nonatomic) OAWidgetPanelViewController *bottomPanelController;
@property (nonatomic) OAWidgetPanelViewController *rightPanelController;

- (instancetype) initWithHudViewController:(OAMapHudViewController *)mapHudViewController;

- (void) removeSideWidget:(OATextInfoWidget *)widget;

- (void) recreateAllControls;
- (void) recreateControls;
- (void) recreateTopWidgetsPanel;
- (void) updateInfo;
- (void) updateWeatherToolbarVisible;
- (void) expandClicked:(id)sender;

- (void) updateRuler;

- (void)updateLayout;
- (void)viewWillTransition;
- (void)updateSpeedometer;

@end
