//
//  OASearchToolbarViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 06/02/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OASearchToolbarViewController.h"
#import "OAPOIUIFilter.h"

@interface OASearchToolbarViewController ()

@end

@implementation OASearchToolbarViewController
{
    OAPOIUIFilter *_filter;
}

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
    self.view.frame = CGRectMake(0.0, [self.delegate toolbarTopPosition], DeviceScreenWidth - OAUtilities.getLeftMargin * 2, self.navBarView.bounds.size.height);
    [self.delegate toolbarLayoutDidChange:self animated:animated];
}

- (void) setFilter:(OAPOIUIFilter *)filter
{
    _filter = filter;
}

- (IBAction)backPress:(id)sender
{
    if (self.searchDelegate)
        [self.searchDelegate searchToolbarOpenSearch:_filter];
}

- (IBAction)titlePress:(id)sender
{
    if (self.searchDelegate)
        [self.searchDelegate searchToolbarOpenSearch:_filter];
}

- (IBAction)closePress:(id)sender
{
    if (self.searchDelegate)
        [self.searchDelegate searchToolbarClose];
}


@end
