//
//  OASunriseWidget.m
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 09.03.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OASunriseWidget.h"
#import "OASunriseSunsetWidgetHelper.h"
#import "OAAppSettings.h"

@implementation OASunriseWidget
{
    OAAppSettings *_settings;
    NSArray<NSString *> *_sunriseItems;
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        _settings = [OAAppSettings sharedManager];
        
        __weak OASunriseWidget *selfWeak = self;
        self.updateInfoFunction = ^BOOL{
            [selfWeak updateInfo];
            return NO;
        };
        self.onClickFunction = ^(id sender) {
            [selfWeak onWidgetClicked];
        };
        
        [self setText:@"-" subtext:@""];
        [self setIcons:@"widget_sunrise_day" widgetNightIcon:@"widget_sunrise_night"];
    }
    return self;
}

- (BOOL) updateInfo
{
    if ([_settings.sunriseMode get] == EOASunriseSunsetTimeLeft)
        _sunriseItems = [OASunriseSunsetWidgetHelper getTimeLeftUntilSunriseSunset:YES];
    else
        _sunriseItems = [OASunriseSunsetWidgetHelper getNextSunriseSunset:YES];
    
    [self setText:_sunriseItems.firstObject subtext:_sunriseItems.lastObject];
    return YES;
}

- (void) onWidgetClicked
{
    if ([_settings.sunriseMode get] != EOASunriseSunsetTimeLeft)
        [_settings.sunriseMode set:EOASunriseSunsetTimeLeft];
    
    else
        [_settings.sunriseMode set:EOASunriseSunsetNext];
    [self updateInfo];
}

@end
