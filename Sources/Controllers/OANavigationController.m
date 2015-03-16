//
//  OANavigationController.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/29/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OANavigationController.h"
#import "OASuperViewController.h"
#import "OAIntroViewController.h"

@interface OANavigationController ()
@end

@implementation OANavigationController

-(instancetype)initWithRootViewController:(UIViewController *)rootViewController
{
    self = [super initWithRootViewController:rootViewController];
    if (self) {
        self.navigationBarHidden = YES;
    }
    return self;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    if (self.visibleViewController == nil)
        return [super preferredStatusBarStyle];

    return self.visibleViewController.preferredStatusBarStyle;
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

#pragma mark - Autorotation

- (BOOL)shouldAutorotate
{
    return YES;
}

- (NSUInteger) supportedInterfaceOrientations {
    if ([[self visibleViewController] isKindOfClass:[OAIntroViewController class]])
        return UIInterfaceOrientationMaskPortrait;
    return UIInterfaceOrientationMaskAll;
}

- (UIInterfaceOrientation) preferredInterfaceOrientationForPresentation {
    if ([[self visibleViewController] isKindOfClass:[OAIntroViewController class]])
        return UIInterfaceOrientationPortrait;
    return UIInterfaceOrientationPortrait | UIInterfaceOrientationLandscapeLeft | UIInterfaceOrientationLandscapeRight;
}

@end
