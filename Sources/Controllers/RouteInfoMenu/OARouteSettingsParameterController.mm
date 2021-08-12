//
//  OARouteSettingsParameterController.m
//  OsmAnd
//
//  Created by Paul on 8/29/18.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OARouteSettingsParameterController.h"
#import "OARoutePreferencesParameters.h"
#import "OsmAndApp.h"
#import "OAAppSettings.h"
#import "Localization.h"
#import "OAFavoriteItem.h"
#import "OADefaultFavorite.h"
#import "OAColors.h"
#import "OARoutingHelper.h"
#import "OAUtilities.h"
#import "OASettingsTitleTableViewCell.h"

@interface OARouteSettingsParameterController ()

@end

@implementation OARouteSettingsParameterController
{
    OALocalRoutingParameterGroup *_group;
}

- (instancetype) initWithParameterGroup:(OALocalRoutingParameterGroup *) group
{
    self = [super init];
    if (self) {
        _group = group;
    }
    return self;
}

-(void) applyLocalization
{
    [super applyLocalization];
    self.titleView.text = _group.getText;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    [self.tableView setDataSource:self];
    [self.tableView setDelegate:self];
    self.tableView.separatorInset = UIEdgeInsetsMake(0., 16.0, 0., 0.);
    self.tableView.contentInset = UIEdgeInsetsMake(10., 0., 0., 0.);
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
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.tableView reloadData];
}

- (void)backButtonClicked:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)doneButtonPressed
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _group.getRoutingParameters.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.001;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.001;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OALocalRoutingParameter *param = _group.getRoutingParameters[indexPath.row];
    NSString *text = [param getText];
    
    OASettingsTitleTableViewCell* cell = nil;
    cell = [tableView dequeueReusableCellWithIdentifier:[OASettingsTitleTableViewCell getCellIdentifier]];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASettingsTitleTableViewCell getCellIdentifier] owner:self options:nil];
        cell = (OASettingsTitleTableViewCell *)[nib objectAtIndex:0];
    }
    
    if (cell)
    {
        [cell.textView setText:text];
        if (_group.getSelected == param)
            [cell.iconView setImage:[UIImage imageNamed:@"menu_cell_selected.png"]];
        else
            [cell.iconView setImage:nil];
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    for (NSInteger i = 0; i < _group.getRoutingParameters.count; i++)
    {
        OALocalRoutingParameter *param = _group.getRoutingParameters[i];
        [param setSelected:i == indexPath.row];
    }
    [self.routingHelper recalculateRouteDueToSettingsChange];
    [tableView reloadData];
}

@end
