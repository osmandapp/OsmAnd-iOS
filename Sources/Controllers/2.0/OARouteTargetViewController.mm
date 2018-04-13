//
//  OARouteTargetViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 31/08/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OARouteTargetViewController.h"
#import "Localization.h"
#import "OARootViewController.h"
#import "OAMapActions.h"
#import "OARTargetPoint.h"
#import "OAPointDescription.h"
#import "OATargetPointsHelper.h"
#import "OARoutingHelper.h"

@interface OARouteTargetViewController ()

@end

@implementation OARouteTargetViewController
{
    OATargetPointsHelper *_targetPointsHelper;
    OARoutingHelper *_routingHelper;
}

- (instancetype) initWithTargetPoint:(OARTargetPoint *)targetPoint
{
    self = [super init];
    if (self)
    {
        _targetPointsHelper = [OATargetPointsHelper sharedInstance];
        _routingHelper = [OARoutingHelper sharedInstance];
        
        _targetPoint = targetPoint;
        
        NSInteger intermediatePointsCount = [_targetPointsHelper getIntermediatePoints].count;
        BOOL nav = [_routingHelper isRoutePlanningMode] || [_routingHelper isFollowingMode];

        self.leftControlButton = [[OATargetMenuControlButton alloc] init];
        if (nav && intermediatePointsCount == 0 && !targetPoint.start)
        {
            self.leftControlButton.title = OALocalizedString(@"cancel_navigation");
        }
        else
        {
            self.leftControlButton.title = OALocalizedString(@"shared_string_remove");
        }
    }
    return self;
}

- (BOOL) supportFullScreen
{
    return YES;
}

- (NSString *) getCommonTypeStr
{
    if (_targetPoint.start)
        return OALocalizedString(@"starting_point");
    else
        return [_targetPoint getPointDescription].typeName;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    [self applyTopToolbarTargetTitle];
}

- (BOOL) hasTopToolbar
{
    return YES;
}

- (BOOL) shouldShowToolbar
{
    return YES;
}

- (ETopToolbarType) topToolbarType
{
    return ETopToolbarTypeFloating;
}

- (void) leftControlButtonPressed
{
    NSInteger intermediatePointsCount = [_targetPointsHelper getIntermediatePoints].count;
    BOOL nav = [_routingHelper isRoutePlanningMode] || [_routingHelper isFollowingMode];

    if (_targetPoint.start)
        [_targetPointsHelper clearStartPoint:YES];
    else if (_targetPoint.intermediate)
        [_targetPointsHelper removeWayPoint:YES index:_targetPoint.index];
    else
        [_targetPointsHelper removeWayPoint:YES index:-1];

    [[OARootViewController instance].mapPanel targetHide];
    if (nav && intermediatePointsCount == 0 && !_targetPoint.start)
    {
        [[OARootViewController instance].mapPanel.mapActions stopNavigationWithoutConfirm];
        [_targetPointsHelper clearStartPoint:NO];
    }
}

@end
