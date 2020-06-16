//
//  OACreateProfileViewController.m
//  OsmAnd
//
//  Created by Paul on 8/29/18.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OACreateProfileViewController.h"
#import "Localization.h"
#import "OAColors.h"


#include <generalRouter.h>

@interface OACreateProfileViewController () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation OACreateProfileViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    return [super initWithNibName:@"OACreateProfileViewController" bundle:nil];
}

- (instancetype) init
{
    self = [super init];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void) commonInit
{
    [self generateData];
}

- (void) generateData
{
}

-(void) applyLocalization
{
    [_backButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    _tableView.delegate = self;
    _tableView.dataSource = self;
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setupView];
}

- (void) setupView
{
}

- (void)backButtonClicked:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


-(void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    UITableViewHeaderFooterView *vw = (UITableViewHeaderFooterView *) view;
    [vw.textLabel setTextColor:UIColorFromRGB(color_text_footer)];
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    return nil;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
}


@end
