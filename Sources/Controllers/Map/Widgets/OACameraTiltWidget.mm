//
//  OACameraTiltWidget.m
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 03.03.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OACameraTiltWidget.h"
#import "OARootViewController.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"
#import "Localization.h"

@implementation OACameraTiltWidget
{
    OAMapRendererView *_rendererView;
    int _cachedMapTilt;
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        _cachedMapTilt = 0;
        _rendererView = [OARootViewController instance].mapPanel.mapViewController.mapView;
        [self setText:@"-" subtext:@"°"];
        [self setIcons:@"widget_developer_camera_tilt_day" widgetNightIcon:@"widget_developer_camera_tilt_night"];
        __weak OACameraTiltWidget *selfWeak = self;
        self.updateInfoFunction = ^BOOL{
            [selfWeak updateInfo];
            return NO;
        };
    }
    return self;
}

- (BOOL) updateInfo
{
    int mapTilt = [_rendererView elevationAngle];
    if (self.isUpdateNeeded || mapTilt != _cachedMapTilt)
        _cachedMapTilt = mapTilt;
    NSString *cachedMapTiltText = [NSString stringWithFormat:@"%d", _cachedMapTilt];
    [self setText:cachedMapTiltText subtext:@"°"];
    [self setIcons:@"widget_developer_camera_tilt_day" widgetNightIcon:@"widget_developer_camera_tilt_night"];
    [self addAccessibilityLabelsWithValue:cachedMapTiltText];
    return YES;
}

- (void) addAccessibilityLabelsWithValue:(NSString *)value
{
    self.accessibilityLabel = OALocalizedString(@"map_widget_camera_tilt");
    self.accessibilityValue = [NSString stringWithFormat: @"%@ °", value];
}

- (void) setImage:(UIImage *)image
{
    [self.imageView setImage:image.imageFlippedForRightToLeftLayoutDirection];
}

@end
