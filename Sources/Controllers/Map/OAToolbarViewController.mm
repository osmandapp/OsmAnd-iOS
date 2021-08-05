//
//  OAToolbarViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 06/02/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAToolbarViewController.h"

@interface OAToolbarViewController ()

@end

@implementation OAToolbarViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.navBarView.layer setShadowColor:[UIColor blackColor].CGColor];
    [self.navBarView.layer setShadowOpacity:0.3];
    [self.navBarView.layer setShadowRadius:3.0];
    [self.navBarView.layer setShadowOffset:CGSizeMake(0.0, 0.0)];
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (int) getPriority
{
    return 0;
}

- (EOAToolbarAttentionLevel) getAttentionLevel
{
    return EOAToolbarAttentionLevelNormal;
}

- (void) onViewWillAppear:(EOAMapHudType)mapHudType
{
}

- (void)onViewDidAppear:(EOAMapHudType)mapHudType
{
}

- (void)onViewWillDisappear:(EOAMapHudType)mapHudType
{
}

- (void)onMapAzimuthChanged:(id)observable withKey:(id)key andValue:(id)value
{
}

- (void)onMapChanged:(id)observable withKey:(id)key
{
}

-(UIStatusBarStyle)getPreferredStatusBarStyle
{
    return UIStatusBarStyleDefault;
}

-(UIColor *)getStatusBarColor
{
    return nil;
}

-(void)updateFrame:(BOOL)animated
{
}

@end
