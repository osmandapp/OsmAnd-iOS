//
//  OAFPSTextInfoWidget.m
//  OsmAnd Maps
//
//  Created by nnngrach on 19.10.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OAFPSTextInfoWidget.h"
#import "OARootViewController.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"

#define WIDGET_REFRESHING_INTERVAL_SECONDS 1.0

@implementation OAFPSTextInfoWidget
{
    OAMapRendererView *_rendererView;
    NSTimer *_timer;
    float _lastUpdatingMs;
    int _lastUpdatingFrameId;
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        _lastUpdatingMs = 0;
        _lastUpdatingFrameId = 0;
        _rendererView = [OARootViewController instance].mapPanel.mapViewController.mapView;
        
        __weak OAFPSTextInfoWidget *selfWeak = self;
        self.onClickFunction = ^(id sender) {
            [selfWeak onWidgetClicked];
        };
        
        [self startRefreshingTimer];
    }
    return self;
}

//  Launches only on widget turning on. But not on turning off.
- (BOOL) updateVisibility:(BOOL)visible
{   
    [self startRefreshingTimer];
    return [super updateVisibility:visible];
}

- (void) startRefreshingTimer
{
    if (!_timer)
    {
        _timer = [NSTimer scheduledTimerWithTimeInterval:WIDGET_REFRESHING_INTERVAL_SECONDS target:self selector:@selector(updateWidget) userInfo:nil repeats:YES];
    }
}

- (void) stopRefreshingTimer
{
    if ([_timer isValid])
        [_timer invalidate];
    _timer = nil;
}

- (BOOL) updateWidget
{
    if (![self isVisible])
    {
        [self stopRefreshingTimer];
        return YES;
    }
    
    int frameId = [_rendererView getFrameId];
    NSTimeInterval now = CACurrentMediaTime();
    NSString *fps = @"0";
    
    if (frameId > _lastUpdatingFrameId)
    {
        float fpsValue = 1.0 / (now - _lastUpdatingMs) * (frameId - _lastUpdatingFrameId);
        fps = [NSString stringWithFormat:@"%.1f", fpsValue];
    }
    _lastUpdatingMs = now;
    _lastUpdatingFrameId = frameId;
    
    [self setText:fps subtext:@"FPS"];
    [self setIcons:@"widget_fps_day" widgetNightIcon:@"widget_fps_night"];
    return YES;
}

- (void) onWidgetClicked
{
    [self updateWidget];
}

@end
