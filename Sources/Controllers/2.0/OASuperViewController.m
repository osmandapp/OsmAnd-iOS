//
//  OASuperViewController.m
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 06.11.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OASuperViewController.h"

@interface OASuperViewController ()

@end

@implementation OASuperViewController

- (void) viewDidLoad
{
    [super viewDidLoad];
    [self applyLocalization];
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) applyLocalization
{
    // override point
}

#pragma mark - Actions

- (BOOL)isModal
{
    if([self presentingViewController])
        return YES;
    if([[[self navigationController] presentingViewController] presentedViewController] == [self navigationController])
        return YES;
    if([[[self tabBarController] presentingViewController] isKindOfClass:[UITabBarController class]])
        return YES;

   return NO;
}

- (IBAction) backButtonClicked:(id)sender
{
    [self dismissViewController];
}

- (void) dismissViewController
{
    if ([self isModal])
        [self dismissViewControllerAnimated:YES completion:nil];
    else
        [self.navigationController popViewControllerAnimated:YES];
}

- (void) showViewController:(UIViewController *)viewController
{
    if ([self isModal])
        [self presentViewController:viewController animated:YES completion:nil];
    else
        [self.navigationController pushViewController:viewController animated:YES];
}


- (UIStatusBarStyle) preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (BOOL) prefersStatusBarHidden
{
    return NO;
}

@end
