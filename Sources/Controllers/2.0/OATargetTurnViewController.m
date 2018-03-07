//
//  OATargetTurnViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 27/08/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OATargetTurnViewController.h"
#import "Localization.h"

@interface OATargetTurnViewController ()

@end

@implementation OATargetTurnViewController

- (NSString *) getCommonTypeStr
{
    return OALocalizedString(@"shared_string_turn");
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
