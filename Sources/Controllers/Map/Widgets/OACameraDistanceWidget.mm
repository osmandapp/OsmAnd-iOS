//
//  OACameraDistanceWidget.m
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 03.03.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OACameraDistanceWidget.h"
#import "OARootViewController.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"
#import "OAOsmAndFormatter.h"
#import "OAAppSettings.h"
#import "Localization.h"
#import "OsmAnd_Maps-Swift.h"

@implementation OACameraDistanceWidget
{
    OAMapRendererView *_rendererView;
    OAAppSettings *_settings;
    int _cachedCameraDistance;
}

- (instancetype)initWithСustomId:(NSString *)customId
                         appMode:(OAApplicationMode *)appMode
{
    self = [super initWithType:OAWidgetType.devCameraDistance];
    if (self)
    {
        [self configurePrefsWithId:customId appMode:appMode widgetParams:nil];
        _cachedCameraDistance = -1;
        _settings = [OAAppSettings sharedManager];
        _rendererView = [OARootViewController instance].mapPanel.mapViewController.mapView;
        [self setText:@"-" subtext:@""];
        [self setIcon:@"widget_developer_camera_distance"];
        
        __weak OACameraDistanceWidget *selfWeak = self;
        self.updateInfoFunction = ^BOOL{
            [selfWeak updateInfo];
            return NO;
        };
    }
    return self;
}

- (BOOL) updateInfo
{
    float cameraDistance = [self getCameraHeightInMeters];
    if (self.isUpdateNeeded || cameraDistance != _cachedCameraDistance)
    {
        _cachedCameraDistance = cameraDistance;
        NSString *text = _cachedCameraDistance > 0 ? [self formatDistance:_cachedCameraDistance] : @"-";
        [self setText:text subtext:@""];
        [self setIcon:@"widget_developer_camera_distance"];
    }
    return YES;
}

- (float) getCameraHeightInMeters
{
    return [_rendererView getCameraHeightInMeters];
}

- (NSString *) formatDistance: (float) distanceInMeters
{
    return [OAOsmAndFormatter getFormattedDistance:distanceInMeters forceTrailingZeroes:NO];
}

- (void) setImage:(UIImage *)image
{
    [super setImage:image.imageFlippedForRightToLeftLayoutDirection];
}

@end
