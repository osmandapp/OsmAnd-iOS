//
//  OAMapOpacitySliderToggler.m
//  OsmAnd Maps
//
//  Created by nnngrach on 12.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OAMapOpacitySliderToggler.h"
#import "OARootViewController.h"
#import "OAAppSettings.h"

@implementation OAMapOpacitySliderToggler
{
     OAAppSettings *_settings;
}


static OAMapOpacitySliderToggler *sharedSingleton_ = nil;

+ (OAMapOpacitySliderToggler *) sharedInstance
{
    if (sharedSingleton_ == nil)
    {
        sharedSingleton_ = [[OAMapOpacitySliderToggler alloc] init];
        [sharedSingleton_ initParameters];
    }
    return sharedSingleton_;
}


- (void) initParameters
{
    _settings = [OAAppSettings sharedManager];
}



- (BOOL)isOpacitySliderEnabled
{
    return [_settings mapSettingShowOpacitySlider];
}

- (void)setIsOpacitySliderEnabled: (BOOL)isEnabled
{
    [_settings setMapSettingShowOpacitySlider:isEnabled];
}


- (void)showOpacitySlider
{
    [[OARootViewController instance].mapPanel updateOverlayUnderlayView:[self isOpacitySliderEnabled]];
}

@end
