//
//  OAImpassableRoadViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 06/01/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAImpassableRoadViewController.h"
#import "Localization.h"

@interface OAImpassableRoadViewController ()

@end

@implementation OAImpassableRoadViewController

- (instancetype) initWithRoadId:(unsigned long long)roadId
{
    self = [super init];
    if (self)
    {
        _roadId = roadId;
    }
    return self;
}

- (NSString *) getCommonTypeStr
{
    return OALocalizedString(@"road_blocked");
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
