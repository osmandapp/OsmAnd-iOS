//
//  OADebugSettings.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/31/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OADebugSettings.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"

#include <OsmAndCore.h>

@implementation OADebugSettings

- (instancetype)init
{
    self = [super init];
    if (self) {
        _useRawSpeedAndAltitudeOnHUD = NO;
        _setAllResourcesAsOutdated = NO;
        _textureFilteringQuality = 1;
    }
    return self;
}

@synthesize useRawSpeedAndAltitudeOnHUD = _useRawSpeedAndAltitudeOnHUD;
@synthesize setAllResourcesAsOutdated = _setAllResourcesAsOutdated;

-(void)setTextureFilteringQuality:(int)textureFilteringQuality
{
    _textureFilteringQuality = textureFilteringQuality;
 
    OAMapViewController* mapVC = [OARootViewController instance].mapPanel.mapViewController;
    OAMapRendererView* mapRendererView = (OAMapRendererView*)mapVC.view;
    [mapRendererView setTextureFilteringQuality:(OsmAnd::TextureFilteringQuality)_textureFilteringQuality];
    
}

@end
