//
//  OAMapWidgetRegistry.h
//  OsmAnd
//
//  Created by Alexey Kulish on 02/10/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

#define COLLAPSED_PREFIX @"+"
#define HIDE_PREFIX @"-"
#define SHOW_PREFIX @""
#define SETTINGS_SEPARATOR @";"

#define kWidgetModeDisabled 0x1
#define kWidgetModeEnabled 0x2
#define KWidgetModeAvailable 0x4
#define kWidgetModeDefault 0x8
#define kWidgetModeMatchingPanels 0x16

#define kWidgetRegisteredNotification @"onWidgetRegistered"
#define kWidgetVisibilityChangedMotification @"onWidgetVisibilityChanged"
#define kWidgetsCleared @"onWidgetsCleared"

@class OAApplicationMode, OATextInfoWidget, OAWidgetState, OAMapWidgetInfo, OAWidgetsPanel, OAWidgetType, OAWidgetPanelViewController;

@interface OAMapWidgetRegistry : NSObject

+ (OAMapWidgetRegistry *) sharedInstance;

- (void) populateControlsContainer:(OAWidgetPanelViewController *)stack mode:(OAApplicationMode *)mode widgetPanel:(OAWidgetsPanel *)widgetPanel;
- (void) updateInfo:(OAApplicationMode *)mode expanded:(BOOL)expanded;
- (void) removeSideWidgetInternal:(OATextInfoWidget *)widget;

- (NSArray<OAMapWidgetInfo *> *)getAllWidgets;
- (NSMutableOrderedSet<OAMapWidgetInfo *> *)getWidgetsForPanel:(OAApplicationMode *)appMode
                                                   filterModes:(NSInteger) filterModes
                                                        panels:(NSArray<OAWidgetsPanel *> *)panels;

- (void) enableDisableWidgetForMode:(OAApplicationMode *)appMode
                         widgetInfo:(OAMapWidgetInfo *)widgetInfo
                            enabled:(NSNumber *)enabled
                   recreateControls:(BOOL)recreateControls;

- (NSArray<NSOrderedSet<OAMapWidgetInfo *> *> *)getPagedWidgetsForPanel:(OAApplicationMode *)appMode
                                                                  panel:(OAWidgetsPanel *)panel
                                                            filterModes:(NSInteger)filterModes;

- (void) registerAllControls;
- (OAMapWidgetInfo *) getWidgetInfoById:(NSString *)widgetId;
- (NSMutableOrderedSet<OAMapWidgetInfo *> *)getWidgetsForPanel:(OAWidgetsPanel *)panel;
- (NSArray<OAMapWidgetInfo *> *)getWidgetInfoForType:(OAWidgetType *)widgetType;
- (void) updateWidgetsInfo:(OAApplicationMode *)appMode;

- (BOOL) isWidgetVisible:(NSString *)widgetId;
- (void) clearWidgets;
- (void) reorderWidgets;

- (BOOL) isAnyWeatherWidgetVisible;

@end

