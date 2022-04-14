//
//  OAMapWidgetRegistry.h
//  OsmAnd
//
//  Created by Alexey Kulish on 02/10/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OAApplicationMode, OATextInfoWidget, OAMapWidgetRegInfo, OAWidgetState;

@interface OAMapWidgetRegistry : NSObject

- (void) populateStackControl:(UIView *)stack mode:(OAApplicationMode *)mode left:(BOOL)left expanded:(BOOL)expanded;
- (BOOL) hasCollapsibles:(OAApplicationMode *)mode;

- (void) updateInfo:(OAApplicationMode *)mode expanded:(BOOL)expanded;
- (void) removeSideWidget:(NSString *)key;
- (void) removeSideWidgetInternal:(OATextInfoWidget *)widget;

- (OAMapWidgetRegInfo *) registerSideWidgetInternal:(OATextInfoWidget *)widget widgetState:(OAWidgetState *)widgetState key:(NSString *)key left:(BOOL)left priorityOrder:(int)priorityOrder;
- (OAMapWidgetRegInfo *) registerSideWidgetInternal:(OATextInfoWidget *)widget imageId:(NSString *)imageId message:(NSString *)message key:(NSString *)key left:(BOOL)left priorityOrder:(int)priorityOrder;

- (BOOL) isVisible:(NSString *)key;
- (void) setVisibility:(OAMapWidgetRegInfo *)m visible:(BOOL)visible collapsed:(BOOL)collapsed;
- (void) setVisibility:(OAApplicationMode *)mode m:(OAMapWidgetRegInfo *)m visible:(BOOL)visible collapsed:(BOOL)collapsed;
- (void) resetToDefault;
- (void) resetToDefault:(OAApplicationMode *)mode;
- (void) updateVisibleWidgets;

- (NSOrderedSet<OAMapWidgetRegInfo *> *) getLeftWidgetSet;
- (NSOrderedSet<OAMapWidgetRegInfo *> *) getRightWidgetSet;
- (OAMapWidgetRegInfo *) widgetByKey:(NSString *)key;

@end
