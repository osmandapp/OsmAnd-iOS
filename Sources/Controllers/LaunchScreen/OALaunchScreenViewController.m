//
//  OALaunchScreenViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 27/12/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OALaunchScreenViewController.h"
#import "OAIAPHelper.h"

@interface OALaunchScreenViewController ()

@end

@implementation OALaunchScreenViewController

- (instancetype) init
{
    self = [super initWithNibName:@"OALaunchScreenViewController" bundle:nil];
    if (self)
    {
        self.view.frame = [UIScreen mainScreen].bounds;
    }
    return self;
}

- (instancetype) initWithFrame:(CGRect)frame
{
    self = [super initWithNibName:@"OALaunchScreenViewController" bundle:nil];
    if (self)
    {
        self.view.frame = [UIScreen mainScreen].bounds;
    }
    return self;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    if ([OAIAPHelper isOsmAndProAvailable])
    {
        self.appNameImageView.image = [UIImage imageNamed:@"img_text_osmand_maps_pro"];
        [self animateImageView];
    }
    else if ([OAIAPHelper isFullVersionPurchased] || [OAIAPHelper isSubscribedToMaps])
    {
        self.appNameImageView.image = [UIImage imageNamed:@"img_text_osmand_maps_plus"];
        [self animateImageView];
    }
    else
    {
        self.appNameImageView.image = [UIImage imageNamed:@"img_text_osmand_maps"];
    }
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

- (void) animateImageView
{
    self.appNameImageView.alpha = 0.0;
    [UIView animateWithDuration:0.5 animations:^{
        self.appNameImageView.alpha = 1.0;
    }];
}

@end
