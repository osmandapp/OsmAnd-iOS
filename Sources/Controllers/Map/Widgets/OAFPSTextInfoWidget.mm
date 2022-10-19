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

#define HALF_FRAME_BUFFER_LENGTH 20
#define WIDGET_REFRESHING_INTERVAL_SECONDS 0.1

@implementation OAFPSTextInfoWidget
{
    OAMapRendererView *_rendererView;
    NSTimer *_timer;
    long _startMs;
    int _startFrameId;
    long _middleMs;
    int _middleFrameId;
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        _startMs = 0;
        _startFrameId = 0;
        _middleMs = 0;
        _middleFrameId = 0;
        OAMapViewController *mapVC = [OARootViewController instance].mapPanel.mapViewController;
        _rendererView = (OAMapRendererView*)mapVC.view;
        
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
        _timer = [NSTimer scheduledTimerWithTimeInterval:WIDGET_REFRESHING_INTERVAL_SECONDS target:self selector:@selector(updateInfo) userInfo:nil repeats:YES];
    }
}

- (void) stopRefreshingTimer
{
    if ([_timer isValid])
        [_timer invalidate];
    _timer = nil;
}

- (BOOL) updateInfo
{
    if (![self isVisible])
    {
        [self stopRefreshingTimer];
        return YES;
    }
    
    int frameId = [_rendererView getFrameId];
    NSTimeInterval now = [[NSDate alloc] init].timeIntervalSince1970;
    NSString *fps = @"-";
    
    if (frameId > _startFrameId && now > _startMs && _startMs != 0)
    {
        float fpsValue = 1.0 / (now - _startMs) * (frameId - _startFrameId);
        fps = [NSString stringWithFormat:@"%.1f", fpsValue];
    }
    if (_startFrameId == 0 || (_middleFrameId - _startFrameId) > HALF_FRAME_BUFFER_LENGTH)
    {
        _startMs = _middleMs;
        _startFrameId = _middleFrameId;
    }
    if (_middleFrameId == 0 || (frameId - _middleFrameId) > HALF_FRAME_BUFFER_LENGTH)
    {
        _middleMs = now;
        _middleFrameId = frameId;
    }
    
    [self setText:fps subtext:@"FPS"];
    [self setIcons:@"widget_time_day" widgetNightIcon:@"widget_time_night"];
    return YES;
}

- (void) onWidgetClicked
{
    [self updateInfo];
}

@end
