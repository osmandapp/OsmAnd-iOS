//
//  OAZoomLevelWidget.m
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 03.03.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OAZoomLevelWidget.h"
#import "OARootViewController.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"
#import "Localization.h"

@implementation OAZoomLevelWidget
{
    OAMapRendererView *_rendererView;
    int _cachedZoom;
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        _rendererView = [OARootViewController instance].mapPanel.mapViewController.mapView;
        [self setText:@"-" subtext:@""];
        [self setIcons:@"widget_developer_map_zoom_day" widgetNightIcon:@"widget_developer_map_zoom_night"];
        
        __weak OAZoomLevelWidget *selfWeak = self;
        self.updateInfoFunction = ^BOOL{
            [selfWeak updateInfo];
            return NO;
        };
    }
    return self;
}

- (BOOL) updateInfo
{
    float newZoom = [_rendererView zoom];
    if (self.isUpdateNeeded || newZoom != _cachedZoom)
    {
        _cachedZoom = newZoom;
        NSString *cachedZoomText = [NSString stringWithFormat:@"%d", _cachedZoom];
        [self setText:cachedZoomText subtext:@""];
        [self setIcons:@"widget_developer_map_zoom_day" widgetNightIcon:@"widget_developer_map_zoom_night"];
    }
    return YES;
}

- (void) setImage:(UIImage *)image
{
    [super setImage:image.imageFlippedForRightToLeftLayoutDirection];
}

@end
