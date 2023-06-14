//
//  OAMapWidgetRegistry.m
//  OsmAnd
//
//  Created by Alexey Kulish on 02/10/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAMapWidgetRegistry.h"
#import "OsmAndApp.h"
#import "OAAppSettings.h"
#import "OAMapWidgetRegInfo.h"
#import "OATextInfoWidget.h"
#import "OAWidgetState.h"
#import "OAApplicationMode.h"
#import "OAAutoObserverProxy.h"
#import "OAWeatherPlugin.h"
#import "OARootViewController.h"
#import "OAMapHudViewController.h"
#import "OAMapInfoController.h"
#import "OrderedDictionary.h"
#import "OsmAnd_Maps-Swift.h"

@implementation OAMapWidgetRegistry
{
    
    // TODO: delete
    NSMutableOrderedSet<OAMapWidgetRegInfo *> *_leftWidgetSet;
    NSMutableOrderedSet<OAMapWidgetRegInfo *> *_rightWidgetSet;
    
    NSMutableDictionary<OAWidgetsPanel *, NSMutableOrderedSet<OAMapWidgetInfo *> *> *_allWidgets;

    NSMapTable<OAApplicationMode *, NSMutableSet<NSString *> *> *_visibleElementsFromSettings;
    OAAppSettings *_settings;
    OAAutoObserverProxy* _widgetSettingResetObserver;
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        _allWidgets = [NSMutableDictionary dictionary];
        _visibleElementsFromSettings = [NSMapTable strongToStrongObjectsMapTable];
        _settings = [OAAppSettings sharedManager];
        [self loadVisibleElementsFromSettings];
        _widgetSettingResetObserver = [[OAAutoObserverProxy alloc] initWith:self withHandler:@selector(onWidgetSettingsReset:withKey:) andObserve:[OsmAndApp instance].widgetSettingResetObservable];
    }
    return self;
}

- (void) populateStackControl:(UIView *)stack mode:(OAApplicationMode *)mode left:(BOOL)left expanded:(BOOL)expanded
{
    NSArray<OAMapWidgetRegInfo *> *s = [NSArray arrayWithArray:left ? _leftWidgetSet.array : _rightWidgetSet.array];
    NSArray *weatherWidgets = @[kWeatherTemp, kWeatherPressure, kWeatherWind, kWeatherCloud, kWeatherPrecip];
    BOOL weatherToolbarVisible = [OARootViewController instance].mapPanel.hudViewController.mapInfoController.weatherToolbarVisible;
    for (OAMapWidgetRegInfo *r in s)
    {
        if (r.widget && ((!weatherToolbarVisible && ([r visible:mode] || [r.widget isExplicitlyVisible])) || (weatherToolbarVisible && [weatherWidgets containsObject:r.key])))
            [stack addSubview:r.widget];
    }
    if (expanded)
    {
        for (OAMapWidgetRegInfo *r in s)
        {
            if (r.widget && ((!weatherToolbarVisible && [r visibleCollapsed:mode] && ![r.widget isExplicitlyVisible]) || (weatherToolbarVisible && [weatherWidgets containsObject:r.key])))
                [stack addSubview:r.widget];
        }
    }
}

- (void) populateStackControl:(OAWidgetPanelViewController *)stack mode:(OAApplicationMode *)mode widgetPanel:(OAWidgetsPanel *)widgetPanel
{
    NSOrderedSet<OAMapWidgetInfo *> *widgets = [self getWidgetsForPanel:widgetPanel];
    
    NSMutableArray<OABaseWidgetView *> *widgetsToShow = [NSMutableArray array];
    
    BOOL weatherToolbarVisible = self.isWeatherToolbarVisible;
    for (OAMapWidgetInfo *widgetInfo in widgets)
    {
        if ([widgetInfo isEnabledForAppMode:mode] || weatherToolbarVisible)
        {
            [widgetsToShow addObject:widgetInfo.widget];
        }
        else
        {
            [widgetInfo.widget removeFromSuperview];
        }
    }
    
//    for (int i = 0; i < widgetsToShow.count; i++)
//    {
//        OABaseWidgetView *widget = widgetsToShow[i];
//        NSArray<OABaseWidgetView *> *followingWidgets = i + 1 == widgetsToShow.count
//        ? @[]
//        : [widgetsToShow subarrayWithRange:NSMakeRange(i + 1, widgetsToShow.count - (i + 1))];
//        [widget attachView:stack order:i followingWidgets:followingWidgets];
//    }
    [stack updateWidgetPages:@[widgetsToShow]];
}

- (void) updateWidgetsInfo:(OAApplicationMode *)appMode
{
    for (OAMapWidgetInfo *widgetInfo in [self getAllWidgets])
    {
        if ([widgetInfo isEnabledForAppMode:appMode] || [widgetInfo isKindOfClass:OACenterWidgetInfo.class])
        {
            [widgetInfo.widget updateInfo];
        }
    }
}

- (NSArray<OAMapWidgetInfo *> *)getAllWidgets
{
    NSMutableArray<OAMapWidgetInfo *> *widgets = [NSMutableArray array];
    for (NSOrderedSet<OAMapWidgetInfo *> *panelWidgets in _allWidgets.allValues) {
        [widgets addObjectsFromArray:panelWidgets.array];
    }
    return widgets;
}

- (NSMutableOrderedSet<OAMapWidgetInfo *> *) getLeftWidgets
{
    return [self getWidgetsForPanel:OAWidgetsPanel.leftPanel];
}

- (NSMutableOrderedSet<OAMapWidgetInfo *> *) getRightWidgets {
    return [self getWidgetsForPanel:OAWidgetsPanel.rightPanel];
}

- (BOOL) hasCollapsibles:(OAApplicationMode *)mode
{
    for (OAMapWidgetRegInfo *r in self.getLeftWidgetSet)
        if ([r visibleCollapsed:mode])
            return YES;

    for (OAMapWidgetRegInfo *r in self.getRightWidgetSet)
        if ([r visibleCollapsed:mode])
            return YES;

    return NO;
}

- (void) updateInfo:(OAApplicationMode *)mode expanded:(BOOL)expanded
{
    for (OAMapWidgetInfo *widgetInfo in self.getAllWidgets)
    {
        if ([widgetInfo isEnabledForAppMode:mode] || [widgetInfo isKindOfClass:OACenterWidgetInfo.class] || (self.isWeatherToolbarVisible && widgetInfo.getWidgetType.group == OAWidgetGroup.weather))
        {
            [widgetInfo.widget updateInfo];
        }
    }
}

- (void) update:(OAApplicationMode *)mode expanded:(BOOL)expanded widgetSet:(NSOrderedSet<OAMapWidgetRegInfo *> *)widgetSet
{
    NSArray *weatherWidgets = @[kWeatherTemp, kWeatherPressure, kWeatherWind, kWeatherCloud, kWeatherPrecip];
    BOOL weatherToolbarVisible = [OARootViewController instance].mapPanel.hudViewController.mapInfoController.weatherToolbarVisible;
    for (OAMapWidgetRegInfo *r in widgetSet)
    {
        if (r.widget && ((!weatherToolbarVisible && ([r visible:mode] || ([r visibleCollapsed:mode] && expanded))) || (weatherToolbarVisible && [weatherWidgets containsObject:r.key])))
            [r.widget updateInfo];
    }
}

- (void) removeSideWidget:(NSString *)key
{
    for (OAMapWidgetRegInfo *widget in _leftWidgetSet)
    {
        if ([widget.key isEqualToString:key])
            [_leftWidgetSet removeObject:widget];
    }
    for (OAMapWidgetRegInfo *widget in _rightWidgetSet)
    {
        if ([widget.key isEqualToString:key])
            [_rightWidgetSet removeObject:widget];
    }
}

- (void) removeSideWidgetInternal:(OATextInfoWidget *)widget
{
    NSMutableOrderedSet<OAMapWidgetInfo *> *leftSet = self.getLeftWidgets;
    NSArray<OAMapWidgetInfo *> *leftWidgets = leftSet.array;
    for (OAMapWidgetInfo *r in leftWidgets)
    {
        if (r.widget == widget)
            [leftSet removeObject:r];
    }

    NSMutableOrderedSet<OAMapWidgetInfo *> *rightSet = self.getRightWidgets;
    NSArray<OAMapWidgetInfo *> *rightWidgets = rightSet.array;
    
    for (OAMapWidgetInfo *r in rightWidgets)
    {
        if (r.widget == widget)
            [rightSet removeObject:r];
    }
}

- (void) clearWidgets
{
    [_allWidgets removeAllObjects];
    [self notifyWidgetsCleared];
}

- (void) notifyWidgetsCleared
{
    [NSNotificationCenter.defaultCenter postNotificationName:kWidgetsCleared object:nil];
}

- (void) notifyWidgetRegistered:(OAMapWidgetInfo *)widgetInfo
{
    [NSNotificationCenter.defaultCenter postNotificationName:kWidgetRegisteredNotification object:widgetInfo];
}

- (void) notifyWidgetVisibilityChanged:(OAMapWidgetInfo *)widgetInfo
{
    [NSNotificationCenter.defaultCenter postNotificationName:kWidgetVisibilityChangedMotification object:widgetInfo];
}

- (BOOL) isWidgetVisibleForInfo:(OAMapWidgetInfo *)widgetInfo
{
    return [self isWidgetVisible:widgetInfo.key];
}

- (BOOL) isWidgetVisible:(NSString *)widgetId
{
    OAApplicationMode *appMode = _settings.applicationMode.get;
    OAMapWidgetInfo *widgetInfo = [self getWidgetInfoById:widgetId];
    return widgetInfo != nil && [widgetInfo isEnabledForAppMode:appMode];
}

- (OAMapWidgetInfo *) getWidgetInfoById:(NSString *)widgetId
{
    for (OAMapWidgetInfo *widgetInfo in self.getAllWidgets)
    {
        if ([widgetId isEqualToString:widgetInfo.key])
        {
            return widgetInfo;
        }
    }
    return nil;
}

- (void) enableDisableWidgetForMode:(OAApplicationMode *)appMode
                         widgetInfo:(OAMapWidgetInfo *)widgetInfo
                            enabled:(NSNumber *)enabled
                   recreateControls:(BOOL)recreateControls
{
    [widgetInfo enableDisableWithAppMode:appMode enabled:enabled];
    [self notifyWidgetVisibilityChanged:widgetInfo];
    
    if ([widgetInfo isCustomWidget] && (!enabled || !enabled.boolValue))
        [_settings.customWidgetKeys remove:widgetInfo.key];
    
    if (recreateControls)
        [[OARootViewController instance].mapPanel recreateControls];
}

- (void) reorderWidgets
{
    [self reorderWidgets:self.getAllWidgets];
}

- (void) reorderWidgets:(NSArray<OAMapWidgetInfo *> *)widgetInfos
{
    NSMutableDictionary<OAWidgetsPanel *, NSMutableOrderedSet<OAMapWidgetInfo *> *> *newAllWidgets = [NSMutableDictionary dictionary];
    for (OAMapWidgetInfo *widget in widgetInfos)
    {
        OAWidgetsPanel *panel = [widget getUpdatedPanel];
        widget.pageIndex = [panel getWidgetPage:widget.key];
        widget.priority = [panel getWidgetOrder:widget.key];
        
        NSMutableOrderedSet<OAMapWidgetInfo *> *widgetsOfPanel = newAllWidgets[panel];
        if (widgetsOfPanel == nil && panel != nil)
        {
            widgetsOfPanel = [NSMutableOrderedSet orderedSet];
            newAllWidgets[panel] = widgetsOfPanel;
        }
        [widgetsOfPanel addObject:widget];
    }
    
    _allWidgets = newAllWidgets;
}

- (NSArray<OAMapWidgetInfo *> *)getWidgetInfoForType:(OAWidgetType *)widgetType
{
    NSMutableArray<OAMapWidgetInfo *> *widgets = [NSMutableArray array];
    for (OAMapWidgetInfo *widgetInfo in self.getAllWidgets)
    {
        if (widgetInfo.getWidgetType == widgetType)
        {
            [widgets addObject:widgetInfo];
        }
    }
    return widgets;
}

- (NSArray<NSOrderedSet<OAMapWidgetInfo *> *> *)getPagedWidgetsForPanel:(OAApplicationMode *)appMode
                                                                  panel:(OAWidgetsPanel *)panel
                                                            filterModes:(NSInteger)filterModes
{
    MutableOrderedDictionary<NSNumber *, NSMutableOrderedSet<OAMapWidgetInfo *> *> *widgetsByPages = [MutableOrderedDictionary dictionary];
    for (OAMapWidgetInfo *widgetInfo in [self getWidgetsForPanel:appMode filterModes:filterModes panels:@[panel]])
    {
        NSInteger page = widgetInfo.pageIndex;
        NSMutableOrderedSet<OAMapWidgetInfo *> *widgetsOfPage = widgetsByPages[@(page)];
        if (!widgetsOfPage)
        {
            widgetsOfPage = [NSMutableOrderedSet orderedSet];
            widgetsByPages[@(page)] = widgetsOfPage;
        }
        [widgetsOfPage addObject:widgetInfo];
    }
    return widgetsByPages.allValues;
}

- (NSMutableOrderedSet<OAMapWidgetInfo *> *)getWidgetsForPanel:(OAApplicationMode *)appMode
                                                   filterModes:(NSInteger) filterModes
                                                        panels:(NSArray<OAWidgetsPanel *> *)panels
{
    NSMutableArray<OAMapWidgetInfo *> *widgetInfos = [NSMutableArray array];
    if (_settings.applicationMode.get == appMode)
        [widgetInfos addObjectsFromArray:self.getAllWidgets];
    else
        [widgetInfos addObjectsFromArray:[OAWidgetsInitializer createAllControlsWithAppMode:appMode]];
    NSMutableOrderedSet<OAMapWidgetInfo *> *filteredWidgets = [NSMutableOrderedSet orderedSet];
    for (OAMapWidgetInfo *widget in widgetInfos)
    {
        if ([panels containsObject:widget.widgetPanel])
        {
            BOOL disabledMode = (filterModes & kWidgetModeDisabled) == kWidgetModeDisabled;
            BOOL enabledMode = (filterModes & kWidgetModeEnabled) == kWidgetModeEnabled;
            BOOL availableMode = (filterModes & KWidgetModeAvailable) == KWidgetModeAvailable;
            BOOL defaultMode = (filterModes & kWidgetModeDefault) == kWidgetModeDefault;
            
            BOOL passDisabled = !disabledMode || ![widget isEnabledForAppMode:appMode];
            BOOL passEnabled = !enabledMode || [widget isEnabledForAppMode:appMode];
            BOOL passAvailable = !availableMode || [OAWidgetsAvailabilityHelper isWidgetAvailableWithWidgetId:widget.key appMode:appMode];
            BOOL defaultAvailable = !defaultMode || !widget.isCustomWidget;
            
            if (passDisabled && passEnabled && passAvailable && defaultAvailable)
            {
                [filteredWidgets addObject:widget];
            }
        }
    }
    return filteredWidgets;
}

- (BOOL) isWeatherToolbarVisible
{
    return [OARootViewController instance].mapPanel.hudViewController.mapInfoController.weatherToolbarVisible;
}

- (NSMutableOrderedSet<OAMapWidgetInfo *> *)getWidgetsForPanel:(OAWidgetsPanel *)panel
{
    if (panel == OAWidgetsPanel.rightPanel && self.isWeatherToolbarVisible)
    {
        NSMutableOrderedSet<OAMapWidgetInfo *> *widgets = [NSMutableOrderedSet orderedSet];
        for (OAMapWidgetInfo *info in _allWidgets[panel])
        {
            if (info.getWidgetType.group == OAWidgetGroup.weather) {
                [widgets addObject:info];
            }
        }
        return widgets;
    }
    else if (self.isWeatherToolbarVisible)
    {
        return [NSMutableOrderedSet orderedSet];
    }
    NSMutableOrderedSet<OAMapWidgetInfo *> *widgets = _allWidgets[panel];
    if (widgets == nil)
    {
        widgets = [NSMutableOrderedSet orderedSet];
        _allWidgets[panel] = widgets;
    }
    return widgets;
}

// TODO: Delete

- (OAMapWidgetRegInfo *) registerSideWidgetInternal:(OATextInfoWidget *)widget widgetState:(OAWidgetState *)widgetState key:(NSString *)key left:(BOOL)left priorityOrder:(int)priorityOrder
{
    OAMapWidgetRegInfo *ii = [[OAMapWidgetRegInfo alloc] initWithKey:key widget:widget widgetState:widgetState priorityOrder:priorityOrder left:left];
    [self processVisibleModes:key ii:ii];
    if (widget)
        [widget setContentTitle:[widgetState getMenuTitle]];

    if (left)
    {
        [_leftWidgetSet addObject:ii];
        [_leftWidgetSet sortUsingComparator:^NSComparisonResult(OAMapWidgetRegInfo * _Nonnull r1, OAMapWidgetRegInfo * _Nonnull r2) {
            return [r1 compare:r2];
        }];
    }
    else
    {
        [_rightWidgetSet addObject:ii];
        [_rightWidgetSet sortUsingComparator:^NSComparisonResult(OAMapWidgetRegInfo * _Nonnull r1, OAMapWidgetRegInfo * _Nonnull r2) {
            return [r1 compare:r2];
        }];
    }

    return ii;
}

- (OAMapWidgetRegInfo *) registerSideWidgetInternal:(OATextInfoWidget *)widget imageId:(NSString *)imageId message:(NSString *)message description:(NSString *)description key:(NSString *)key left:(BOOL)left priorityOrder:(int)priorityOrder
{
    OAMapWidgetRegInfo *ii = [[OAMapWidgetRegInfo alloc] initWithKey:key widget:widget imageId:imageId message:message description:description priorityOrder:priorityOrder left:left];
    [self processVisibleModes:key ii:ii];
    if (widget)
        [widget setContentTitle:message];

    if (left)
    {
        [_leftWidgetSet addObject:ii];
        [_leftWidgetSet sortUsingComparator:^NSComparisonResult(OAMapWidgetRegInfo * _Nonnull r1, OAMapWidgetRegInfo * _Nonnull r2) {
            return [r1 compare:r2];
        }];
    }
    else
    {
        [_rightWidgetSet addObject:ii];
        [_rightWidgetSet sortUsingComparator:^NSComparisonResult(OAMapWidgetRegInfo * _Nonnull r1, OAMapWidgetRegInfo * _Nonnull r2) {
            return [r1 compare:r2];
        }];
    }

    return ii;
}

- (void) processVisibleModes:(NSString *)key ii:(OAMapWidgetRegInfo *)ii
{
    for (OAApplicationMode *ms in [OAApplicationMode values])
    {
        BOOL collapse = NO; /*[ms isWidgetCollapsible:key];*/
        BOOL def = YES;/*[ms isWidgetVisible:key];*/
        NSMutableSet<NSString *> *set = [_visibleElementsFromSettings objectForKey:ms];
        if (set)
        {
            if ([set containsObject:key])
            {
                def = YES;
                collapse = NO;
            }
            else if ([set containsObject:[HIDE_PREFIX stringByAppendingString:key]])
            {
                def = NO;
                collapse = NO;
            } else if ([set containsObject:[COLLAPSED_PREFIX stringByAppendingString:key]])
            {
                def = NO;
                collapse = YES;
            }
        }
        if (def)
            [ii.visibleModes addObject:ms];
        else if (collapse)
            [ii.visibleCollapsible addObject:ms];
    }
}

- (void) restoreModes:(NSMutableSet<NSString *> *)set mi:(NSOrderedSet<OAMapWidgetRegInfo *> *)mi mode:(OAApplicationMode *)mode
{
    for (OAMapWidgetRegInfo *m in mi)
    {
        if ([m.visibleModes containsObject:mode])
            [set addObject:m.key];
        else if (m.visibleCollapsible && [m.visibleCollapsible containsObject:mode])
            [set addObject:[COLLAPSED_PREFIX stringByAppendingString:m.key]];
        else
            [set addObject:[HIDE_PREFIX stringByAppendingString:m.key]];
    }
}

- (BOOL) isVisible:(NSString *)key
{
    OAApplicationMode *mode = _settings.applicationMode.get;
    NSMutableSet<NSString *> *elements = [_visibleElementsFromSettings objectForKey:mode];
    return elements && ([elements containsObject:key] || [elements containsObject:[COLLAPSED_PREFIX stringByAppendingString:key]]);
}

- (void) setVisibility:(OAMapWidgetRegInfo *)m visible:(BOOL)visible collapsed:(BOOL)collapsed
{
    OAApplicationMode *mode = _settings.applicationMode.get;
    [self setVisibility:mode m:m visible:visible collapsed:collapsed];
}

- (void) setVisibility:(OAApplicationMode *)mode m:(OAMapWidgetRegInfo *)m visible:(BOOL)visible collapsed:(BOOL)collapsed
{
    [self defineDefaultSettingsElement:mode];
    // clear everything
    [[_visibleElementsFromSettings objectForKey:mode] removeObject:m.key];
    [[_visibleElementsFromSettings objectForKey:mode] removeObject:[COLLAPSED_PREFIX stringByAppendingString:m.key]];
    [[_visibleElementsFromSettings objectForKey:mode] removeObject:[HIDE_PREFIX stringByAppendingString:m.key]];
    [m.visibleModes removeObject:mode];
    [m.visibleCollapsible removeObject:mode];
    if (visible && collapsed)
    {
        // Set "collapsed" state
        [m.visibleCollapsible addObject:mode];
        [[_visibleElementsFromSettings objectForKey:mode] addObject:[COLLAPSED_PREFIX stringByAppendingString:m.key]];
    }
    else if (visible)
    {
        // Set "visible" state
        [m.visibleModes addObject:mode];
        [[_visibleElementsFromSettings objectForKey:mode] addObject:[SHOW_PREFIX stringByAppendingString:m.key]];
    }
    else
    {
        // Set "hidden" state
        [[_visibleElementsFromSettings objectForKey:mode] addObject:[HIDE_PREFIX stringByAppendingString:m.key]];
    }
    [self saveVisibleElementsToSettings:mode];
}

- (void) defineDefaultSettingsElement:(OAApplicationMode *)mode
{
    if ([_visibleElementsFromSettings objectForKey:mode] == nil)
    {
        NSMutableSet<NSString *> *set = [NSMutableSet set];
        [self restoreModes:set mi:_leftWidgetSet mode:mode];
        [self restoreModes:set mi:_rightWidgetSet mode:mode];
        [_visibleElementsFromSettings setObject:set forKey:mode];
    }
}

- (void) saveVisibleElementsToSettings:(OAApplicationMode *)mode
{
    NSMutableString *bs = [NSMutableString string];
    for (NSString *ks in [_visibleElementsFromSettings objectForKey:mode])
    {
        [bs appendString:ks];
        [bs appendString:SETTINGS_SEPARATOR];
    }

    [_settings.mapInfoControls set:[NSString stringWithString:bs]];
}

- (void) onWidgetSettingsReset:(id)sender withKey:(id)key;
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (key && [key isKindOfClass:OAApplicationMode.class])
            [self resetToDefault:(OAApplicationMode *)key];
    });
}

- (void) resetDefault:(OAApplicationMode *)mode set:(NSMutableOrderedSet<OAMapWidgetRegInfo *> *)set
{
    for (OAMapWidgetRegInfo *ri in set)
    {
        [ri.visibleCollapsible removeObject:mode];
        [ri.visibleModes removeObject:mode];
        if ([mode isWidgetVisible:ri.key])
        {
            if ([mode isWidgetCollapsible:ri.key])
                [ri.visibleCollapsible addObject:mode];
            else
                [ri.visibleModes addObject:mode];
        }
    }
}

- (void) resetToDefault
{
    OAApplicationMode *appMode = _settings.applicationMode.get;
    [self resetToDefault: appMode];
}

- (void) resetToDefault:(OAApplicationMode *)mode
{
    [self resetDefault:mode set:_leftWidgetSet];
    [self resetDefault:mode set:_rightWidgetSet];
    [self setVisibility:mode m:[self widgetByKey:@"radius_ruler"] visible:NO collapsed:NO];
    [self resetDefaultAppearance:mode];
    [_visibleElementsFromSettings setObject:nil forKey:mode];
    [_settings.mapInfoControls set:SHOW_PREFIX];
}

- (void) resetDefaultAppearance:(OAApplicationMode *)appMode
{
    [_settings.distanceIndicationVisibility resetToDefault];
    [_settings.transparentMapTheme resetToDefault];
    [_settings.showStreetName resetToDefault];
    [_settings.positionPlacementOnMap resetToDefault];
}

- (void) updateVisibleWidgets
{
    [self loadVisibleElementsFromSettings];
    for (OAMapWidgetRegInfo *ri in _leftWidgetSet)
        [self processVisibleModes:ri.key ii:ri];
    for (OAMapWidgetRegInfo *ri in _rightWidgetSet)
        [self processVisibleModes:ri.key ii:ri];
}

- (void) loadVisibleElementsFromSettings
{
    _visibleElementsFromSettings = [NSMapTable strongToStrongObjectsMapTable];
    for (OAApplicationMode *ms in OAApplicationMode.values)
    {
        NSString *mpf = [_settings.mapInfoControls get:ms];
        if ([mpf isEqualToString:SHOW_PREFIX])
        {
            [_visibleElementsFromSettings setObject:nil forKey:ms];
        }
        else
        {
            NSMutableSet<NSString *> *set = [NSMutableSet set];
            [_visibleElementsFromSettings setObject:set forKey:ms];
            NSArray<NSString *> *split = [mpf componentsSeparatedByString:SETTINGS_SEPARATOR];
            [set addObjectsFromArray:split];
        }

    }
}

- (void) registerAllControls
{
    OAApplicationMode *appMode = _settings.applicationMode.get;
    NSArray<OAMapWidgetInfo *> *infos = [OAWidgetsInitializer createAllControlsWithAppMode:appMode];
    [self reorderWidgets:infos];
    
    for (OAMapWidgetInfo *widgetInfo : infos)
    {
        [self notifyWidgetRegistered:widgetInfo];
    }
}

- (NSOrderedSet<OAMapWidgetRegInfo *> *) getLeftWidgetSet
{
    return [NSOrderedSet orderedSetWithOrderedSet:_leftWidgetSet];
}

- (NSOrderedSet<OAMapWidgetRegInfo *> *) getRightWidgetSet
{
    return [NSOrderedSet orderedSetWithOrderedSet:_rightWidgetSet];
}

- (OAMapWidgetRegInfo *) widgetByKey:(NSString *)key
{
    for (OAMapWidgetRegInfo *r in _leftWidgetSet)
    {
        if ([r.key isEqualToString:key])
            return r;
    }
    for (OAMapWidgetRegInfo *r in _rightWidgetSet)
    {
        if ([r.key isEqualToString:key])
            return r;
    }
    return nil;
}

@end
