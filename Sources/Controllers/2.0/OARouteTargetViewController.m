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
#import "OARTargetPoint.h"
#import "OAPointDescription.h"

@interface OARouteTargetViewController ()

@end

@implementation OARouteTargetViewController

- (instancetype) initWithTargetPoint:(OARTargetPoint *)targetPoint
{
    self = [super init];
    if (self)
    {
        _targetPoint = targetPoint;
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

@end
