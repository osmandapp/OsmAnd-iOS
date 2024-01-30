//
//  OATargetDistanceWidget.m
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 03.03.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OATargetDistanceWidget.h"
#import "OARootViewController.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"
#import "OAOsmAndFormatter.h"
#import "Localization.h"
#import "OsmAnd_Maps-Swift.h"

@implementation OATargetDistanceWidget
{
    OAMapRendererView *_rendererView;
    float _cachedTargetDistance;
}

- (instancetype)initWithСustomId:(NSString *)customId
                         appMode:(OAApplicationMode *)appMode
{
    self = [super initWithType:OAWidgetType.devTargetDistance];
    if (self)
    {
        [self configurePrefsWithId:customId appMode:appMode widgetParams:nil];
        _cachedTargetDistance = -1;
        _rendererView = [OARootViewController instance].mapPanel.mapViewController.mapView;
        [self setText:@"-" subtext:@""];
        [self setIcon:@"widget_developer_target_distance"];
        
        __weak OATargetDistanceWidget *selfWeak = self;
        self.updateInfoFunction = ^BOOL{
            [selfWeak updateInfo];
            return NO;
        };
    }
    return self;
}

- (BOOL) updateInfo
{
    float targetDistance = [self getTargetDistanceInMeters];
    if (self.isUpdateNeeded || targetDistance != _cachedTargetDistance)
    {
        _cachedTargetDistance = targetDistance;
        NSString *text = _cachedTargetDistance > 0 ? [self formatDistance:_cachedTargetDistance] : @"-";
        [self setText:text subtext:@""];
        [self setIcon:@"widget_developer_target_distance"];
    }
    return YES;
}

- (float) getTargetDistanceInMeters
{
    return [_rendererView getTargetDistanceInMeters];
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
