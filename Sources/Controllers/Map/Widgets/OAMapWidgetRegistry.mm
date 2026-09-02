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
#import "OAMapPanelViewController.h"
#import "OAMapHudViewController.h"
#import "OAMapInfoController.h"
#import "OrderedDictionary.h"
#import "OsmAnd_Maps-Swift.h"

@implementation OAMapWidgetRegistry
{
    NSMutableDictionary<OAWidgetsPanel *, NSMutableOrderedSet<OAMapWidgetInfo *> *> *_allWidgets;
    OAAppSettings *_settings;
    OAApplicationMode *_cachedAppMode;
    ScreenLayoutMode _cachedScreenLayoutMode;
    BOOL _cachedUseSeparateLayouts;
}

- (NSArray<NSString *> *)widgetsVisibilityForAppMode:(OAApplicationMode *)appMode
{
    return [self widgetsVisibilityForAppMode:appMode
                            screenLayoutMode:[ScreenLayoutModeWrapper defaultForAppMode:appMode]];
}

- (NSArray<NSString *> *)widgetsVisibilityForAppMode:(OAApplicationMode *)appMode
                                    screenLayoutMode:(ScreenLayoutMode)screenLayoutMode
{
    NSNumber *layoutMode = [_settings.useSeparateLayouts get:appMode] ? @(screenLayoutMode) : nil;
    return [OAMapWidgetInfo widgetsVisibility:appMode
                              screenLayoutMode:layoutMode];
}

+ (OAMapWidgetRegistry *)sharedInstance
{
    static dispatch_once_t once;
    static OAMapWidgetRegistry * sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        _allWidgets = [NSMutableDictionary dictionary];
        _settings = [OAAppSettings sharedManager];
    }
    return self;
}

- (void) populateControlsContainer:(OAWidgetPanelViewController *)stack mode:(OAApplicationMode *)mode widgetPanel:(OAWidgetsPanel *)widgetPanel
{
    NSMutableArray<NSMutableArray<OABaseWidgetView *> *> *widgetsToShow = [NSMutableArray array];
    NSMutableArray<OABaseWidgetView *> *currentPage = [NSMutableArray array];
    BOOL weatherToolbarVisible = self.isWeatherToolbarVisible;

    ScreenLayoutMode screenLayoutMode = [ScreenLayoutModeWrapper defaultForAppMode:mode];
    NSArray<NSString *> *widgetsVisibility = [self widgetsVisibilityForAppMode:mode
                                                              screenLayoutMode:screenLayoutMode];
    NSArray<NSOrderedSet<OAMapWidgetInfo *> *> *pagedWidgets = [self pagedWidgetsForPanel:mode panel:widgetPanel filterModes:(KWidgetModeAvailable | kWidgetModeEnabled | kWidgetModeMatchingPanels) screenLayoutMode:screenLayoutMode];
    if (weatherToolbarVisible && widgetPanel == OAWidgetsPanel.rightPanel)
    {
        pagedWidgets = @[];
    }
    for (NSOrderedSet<OAMapWidgetInfo *> *page in pagedWidgets)
    {
        NSArray<OAMapWidgetInfo *> *sortedWidgets =
        [page.array sortedArrayUsingComparator:^NSComparisonResult(OAMapWidgetInfo * _Nonnull w1, OAMapWidgetInfo * _Nonnull w2) {
            return [OAUtilities compareInt:(int) w1.priority y:(int) w2.priority];
        }];
        for (OAMapWidgetInfo *widgetInfo in sortedWidgets)
        {
            if ([widgetInfo isEnabledForAppMode:mode widgetsVisibility:widgetsVisibility] || weatherToolbarVisible)
                [currentPage addObject:widgetInfo.widget];
            else
                [widgetInfo.widget detachView:widgetPanel];
        }
        [widgetsToShow addObject:currentPage];
        for (int i = 0; i < currentPage.count; i++)
        {
            OABaseWidgetView *widget = currentPage[i];
            NSArray<OABaseWidgetView *> *followingWidgets = i + 1 == currentPage.count
                ? @[]
                : [currentPage subarrayWithRange:NSMakeRange(i + 1, currentPage.count - (i + 1))];
            [widget attachView:stack.view specialContainer:stack.specialPanelController.view order:i followingWidgets:followingWidgets];
        }
        currentPage = [NSMutableArray array];
    }

    if (widgetsToShow.count == 1)
    {
        OABaseWidgetView *lastWidget = widgetsToShow[0].lastObject;
        if (lastWidget.widgetType && lastWidget.widgetType.special && stack.specialPanelController)
        {
            [stack.specialPanelController updateWidgetPages:@[@[lastWidget]]];
            [widgetsToShow[0] removeLastObject];
        }
    }
    [stack updateWidgetPages:widgetsToShow];
}

- (void) updateWidgetsInfo:(OAApplicationMode *)appMode
{
    NSArray<NSString *> *widgetsVisibility = [self widgetsVisibilityForAppMode:appMode];
    for (OAMapWidgetInfo *widgetInfo in [self getAllWidgets])
    {
        if ([widgetInfo isEnabledForAppMode:appMode widgetsVisibility:widgetsVisibility])
            [widgetInfo.widget updateInfo];
    }
}

- (NSArray<OAMapWidgetInfo *> *)getAllWidgets
{
    NSMutableArray<OAMapWidgetInfo *> *widgets = [NSMutableArray array];
    for (NSOrderedSet<OAMapWidgetInfo *> *panelWidgets in _allWidgets.allValues)
    {
        [widgets addObjectsFromArray:panelWidgets.array];
    }
    return widgets;
}

- (NSMutableOrderedSet<OAMapWidgetInfo *> *) getLeftWidgets
{
    return [self widgetsForPanel:OAWidgetsPanel.leftPanel];
}

- (NSMutableOrderedSet<OAMapWidgetInfo *> *) getRightWidgets
{
    return [self widgetsForPanel:OAWidgetsPanel.rightPanel];
}

- (BOOL) isAnyWeatherWidgetVisible
{
    OAApplicationMode *mode = [_settings.applicationMode get];
    BOOL weatherToolbarVisible = self.isWeatherToolbarVisible;
    NSArray<NSString *> *widgetsVisibility = [self widgetsVisibilityForAppMode:mode];
    for (OAMapWidgetInfo *widgetInfo in OAMapWidgetRegistry.sharedInstance.getAllWidgets)
    {
        if (widgetInfo.widgetType.group == OAWidgetGroup.weather)
        {
            if (weatherToolbarVisible || [widgetInfo isEnabledForAppMode:mode widgetsVisibility:widgetsVisibility])
                return YES;
        }
    }
    return NO;
}

- (void) updateInfo:(OAApplicationMode *)mode expanded:(BOOL)expanded
{
    BOOL weatherToolbarVisible = self.isWeatherToolbarVisible;
    NSArray<NSString *> *widgetsVisibility = [self widgetsVisibilityForAppMode:mode];
    for (OAMapWidgetInfo *widgetInfo in self.getAllWidgets)
    {
        BOOL enabledForAppMode = [widgetInfo isEnabledForAppMode:mode widgetsVisibility:widgetsVisibility];
        if (enabledForAppMode || (weatherToolbarVisible && widgetInfo.widgetType.group == OAWidgetGroup.weather))
            [widgetInfo.widget updateInfo];
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
    _cachedAppMode = nil;
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

- (void) notifyWidgetsPanelsDidLayout
{
    NSNotification *notif = [NSNotification notificationWithName:kWidgetsPanelsDidLayoutNotification object:self userInfo:nil];
    [[NSNotificationQueue defaultQueue] enqueueNotification:notif postingStyle:NSPostASAP coalesceMask:(NSNotificationCoalescingOnName | NSNotificationCoalescingOnSender) forModes:nil];
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
    [widgetInfo enableDisableForMode:appMode enabled:enabled];
    [self notifyWidgetVisibilityChanged:widgetInfo];
    
    if ([widgetInfo isCustomWidget] && (!enabled || !enabled.boolValue))
    {
        NSNumber *layoutMode = [_settings.useSeparateLayouts get:appMode] ? @(widgetInfo.screenLayoutMode) : nil;
        OACommonStringList *customWidgetKeys = [_settings customWidgetKeys:layoutMode];
        NSMutableArray<NSString *> *keys = [[customWidgetKeys get:appMode] mutableCopy];
        [keys removeObject:widgetInfo.key];
        [customWidgetKeys set:keys mode:appMode];
    }
    
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
        NSNumber *layoutMode = [_settings.useSeparateLayouts get:widget.appMode] ? @(widget.screenLayoutMode) : nil;
        OAWidgetsPanel *panel = [widget getUpdatedPanel];
        widget.pageIndex = [panel widgetPage:widget.key appMode:widget.appMode screenLayoutMode:layoutMode];
        widget.priority = [panel widgetOrder:widget.key appMode:widget.appMode screenLayoutMode:layoutMode];
        
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

- (NSArray<OAMapWidgetInfo *> *)getWidgetInfosForType:(OAWidgetType *)widgetType
{
    NSMutableArray<OAMapWidgetInfo *> *widgets = [NSMutableArray array];
    for (OAMapWidgetInfo *widgetInfo in self.getAllWidgets)
    {
        if (widgetInfo.widgetType == widgetType)
            [widgets addObject:widgetInfo];
    }
    return [widgets copy];
}

- (NSArray<OAMapWidgetInfo *> *)widgetsForAppMode:(OAApplicationMode *)appMode
                                 screenLayoutMode:(ScreenLayoutMode)screenLayoutMode
{
    NSNumber *layoutMode = [_settings.useSeparateLayouts get:appMode] ? @(screenLayoutMode) : nil;
    return [self widgetsForAppMode:appMode layoutMode:layoutMode];
}

- (NSArray<OAMapWidgetInfo *> *)widgetsForAppMode:(OAApplicationMode *)appMode
                                       layoutMode:(NSNumber *)layoutMode
{
    BOOL useSeparateLayouts = layoutMode != nil;
    ScreenLayoutMode screenLayoutMode = useSeparateLayouts
        ? (ScreenLayoutMode)layoutMode.intValue
        : ScreenLayoutModePortrait;
    if (_cachedAppMode == appMode
        && _cachedUseSeparateLayouts == useSeparateLayouts
        && (!useSeparateLayouts || _cachedScreenLayoutMode == screenLayoutMode))
    {
        return self.getAllWidgets;
    }
    return [OAWidgetsInitializer createAllControlsWithAppMode:appMode
                                             screenLayoutMode:screenLayoutMode
                                         preferenceLayoutMode:layoutMode];
}

- (OAMapWidgetInfo *)widgetInfoForType:(OAWidgetType *)widgetType
{
    for (OAMapWidgetInfo *widgetInfo in self.getAllWidgets)
    {
        if (widgetInfo.widgetType == widgetType && ![widgetInfo isCustomWidget])
            return widgetInfo;
    }
    return nil;
}

- (OAMapWidgetInfo *)widgetInfoForType:(OAWidgetType *)widgetType
                               appMode:(OAApplicationMode *)appMode
                      screenLayoutMode:(int)screenLayoutMode
{
    for (OAMapWidgetInfo *widgetInfo in [self widgetsForAppMode:appMode
                                              screenLayoutMode:(ScreenLayoutMode)screenLayoutMode])
    {
        if (widgetInfo.widgetType == widgetType && !widgetInfo.isCustomWidget)
            return widgetInfo;
    }
    return nil;
}

- (NSArray<NSOrderedSet<OAMapWidgetInfo *> *> *)pagedWidgetsForPanel:(OAApplicationMode *)appMode
                                                               panel:(OAWidgetsPanel *)panel
                                                         filterModes:(NSInteger)filterModes
{
    return [self pagedWidgetsForPanel:appMode
                                panel:panel
                          filterModes:filterModes
                     screenLayoutMode:[ScreenLayoutModeWrapper defaultForAppMode:appMode]];
}

- (NSArray<NSOrderedSet<OAMapWidgetInfo *> *> *)pagedWidgetsForPanel:(OAApplicationMode *)appMode
                                                               panel:(OAWidgetsPanel *)panel
                                                         filterModes:(NSInteger)filterModes
                                                    screenLayoutMode:(int)screenLayoutMode
{
    MutableOrderedDictionary<NSNumber *, NSMutableOrderedSet<OAMapWidgetInfo *> *> *widgetsByPages = [MutableOrderedDictionary dictionary];
    NSNumber *layoutMode = [_settings.useSeparateLayouts get:appMode] ? @(screenLayoutMode) : nil;
    for (OAMapWidgetInfo *widgetInfo in [self widgetsForPanel:appMode filterModes:filterModes panels:@[panel] layoutMode:layoutMode])
    {
        NSInteger page = widgetInfo.pageIndex;
        NSMutableOrderedSet<OAMapWidgetInfo *> *widgetsOfPage = widgetsByPages[@(page)];
        if (!widgetsOfPage)
        {
            widgetsOfPage = [NSMutableOrderedSet orderedSet];
            [widgetsByPages setObject:widgetsOfPage forKey:@(page)];
        }
        [widgetsOfPage addObject:widgetInfo];
    }
    return widgetsByPages.allValues;
}

- (NSMutableOrderedSet<OAMapWidgetInfo *> *)widgetsForPanel:(OAApplicationMode *)appMode
                                                filterModes:(NSInteger)filterModes
                                                     panels:(NSArray<OAWidgetsPanel *> *)panels
                                                 layoutMode:(NSNumber *)layoutMode
{
    NSArray<OAMapWidgetInfo *> *widgetInfos = [self widgetsForAppMode:appMode layoutMode:layoutMode];
    return [self filteredWidgets:widgetInfos
                        appMode:appMode
                     layoutMode:layoutMode
                    filterModes:filterModes
                         panels:panels];
}

- (NSMutableOrderedSet<OAMapWidgetInfo *> *)filteredWidgets:(NSArray<OAMapWidgetInfo *> *)widgetInfos
                                                    appMode:(OAApplicationMode *)appMode
                                                 layoutMode:(NSNumber *)layoutMode
                                                filterModes:(NSInteger)filterModes
                                                     panels:(NSArray<OAWidgetsPanel *> *)panels
{
    NSMutableArray<Class> *includedWidgetTypes = [NSMutableArray array];
    if ([panels containsObject:OAWidgetsPanel.leftPanel] || [panels containsObject:OAWidgetsPanel.rightPanel])
    {
        [includedWidgetTypes addObject:OASideWidgetInfo.class];
        [includedWidgetTypes addObject:OASimpleWidgetInfo.class];
    }
    if ([panels containsObject:OAWidgetsPanel.topPanel] || [panels containsObject:OAWidgetsPanel.bottomPanel])
    {
        [includedWidgetTypes addObject:OACenterWidgetInfo.class];
        [includedWidgetTypes addObject:OASimpleWidgetInfo.class];
    }
    NSArray<NSString *> *widgetsVisibility = [OAMapWidgetInfo widgetsVisibility:appMode
                                                               screenLayoutMode:layoutMode];
    NSMutableOrderedSet<OAMapWidgetInfo *> *filteredWidgets = [NSMutableOrderedSet orderedSet];
    for (OAMapWidgetInfo *widget in widgetInfos)
    {
        if ([includedWidgetTypes containsObject:widget.class])
        {
            BOOL disabledMode = (filterModes & kWidgetModeDisabled) == kWidgetModeDisabled;
            BOOL enabledMode = (filterModes & kWidgetModeEnabled) == kWidgetModeEnabled;
            BOOL availableMode = (filterModes & KWidgetModeAvailable) == KWidgetModeAvailable;
            BOOL defaultMode = (filterModes & kWidgetModeDefault) == kWidgetModeDefault;
            BOOL matchingPanelsMode = (filterModes & kWidgetModeMatchingPanels) == kWidgetModeMatchingPanels;

            BOOL passDisabled = !disabledMode || ![widget isEnabledForAppMode:appMode widgetsVisibility:widgetsVisibility];
            BOOL passEnabled = !enabledMode || [widget isEnabledForAppMode:appMode widgetsVisibility:widgetsVisibility];
            BOOL passAvailable = !availableMode || [OAWidgetsAvailabilityHelper isWidgetAvailableWithWidgetId:widget.key appMode:appMode];
            BOOL defaultAvailable = !defaultMode || !widget.isCustomWidget;
            BOOL passMatchedPanels = !matchingPanelsMode || [panels containsObject:[widget getUpdatedPanel:appMode
                                                                        screenLayoutMode:layoutMode]];
            BOOL passTypeAllowed = [widget widgetType] == nil || [[widget widgetType] isAllowed];
            BOOL passPanelAllowed = [widget widgetType] == nil || [[widget widgetType] isPanelsAllowed:panels];
            
            if (passDisabled && passEnabled && passAvailable && defaultAvailable && passMatchedPanels && passTypeAllowed && passPanelAllowed)
                [filteredWidgets addObject:widget];
        }
    }
    return [NSMutableOrderedSet orderedSetWithArray:[filteredWidgets sortedArrayUsingDescriptors:@[[[NSSortDescriptor alloc] initWithKey:@"pageIndex" ascending:YES]]]];
}

- (BOOL) isWeatherToolbarVisible
{
    return [OARootViewController instance].mapPanel.hudViewController.mapInfoController.weatherToolbarVisible;
}

- (NSMutableOrderedSet<OAMapWidgetInfo *> *)widgetsForPanel:(OAWidgetsPanel *)panel
{
    NSMutableOrderedSet<OAMapWidgetInfo *> *widgets = _allWidgets[panel];
    if (widgets == nil)
    {
        widgets = [NSMutableOrderedSet orderedSet];
        _allWidgets[panel] = widgets;
    }
    return widgets;
}

- (void) registerAllControls
{
    OAApplicationMode *appMode = _settings.applicationMode.get;
    ScreenLayoutMode screenLayoutMode = [ScreenLayoutModeWrapper defaultForAppMode:appMode];
    NSArray<OAMapWidgetInfo *> *infos = [OAWidgetsInitializer createAllControlsWithAppMode:appMode screenLayoutMode:screenLayoutMode];
    [self reorderWidgets:infos];
    _cachedAppMode = appMode;
    _cachedScreenLayoutMode = screenLayoutMode;
    _cachedUseSeparateLayouts = [_settings.useSeparateLayouts get:appMode];
    
    for (OAMapWidgetInfo *widgetInfo : infos)
    {
        [self notifyWidgetRegistered:widgetInfo];
    }
}

@end
