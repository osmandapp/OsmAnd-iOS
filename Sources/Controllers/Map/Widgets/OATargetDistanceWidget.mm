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

@implementation OATargetDistanceWidget
{
    OAMapRendererView *_rendererView;
    float _cachedTargetDistance;
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        _cachedTargetDistance = -1;
        _rendererView = [OARootViewController instance].mapPanel.mapViewController.mapView;
        [self setText:@"-" subtext:@""];
        [self setIcons:@"widget_developer_target_distance_day" widgetNightIcon:@"widget_developer_target_distance_night"];
        
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
        [self setIcons:@"widget_developer_target_distance_day" widgetNightIcon:@"widget_developer_target_distance_night"];
        [self addAccessibilityLabelsWithValue:text];
    }
    return YES;
}

- (float) getTargetDistanceInMeters
{
    return [_rendererView getTargetDistanceInMeters];
}

- (NSString *) formatDistance: (float) distanceInMeters
{
    return [OAOsmAndFormatter getFormattedDistance:distanceInMeters];
}

- (void) addAccessibilityLabelsWithValue:(NSString *)value
{
    self.accessibilityLabel = OALocalizedString(@"map_widget_target_distance");
    self.accessibilityValue = value;
}

- (void) setImage:(UIImage *)image
{
    [self.imageView setImage:image.imageFlippedForRightToLeftLayoutDirection];
}

@end
