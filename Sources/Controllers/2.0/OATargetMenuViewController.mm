//
//  OATargetMenuViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 29/05/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OATargetMenuViewController.h"

@interface OATargetMenuViewController ()

@end

@implementation OATargetMenuViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    _navBar.hidden = YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (IBAction)buttonOKPressed:(id)sender
{
    [self okPressed];
}

- (IBAction)buttonCancelPressed:(id)sender
{
    [self cancelPressed];
}

- (void)okPressed
{
    // override
}

- (void)cancelPressed
{
    // override
}

- (CGFloat)contentHeight
{
    return 0.0; // override
}

- (void)setContentBackgroundColor:(UIColor *)color
{
    _contentView.backgroundColor = color;
}

-(BOOL)hasTopToolbar
{
    return NO; // override
}

- (BOOL)shouldShowToolbar:(BOOL)isViewVisible;
{
    return NO; // override
}

- (BOOL)supportEditing
{
    return NO; // override
}

- (void)activateEditing
{
    // override
}

- (BOOL)commitChangesAndExit
{
    return YES; // override
}

@end
