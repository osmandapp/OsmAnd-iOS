//
//  OAMapUnderlayAction.m
//  OsmAnd
//
//  Created by Paul on 8/10/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAMapUnderlayAction.h"
#import "OAAppSettings.h"
#import "OsmAndApp.h"
#import "OAMapSource.h"
#import "Localization.h"

#define KEY_UNDERLAYS @"underlays"
#define KEY_NO_UNDERLAY @"no_underlay"

@implementation OAMapUnderlayAction

- (instancetype) init
{
    self = [super initWithType:EOAQuickActionTypeMapUnderlay];
    if (self)
    {
        [super commonInit];
    }
    return self;
}

- (void)execute
{
    NSArray<NSArray<NSString *> *> *sources = self.loadListFromParams;
    if (sources.count > 0)
    {
        BOOL showBottomSheetStyles = [self.getParams[KEY_DIALOG] boolValue];
        if (showBottomSheetStyles)
        {
            // TODO Show bottom sheet with map styles
            return;
        }
        
        NSInteger index = -1;
        NSString *name = [OsmAndApp instance].data.underlayMapSource.variant;
        NSString *currentSource = name ? name : KEY_NO_UNDERLAY;
        
        for (NSInteger idx = 0; idx < sources.count; idx++)
        {
            if ([sources[idx].firstObject isEqualToString:currentSource])
            {
                index = idx;
                break;
            }
        }
        
        NSArray<NSString *> *nextSource = sources[0];
        
        if (index >= 0 && index < sources.count - 1)
            nextSource = sources[index + 1];
        
        [self executeWithParams:nextSource.firstObject];
    }
}

- (void)executeWithParams:(NSString *)params
{
    OsmAndAppInstance app = [OsmAndApp instance];
    BOOL hasUnderlay = ![params isEqualToString:KEY_NO_UNDERLAY];
    if (hasUnderlay)
    {
        OAMapSource *newMapSource = nil;
        for (OAMapSource *mapSource in self.onlineMapSources)
        {
            if ([mapSource.variant isEqualToString:params])
            {
                newMapSource = mapSource;
                break;
            }
        }
        app.data.underlayMapSource = newMapSource;
    }
    else
    {
        app.data.underlayMapSource = nil;
    }
    // indicate change with toast?
}

- (NSString *)getTranslatedItemName:(NSString *)item
{
    if ([item isEqualToString:KEY_NO_UNDERLAY])
        return OALocalizedString(@"quick_action_no_underlay");
    else
        return item;
}

-(NSString *) getAddBtnText
{
    return OALocalizedString(@"quick_action_add_underlay");
}

- (NSString *)getDescrHint
{
    return OALocalizedString(@"quick_action_list_descr");
}

- (NSString *)getDescrTitle
{
    return OALocalizedString(@"map_underlays");
}

- (NSString *)getListKey
{
    return KEY_UNDERLAYS;
}

- (BOOL)fillParams:(NSDictionary *)model
{
    self.params = @{KEY_DIALOG : @(NO), KEY_UNDERLAYS : @"[[\"bing_earth\", \"Bing Earth\"], [\"bing_hybrid\", \"Bing hybtid\"], [\"no_underlay\", \"No Underlay\"]]"};
    return YES;
}

@end
