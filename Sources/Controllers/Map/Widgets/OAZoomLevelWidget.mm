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
#import "OsmAnd_Maps-Swift.h"

@implementation OAZoomLevelWidget
{
    OAMapRendererView *_rendererView;
    float _cachedZoom;
}

- (instancetype)initWithСustomId:(NSString *)customId
                         appMode:(OAApplicationMode *)appMode
                    widgetParams:(NSDictionary *)widgetParams
{
    self = [super initWithType:OAWidgetType.devZoomLevel];
    if (self)
    {
        [self configurePrefsWithId:customId appMode:appMode widgetParams:widgetParams];
        _rendererView = [OARootViewController instance].mapPanel.mapViewController.mapView;
        [self setText:@"-" subtext:@""];
        [self setIcon:@"widget_developer_map_zoom"];
        
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
    BOOL isZoomChangeBigEnough = ABS(int(_cachedZoom * 100) - int(newZoom * 100)) > 1; //update with 0.01 step
    if (self.isUpdateNeeded || isZoomChangeBigEnough)
    {
        _cachedZoom = newZoom;
        NSString *cachedZoomText = [NSString stringWithFormat:@"%.2f", _cachedZoom];
        [self setText:cachedZoomText subtext:@""];
        [self setIcon:@"widget_developer_map_zoom"];
    }
    return YES;
}

- (void) setImage:(UIImage *)image
{
    [super setImage:image.imageFlippedForRightToLeftLayoutDirection];
}

@end
