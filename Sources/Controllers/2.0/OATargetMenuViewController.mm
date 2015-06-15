//
//  OATargetMenuViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 29/05/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OATargetMenuViewController.h"
#import "OAUtilities.h"

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

- (void)useGradient:(BOOL)gradient
{
    if (self.titleGradient && gradient)
    {
        self.titleGradient.hidden = NO;
        self.navBar.backgroundColor = [UIColor clearColor];
    }
    else
    {
        self.titleGradient.hidden = YES;
        self.navBar.backgroundColor = UIColorFromRGB(0xFF8F00);
    }
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
