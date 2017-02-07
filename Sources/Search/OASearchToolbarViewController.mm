//
//  OASearchToolbarViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 06/02/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OASearchToolbarViewController.h"

@interface OASearchToolbarViewController ()

@end

@implementation OASearchToolbarViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.titleButton setTitle:self.toolbarTitle forState:UIControlStateNormal];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

-(void)setToolbarTitle:(NSString *)toolbarTitle
{
    _toolbarTitle = toolbarTitle;
    if (self.titleButton)
        [self.titleButton setTitle:toolbarTitle forState:UIControlStateNormal];
}

-(int)getPriority
{
    return SEARCH_TOOLBAR_PRIORITY;
}

-(UIColor *)getStatusBarColor
{
    return [UIColor whiteColor];
}

- (void)updateFrame:(BOOL)animated
{
    self.view.frame = CGRectMake(0.0, [self.delegate toolbarTopPosition], DeviceScreenWidth, self.navBarView.bounds.size.height);
    [self.delegate toolbarLayoutDidChange:self animated:animated];
}

- (IBAction)backPress:(id)sender
{
    if (self.searchDelegate)
        [self.searchDelegate searchToolbarOpenSearch];
}

- (IBAction)titlePress:(id)sender
{
    if (self.searchDelegate)
        [self.searchDelegate searchToolbarOpenSearch];
}

- (IBAction)closePress:(id)sender
{
    if (self.searchDelegate)
        [self.searchDelegate searchToolbarClose];
}


@end
