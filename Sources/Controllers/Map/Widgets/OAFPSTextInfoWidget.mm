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
#import "OAMapPanelViewController.h"
#import "OAMapRendererView.h"
#import "Localization.h"

#import "OsmAnd_Maps-Swift.h"

#define WIDGET_REFRESHING_INTERVAL_SECONDS 1.0

@implementation OAFPSTextInfoWidget
{
    OAMapRendererView *_rendererView;
    NSTimer *_timer;
    float _lastUpdatingMs;
    int _lastUpdatingFrameId;
}

- (instancetype)initWithСustomId:(NSString *)customId
                         appMode:(OAApplicationMode *)appMode
                    widgetParams:(NSDictionary * _Nullable)widgetParams;
{
    self = [super initWithType:OAWidgetType.devFps];
    if (self)
    {
        [self configurePrefsWithId:customId appMode:appMode widgetParams:widgetParams];
        _lastUpdatingMs = 0;
        _lastUpdatingFrameId = 0;
        _rendererView = [OARootViewController instance].mapPanel.mapViewController.mapView;
        [self setText:@"-" subtext:@"FPS"];
        [self setIcon:@"widget_fps"];
        
        __weak OAFPSTextInfoWidget *selfWeak = self;
        self.onClickFunction = ^(id sender) {
            [selfWeak onWidgetClicked];
        };
        self.updateInfoFunction = ^BOOL{
            [selfWeak onExternalUpdate];
            return NO;
        };
    }
    return self;
}

- (void) onExternalUpdate
{
    if ([self isVisible] && !_timer)
        [self startRefreshingTimer];
    else if (![self isVisible] && _timer)
        [self stopRefreshingTimer];
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
    if (_timer && [_timer isValid])
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
    [self setIcon:@"widget_fps"];
    return YES;
}

- (void) onWidgetClicked
{
    [self onExternalUpdate];
}

@end
