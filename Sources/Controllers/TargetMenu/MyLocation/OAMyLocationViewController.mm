//
//  OAMyLocationViewController.m
//  OsmAnd
//
//  Created by Alexey on 06/07/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAMyLocationViewController.h"
#import "Localization.h"

@interface OAMyLocationViewController ()

@end

@implementation OAMyLocationViewController

- (NSString *) getCommonTypeStr
{
    return OALocalizedString(@"sett_arr_loc");
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
