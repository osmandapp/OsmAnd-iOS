//
//  OAImpassableRoadViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 06/01/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAImpassableRoadViewController.h"
#import "Localization.h"
#import "OAAvoidRoadInfo.h"

@interface OAImpassableRoadViewController ()

@end

@implementation OAImpassableRoadViewController

- (instancetype) initWithRoadInfo:(OAAvoidRoadInfo *)roadInfo
{
    self = [super init];
    if (self)
    {
        _roadInfo = roadInfo;
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

- (BOOL)denyClose
{
    return YES;
}

- (ETopToolbarType) topToolbarType
{
    return ETopToolbarTypeFloating;
}

- (BOOL)hasDismissButton
{
    return YES;
}

- (BOOL)offerMapDownload
{
    return NO;
}

@end
