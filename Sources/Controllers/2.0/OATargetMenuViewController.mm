//
//  OATargetMenuViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 29/05/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OATargetMenuViewController.h"
#import "OAUtilities.h"

@implementation OATargetMenuViewControllerState

@end

@interface OATargetMenuViewController ()

@end

@implementation OATargetMenuViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    _navBar.hidden = YES;
    _actionButtonPressed = NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (IBAction)buttonOKPressed:(id)sender
{
    _actionButtonPressed = YES;
    [self okPressed];
}

- (IBAction)buttonCancelPressed:(id)sender
{
    _actionButtonPressed = YES;
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

- (BOOL)hasContent
{
    return YES; // override
}

- (CGFloat)contentHeight
{
    return 0.0; // override
}

- (void)setContentBackgroundColor:(UIColor *)color
{
    _contentView.backgroundColor = color;
}

- (BOOL)showTopControls
{
    return NO;
}

- (BOOL)supportMapInteraction
{
    return NO; // override
}

- (BOOL)supportFullMenu
{
    return YES; // override
}

- (BOOL)supportFullScreen
{
    return NO; // override
}

-(BOOL)fullScreenWithoutHeader
{
    return NO; // override
}

- (void)goHeaderOnly
{
    // override
}

- (void)goFull
{
    // override
}

- (void)goFullScreen
{
    // override
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
        self.navBarBackground.hidden = YES;
    }
    else
    {
        self.titleGradient.hidden = YES;
        self.navBarBackground.hidden = NO;
    }
}

- (BOOL)disablePanWhileEditing
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

- (BOOL)preHide
{
    return YES; // override
}

- (id)getTargetObj
{
    return nil; // override
}

- (OATargetMenuViewControllerState *)getCurrentState
{
    return nil; // override
}

@end
