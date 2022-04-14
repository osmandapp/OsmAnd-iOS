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

#define COLLAPSED_PREFIX @"+"
#define HIDE_PREFIX @"-"
#define SHOW_PREFIX @""
#define SETTINGS_SEPARATOR @";"

@implementation OAMapWidgetRegistry
{
    NSMutableOrderedSet<OAMapWidgetRegInfo *> *_leftWidgetSet;
    NSMutableOrderedSet<OAMapWidgetRegInfo *> *_rightWidgetSet;
    NSMapTable<OAApplicationMode *, NSMutableSet<NSString *> *> *_visibleElementsFromSettings;
    OAAppSettings *_settings;
    OAAutoObserverProxy* _widgetSettingResetObserver;
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        _leftWidgetSet = [NSMutableOrderedSet orderedSet];
        _rightWidgetSet = [NSMutableOrderedSet orderedSet];
        _visibleElementsFromSettings = [NSMapTable strongToStrongObjectsMapTable];
        _settings = [OAAppSettings sharedManager];
        [self loadVisibleElementsFromSettings];
        _widgetSettingResetObserver = [[OAAutoObserverProxy alloc] initWith:self withHandler:@selector(onWidgetSettingsReset:withKey:) andObserve:[OsmAndApp instance].widgetSettingResetObservable];
    }
    return self;
}

- (void) populateStackControl:(UIView *)stack mode:(OAApplicationMode *)mode left:(BOOL)left expanded:(BOOL)expanded
{
    NSOrderedSet<OAMapWidgetRegInfo *> *s = left ? [_leftWidgetSet copy] : [_rightWidgetSet copy];
    for (OAMapWidgetRegInfo *r in s)
    {
        if (r.widget && ([r visible:mode] || [r.widget isExplicitlyVisible]))
            [stack addSubview:r.widget];
    }
    if (expanded)
    {
        for (OAMapWidgetRegInfo *r in s)
        {
            if (r.widget && [r visibleCollapsed:mode] && ![r.widget isExplicitlyVisible])
                [stack addSubview:r.widget];
        }
    }
}

- (BOOL) hasCollapsibles:(OAApplicationMode *)mode
{
    for (OAMapWidgetRegInfo *r in _leftWidgetSet)
        if ([r visibleCollapsed:mode])
            return YES;

    for (OAMapWidgetRegInfo *r in _rightWidgetSet)
        if ([r visibleCollapsed:mode])
            return YES;

    return NO;
}

- (void) updateInfo:(OAApplicationMode *)mode expanded:(BOOL)expanded
{
    [self update:mode expanded:expanded widgetSet:_leftWidgetSet];
    [self update:mode expanded:expanded widgetSet:_rightWidgetSet];
}

- (void) update:(OAApplicationMode *)mode expanded:(BOOL)expanded widgetSet:(NSOrderedSet<OAMapWidgetRegInfo *> *)widgetSet
{
    for (OAMapWidgetRegInfo *r in widgetSet)
        if (r.widget && ([r visible:mode] || ([r visibleCollapsed:mode] && expanded)))
            [r.widget updateInfo];
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
    NSMutableOrderedSet<OAMapWidgetRegInfo *> *newSet = [NSMutableOrderedSet orderedSet];
    for (OAMapWidgetRegInfo *r in _leftWidgetSet)
        if (r.widget != widget)
            [newSet addObject:r];

    _leftWidgetSet = newSet;
    
    newSet = [NSMutableOrderedSet orderedSet];
    for (OAMapWidgetRegInfo *r in _rightWidgetSet)
        if (r.widget != widget)
            [newSet addObject:r];

    _rightWidgetSet = newSet;
}

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

- (OAMapWidgetRegInfo *) registerSideWidgetInternal:(OATextInfoWidget *)widget imageId:(NSString *)imageId message:(NSString *)message key:(NSString *)key left:(BOOL)left priorityOrder:(int)priorityOrder
{
    OAMapWidgetRegInfo *ii = [[OAMapWidgetRegInfo alloc] initWithKey:key widget:widget imageId:imageId message:message priorityOrder:priorityOrder left:left];
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
        BOOL collapse = [ms isWidgetCollapsible:key];
        BOOL def = [ms isWidgetVisible:key];
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
    [_settings.centerPositionOnMap resetToDefault];
}

- (void) updateVisibleWidgets
{
    [self loadVisibleElementsFromSettings];
    for (OAMapWidgetRegInfo *ri in _leftWidgetSet)
        [self processVisibleModes:ri.key ii:ri];
    for (OAMapWidgetRegInfo *ri in _leftWidgetSet)
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
