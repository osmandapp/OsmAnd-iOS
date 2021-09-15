//
//  OAEditGPXColorViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 08/06/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAEditGPXColorViewController.h"
#import "OAIconTextTableViewCell.h"
#include "Localization.h"

@implementation OAEditGPXColorViewController
{
    OAGPXTrackColorCollection *_colorCollection;
    NSInteger _colorIndex;
}

- (id) initWithColorValue:(NSInteger)colorValue colorsCollection:(OAGPXTrackColorCollection *)collection
{
    self = [super init];
    if (self)
    {
        _colorCollection = collection;
        OAGPXTrackColor *gpxColor = [collection getColorForValue:colorValue];
        _colorIndex = [[collection getAvailableGPXColors] indexOfObject:gpxColor];
    }
    return self;
}

- (void)applyLocalization
{
    [_titleView setText:OALocalizedString(@"fav_color")];
    [_saveButton setTitle:OALocalizedString(@"shared_string_save") forState:UIControlStateNormal];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupView];
}

-(UIView *) getTopView
{
    return _navBarView;
}

-(UIView *) getMiddleView
{
    return _tableView;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)setupView
{
    [self applySafeAreaMargins];
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
    return [[_colorCollection getAvailableGPXColors] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OAIconTextTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OAIconTextTableViewCell getCellIdentifier]];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAIconTextTableViewCell getCellIdentifier] owner:self options:nil];
        cell = (OAIconTextTableViewCell *) nib[0];
        cell.iconViewWidthConstraint.constant = 20.;
        cell.iconViewHeightConstraint.constant = 20.;
    }
    
    if (cell) {
        
        OAGPXTrackColor *gpxColor = [_colorCollection getAvailableGPXColors][indexPath.row];
        [cell.textView setText:gpxColor.name];
        
        cell.iconView.layer.cornerRadius = cell.iconViewHeightConstraint.constant / 2;
        cell.iconView.backgroundColor = gpxColor.color;
        cell.textLeftMarginNoImage.constant = 50.;
        [cell.arrowIconView setImage:[UIImage imageNamed:@"menu_cell_selected"]];
        cell.arrowIconView.hidden = indexPath.row != _colorIndex;
    }
    return cell;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    _colorIndex = indexPath.row;
    [self.tableView reloadData];
}

#pragma mark - Actions

- (IBAction)saveClicked:(id)sender
{
    if (self.delegate)
        [self.delegate trackColorChanged:_colorIndex];
    
    [self backButtonClicked:self];
}

@end
