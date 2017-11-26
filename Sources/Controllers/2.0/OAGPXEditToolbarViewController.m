//
//  OAGPXEditToolbarViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 19/08/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAGPXEditToolbarViewController.h"
#import "Localization.h"

@interface OAGPXEditToolbarViewController ()

@end

@implementation OAGPXEditToolbarViewController


-(void) applyLocalization
{
    [super applyLocalization];
    
    self.titleView.text = OALocalizedString(@"add_waypoint_short");
}

- (void) viewDidLoad
{
    [super viewDidLoad];

}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) okPressed
{
    if (self.delegate)
        [self.delegate addWaypoint];
}

- (void) cancelPressed
{
    if (self.delegate)
        [self.delegate btnCancelPressed];
}

- (BOOL) hasContent
{
    return NO;
}

- (BOOL) hasRouteButton
{
    return NO;
}

-(BOOL) hasTopToolbar
{
    return YES;
}

-(BOOL) shouldShowToolbar:(BOOL)isViewVisible
{
    return YES;
}

@end
