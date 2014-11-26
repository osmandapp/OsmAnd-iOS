//
//  OANavigationController.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/29/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OANavigationController.h"
#import "OASuperViewController.h"

@interface OANavigationController ()
@end

@implementation OANavigationController

- (UIStatusBarStyle)preferredStatusBarStyle
{
    if (self.visibleViewController == nil)
        return [super preferredStatusBarStyle];

    return self.visibleViewController.preferredStatusBarStyle;
}


#pragma mark - Autorotation

- (NSUInteger) supportedInterfaceOrientations {
    if ([[self visibleViewController] isKindOfClass:[OASuperViewController class]])
        return UIInterfaceOrientationMaskPortrait;
    return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskLandscapeLeft;
    
}

- (UIInterfaceOrientation) preferredInterfaceOrientationForPresentation {
    if ([[self visibleViewController] isKindOfClass:[OASuperViewController class]])
        return UIInterfaceOrientationPortrait;
    return UIInterfaceOrientationPortrait | UIInterfaceOrientationLandscapeLeft | UIInterfaceOrientationLandscapeRight;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[self visibleViewController] isKindOfClass:[OASuperViewController class]])
        return UIInterfaceOrientationIsPortrait(interfaceOrientation);
    return YES;
}

@end
