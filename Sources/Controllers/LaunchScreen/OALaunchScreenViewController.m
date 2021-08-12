//
//  OALaunchScreenViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 27/12/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OALaunchScreenViewController.h"

@interface OALaunchScreenViewController ()

@end

@implementation OALaunchScreenViewController

- (instancetype) init
{
    self = [[OALaunchScreenViewController alloc] initWithNibName:@"OALaunchScreenViewController" bundle:nil];
    if (self)
    {
        self.view.frame = [UIScreen mainScreen].bounds;
    }
    return self;
}

- (instancetype) initWithFrame:(CGRect)frame
{
    self = [[OALaunchScreenViewController alloc] initWithNibName:@"OALaunchScreenViewController" bundle:nil];
    if (self)
    {
        self.view.frame = [UIScreen mainScreen].bounds;
    }
    return self;
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

- (BOOL) prefersStatusBarHidden
{
    return YES;
}

@end
