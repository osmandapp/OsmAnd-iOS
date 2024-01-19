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
#import "OsmAnd_Maps-Swift.h"

@implementation OACameraTiltWidget
{
    OAMapRendererView *_rendererView;
    int _cachedMapTilt;
}

- (instancetype)initWithСustomId:(NSString *)customId
                         appMode:(OAApplicationMode *)appMode
{
    self = [super initWithType:OAWidgetType.devCameraTilt];
    if (self)
    {
        [self configurePrefsWithId:customId appMode:appMode];
        _cachedMapTilt = 0;
        _rendererView = [OARootViewController instance].mapPanel.mapViewController.mapView;
        [self setText:@"-" subtext:@"°"];
        [self setIcon:@"widget_developer_camera_tilt"];
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
    [self setIcon:@"widget_developer_camera_tilt"];
    return YES;
}

- (void) setImage:(UIImage *)image
{
    [super setImage:image.imageFlippedForRightToLeftLayoutDirection];
}

@end
