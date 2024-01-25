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
    NSMutableDictionary<OAWidgetsPanel *, NSMutableOrderedSet<OAMapWidgetInfo *> *> *_allWidgets;
    OAAppSettings *_settings;
    OAApplicationMode *_cachedAppMode;
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

    NSArray<NSOrderedSet<OAMapWidgetInfo *> *> *pagedWidgets = [self getPagedWidgetsForPanel:mode panel:widgetPanel filterModes:(KWidgetModeAvailable | kWidgetModeEnabled | kWidgetModeMatchingPanels)];
    if (weatherToolbarVisible && widgetPanel == OAWidgetsPanel.rightPanel)
    {
        NSArray *weatherWidgets = @[kWeatherTemp, kWeatherPressure, kWeatherWind, kWeatherCloud, kWeatherPrecip];
        NSMutableOrderedSet<OAMapWidgetInfo *> *pageWeatherWidget = [NSMutableOrderedSet orderedSet];
        int priority = 0;
        for (NSString *key in weatherWidgets) {
            NSPredicate *keyPredicate = [NSPredicate predicateWithFormat:@"key = %@", key];
            NSArray<OAMapWidgetInfo *> *filteredWidgets = [[self getAllWidgets] filteredArrayUsingPredicate:keyPredicate];
            if (filteredWidgets.count > 0)
            {
                OAMapWidgetInfo *item = filteredWidgets.firstObject;
                item.priority = priority;
                priority ++;
                [pageWeatherWidget addObject:filteredWidgets.firstObject];
            }
        }
        if (pageWeatherWidget.count > 0)
        {
            pagedWidgets = @[pageWeatherWidget];
        }
    }
    for (NSOrderedSet<OAMapWidgetInfo *> *page in pagedWidgets)
    {
        NSArray<OAMapWidgetInfo *> *sortedWidgets =
        [page.array sortedArrayUsingComparator:^NSComparisonResult(OAMapWidgetInfo * _Nonnull w1, OAMapWidgetInfo * _Nonnull w2) {
            return [OAUtilities compareInt:(int) w1.priority y:(int) w2.priority];
        }];
        for (OAMapWidgetInfo *widgetInfo in sortedWidgets)
        {
            if ([widgetInfo isEnabledForAppMode:mode] || weatherToolbarVisible)
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
    for (OAMapWidgetInfo *widgetInfo in [self getAllWidgets])
    {
        if ([widgetInfo isEnabledForAppMode:appMode])
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
    return [self getWidgetsForPanel:OAWidgetsPanel.leftPanel];
}

- (NSMutableOrderedSet<OAMapWidgetInfo *> *) getRightWidgets
{
    return [self getWidgetsForPanel:OAWidgetsPanel.rightPanel];
}

- (BOOL) isAnyWeatherWidgetVisible
{
    OAApplicationMode *mode = [_settings.applicationMode get];
    BOOL weatherToolbarVisible = self.isWeatherToolbarVisible;
    for (OAMapWidgetInfo *widgetInfo in OAMapWidgetRegistry.sharedInstance.getAllWidgets)
    {
        if (widgetInfo.getWidgetType.group == OAWidgetGroup.weather)
        {
            if (weatherToolbarVisible || [widgetInfo isEnabledForAppMode:mode])
                return YES;
        }
    }
    return NO;
}

- (void) updateInfo:(OAApplicationMode *)mode expanded:(BOOL)expanded
{
    BOOL weatherToolbarVisible = self.isWeatherToolbarVisible;
    for (OAMapWidgetInfo *widgetInfo in self.getAllWidgets)
    {
        BOOL enabledForAppMode = [widgetInfo isEnabledForAppMode:mode];
        if (enabledForAppMode || (weatherToolbarVisible && widgetInfo.getWidgetType.group == OAWidgetGroup.weather))
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

- (OAMapWidgetInfo *)getWidgetInfoForType:(OAWidgetType *)widgetType
{
    for (OAMapWidgetInfo *widgetInfo in self.getAllWidgets)
    {
        if (widgetInfo.getWidgetType == widgetType && ![widgetInfo.key containsString:OAMapWidgetInfo.DELIMITER])
            return widgetInfo;
    }
    return nil;
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
            [widgetsByPages setObject:widgetsOfPage forKey:@(page)];
        }
        [widgetsOfPage addObject:widgetInfo];
    }
    return widgetsByPages.allValues;
}

- (NSMutableOrderedSet<OAMapWidgetInfo *> *)getWidgetsForPanel:(OAApplicationMode *)appMode
                                                   filterModes:(NSInteger) filterModes
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
    NSMutableArray<OAMapWidgetInfo *> *widgetInfos = [NSMutableArray array];
    if (_cachedAppMode == appMode)
    {
        [widgetInfos addObjectsFromArray:self.getAllWidgets];
    }
    else
    {
        _cachedAppMode = appMode;
        [widgetInfos addObjectsFromArray:[OAWidgetsInitializer createAllControlsWithAppMode:appMode]];
    }
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

            BOOL passDisabled = !disabledMode || ![widget isEnabledForAppMode:appMode];
            BOOL passEnabled = !enabledMode || [widget isEnabledForAppMode:appMode];
            BOOL passAvailable = !availableMode || [OAWidgetsAvailabilityHelper isWidgetAvailableWithWidgetId:widget.key appMode:appMode];
            BOOL defaultAvailable = !defaultMode || !widget.isCustomWidget;
            BOOL passMatchedPanels = !matchingPanelsMode || [panels containsObject:widget.widgetPanel];
            BOOL passTypeAllowed = [widget getWidgetType] == nil || [[widget getWidgetType] isAllowed];

            if (passDisabled && passEnabled && passAvailable && defaultAvailable && passMatchedPanels && passTypeAllowed)
                [filteredWidgets addObject:widget];
        }
    }
    return [NSMutableOrderedSet orderedSetWithArray:[filteredWidgets sortedArrayUsingDescriptors:@[[[NSSortDescriptor alloc] initWithKey:@"pageIndex" ascending:YES]]]];
}

- (BOOL) isWeatherToolbarVisible
{
    return [OARootViewController instance].mapPanel.hudViewController.mapInfoController.weatherToolbarVisible;
}

- (NSMutableOrderedSet<OAMapWidgetInfo *> *)getWidgetsForPanel:(OAWidgetsPanel *)panel
{
    NSMutableOrderedSet<OAMapWidgetInfo *> *widgets = _allWidgets[panel];
    if (widgets == nil)
    {
        widgets = [NSMutableOrderedSet orderedSet];
        _allWidgets[panel] = widgets;
    }
    return widgets;
}

- (void) resetDefaultAppearance:(OAApplicationMode *)appMode
{
    [_settings.transparentMapTheme resetToDefault];
    [_settings.showStreetName resetToDefault];
    [_settings.positionPlacementOnMap resetToDefault];
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

@end
