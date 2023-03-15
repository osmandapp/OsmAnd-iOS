//
//  OASunsetWidget.m
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 09.03.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OASunsetWidget.h"
#import "OASunriseSunsetWidgetHelper.h"
#import "OAAppSettings.h"

@implementation OASunsetWidget
{
    OAAppSettings *_settings;
    NSArray<NSString *> *_sunsetItems;
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        _settings = [OAAppSettings sharedManager];
        
        __weak OASunsetWidget *selfWeak = self;
        self.updateInfoFunction = ^BOOL{
            [selfWeak updateInfo];
            return NO;
        };
        self.onClickFunction = ^(id sender) {
            [selfWeak onWidgetClicked];
        };
        
        [self setText:@"-" subtext:@""];
        [self setIcons:@"widget_sunset_day" widgetNightIcon:@"widget_sunset_night"];
    }
    return self;
}

- (BOOL) updateInfo
{
    if ([_settings.sunsetMode get] == EOASunriseSunsetTimeLeft)
        _sunsetItems = [OASunriseSunsetWidgetHelper getTimeLeftUntilSunriseSunset:NO];
    else
        _sunsetItems = [OASunriseSunsetWidgetHelper getNextSunriseSunset:NO];
    
    [self setText:_sunsetItems.firstObject subtext:_sunsetItems.lastObject];
    return YES;
}

- (void) onWidgetClicked
{
    if ([_settings.sunsetMode get] != EOASunriseSunsetTimeLeft)
        [_settings.sunsetMode set:EOASunriseSunsetTimeLeft];
    else
        [_settings.sunsetMode set:EOASunriseSunsetNext];
    [self updateInfo];
}

@end
