//
//  OARouteSettingsViewController.m
//  OsmAnd
//
//  Created by Paul on 8/29/18.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OARouteSettingsViewController.h"
#import "OARoutePreferencesParameters.h"
#import "OsmAndApp.h"
#import "OAAppSettings.h"
#import "Localization.h"
#import "OAFavoriteItem.h"
#import "OADefaultFavorite.h"
#import "OAColors.h"
#import "OARoutingHelper.h"
#import "OASettingsTableViewCell.h"
#import "OAUtilities.h"
#import "OASettingSwitchCell.h"
#import "OAIconTitleValueCell.h"

@interface OARouteSettingsViewController ()

@end

@implementation OARouteSettingsViewController
{
    NSDictionary *_data;
}

-(void) applyLocalization
{
    [super applyLocalization];
    self.titleView.text = OALocalizedString(@"shared_string_options");
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    [self.tableView setDataSource:self];
    [self.tableView setDelegate:self];
    self.tableView.separatorInset = UIEdgeInsetsMake(0., 16.0, 0., 0.);
    self.tableView.contentInset = UIEdgeInsetsMake(10., 0., 0., 0.);
    self.tableView.estimatedRowHeight = kEstimatedRowHeight;
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

- (void) generateData
{
    _data = [NSDictionary dictionaryWithDictionary:[self getRoutingParameters:[self.routingHelper getAppMode]]];
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
    return _data.count;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return ((NSArray *)_data[@(section)]).count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0)
        return nil;
    else if (section == 1)
        return OALocalizedString(@"route_parameters");
    else if (section == 2)
        return OALocalizedString(@"osm_edits_advanced");
    
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.001;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    NSString *headerText = [self tableView:tableView titleForHeaderInSection:section];
    if (!headerText)
    {
        return 0.001;
    }
    else
    {
        CGFloat height = [OAUtilities calculateTextBounds:headerText width:tableView.bounds.size.width font:[UIFont systemFontOfSize:13.]].height;
        return MAX(38.0, height + 10.0);
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OALocalRoutingParameter *param = _data[@(indexPath.section)][indexPath.row];
    NSString *text = [param getText];
    //NSString *description = [param getDescription];
    NSString *value = [param getValue];
    //UIImage *icon = [param getIcon];
    NSString *type = [param getCellType];
    OAApplicationMode *appMode = [self.routingHelper getAppMode];
    
    if ([type isEqualToString:[OASettingsTableViewCell getCellIdentifier]])
    {
        OASettingsTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:[OASettingsTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASettingsTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASettingsTableViewCell *)[nib objectAtIndex:0];
        }
        
        if (cell) {
            [cell.textView setText:text];
            [cell.descriptionView setText:value];
        }
        cell.backgroundColor = UIColor.redColor;
        return cell;
    }
    else if ([type isEqualToString:@"OASettingSwitchCell"])
    {
        static NSString* const identifierCell = @"OASettingSwitchCell";
        OASettingSwitchCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OASettingSwitchCell" owner:self options:nil];
            cell = (OASettingSwitchCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            [cell.switchView removeTarget:NULL action:NULL forControlEvents:UIControlEventAllEvents];
            [cell.switchView setOn:[param isChecked]];
            cell.textView.text = text;
            cell.descriptionView.text = nil;
            cell.descriptionView.hidden = YES;
            [cell setSecondaryImage:param.getSecondaryIcon];
            cell.imgView.image = [param.getIcon imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.imgView.tintColor = [param isChecked] ? UIColorFromRGB([appMode getIconColor]) : UIColorFromRGB(color_icon_inactive);
            [param setControlAction:cell.switchView];
            cell.separatorInset = UIEdgeInsetsMake(0., 62., 0., 0.);
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            if ([cell needsUpdateConstraints])
                [cell setNeedsUpdateConstraints];
        }
        return cell;
    }
    else if ([type isEqualToString:[OAIconTitleValueCell getCellIdentifier]])
    {
        OAIconTitleValueCell* cell = [tableView dequeueReusableCellWithIdentifier:[OAIconTitleValueCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAIconTitleValueCell getCellIdentifier] owner:self options:nil];
            cell = (OAIconTitleValueCell *)[nib objectAtIndex:0];
        }
        if (cell)
        {
            cell.textView.text = text;
            cell.descriptionView.hidden = !value || value.length == 0;
            cell.descriptionView.text = value;
            cell.iconView.tintColor = UIColorFromRGB(color_tint_gray);
            cell.leftImageView.image = [param.getIcon imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.leftImageView.tintColor = UIColorFromRGB([appMode getIconColor]);
            cell.separatorInset = UIEdgeInsetsMake(0., 62., 0., 0.);
        }
        return cell;
    }

    return nil;
}

#pragma mark - UITableViewDelegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    OALocalRoutingParameter *param = _data[@(indexPath.section)][indexPath.row];
    [param rowSelectAction:tableView indexPath:indexPath];
}

@end
