//
//  OAEditColorViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 08/06/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAEditColorViewController.h"
#import "OAViewTextTableViewCell.h"
#import "OADefaultFavorite.h"
#import "OAUtilities.h"
#import "OsmAndApp.h"
#include "Localization.h"

@implementation OAEditColorViewController

- (id) initWithColor:(UIColor *)color
{
    self = [super init];
    if (self)
    {
        OAFavoriteColor *favCol = [OADefaultFavorite nearestFavColor:color];
        self.colorIndex = [[OADefaultFavorite builtinColors] indexOfObject:favCol];
    }
    return self;
}

- (void)applyLocalization
{
    [_titleView setText:OALocalizedString(@"fav_color")];
    [_backButton setTitle:OALocalizedString(@"shared_string_back") forState:UIControlStateNormal];
    [_saveButton setTitle:OALocalizedString(@"shared_string_save") forState:UIControlStateNormal];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _saveChanges = NO;
    
    [self setupView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)setupView
{
    [self.tableView setDataSource:self];
    [self.tableView setDelegate:self];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return OALocalizedString(@"fav_colors");
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[OADefaultFavorite builtinColors] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* const reusableIdentifierPoint = @"OAViewTextTableViewCell";
    
    OAViewTextTableViewCell* cell;
    cell = (OAViewTextTableViewCell *)[self.tableView dequeueReusableCellWithIdentifier:reusableIdentifierPoint];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAViewTextCell" owner:self options:nil];
        cell = (OAViewTextTableViewCell *)[nib objectAtIndex:0];
    }
    
    if (cell) {
        
        OAFavoriteColor *favCol = [OADefaultFavorite builtinColors][indexPath.row];
        [cell.textView setText:favCol.name];
        [cell.titleIcon setImage:favCol.icon];
        [cell.iconView setImage:nil];
        
        if (indexPath.row == self.colorIndex)
            [cell.iconView setImage:[UIImage imageNamed:@"menu_cell_selected"]];
    }
    return cell;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    self.colorIndex = indexPath.row;
    [self.tableView reloadData];
}

#pragma mark - Actions

- (IBAction)saveClicked:(id)sender
{
    _saveChanges = YES;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(colorChanged)])
        [self.delegate colorChanged];
    
    [self backButtonClicked:self];
}

@end
