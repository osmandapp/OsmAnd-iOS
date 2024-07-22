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
#import "OsmAnd_Maps-Swift.h"
#import "OARoutingHelper.h"
#import "OAValueTableViewCell.h"
#import "OAUtilities.h"
#import "OASwitchTableViewCell.h"
#import "OASizes.h"
#import "GeneratedAssetSymbols.h"

@interface OARouteSettingsViewController ()

@end

@implementation OARouteSettingsViewController
{
    NSDictionary *_data;
}

-(void) applyLocalization
{
    [super applyLocalization];
    self.navigationItem.title = OALocalizedString(@"shared_string_settings");
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
        return OALocalizedString(@"tab_title_advanced");
    
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
        CGFloat height = [OAUtilities calculateTextBounds:headerText width:tableView.bounds.size.width font:[UIFont preferredFontForTextStyle:UIFontTextStyleFootnote]].height;
        return MAX(38.0, height + 10.0);
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OALocalRoutingParameter *param = _data[@(indexPath.section)][indexPath.row];
    NSString *text = [param getText];
    //NSString *description = [param getDescription];
    NSString *value = [param isKindOfClass:OAHazmatRoutingParameter.class]
            ? OALocalizedString([param isSelected] ? @"shared_string_yes" : @"shared_string_no")
            : [param getValue];
    //UIImage *icon = [param getIcon];
    NSString *type = [param getCellType];
    OAApplicationMode *appMode = [self.routingHelper getAppMode];
    
    if ([type isEqualToString:[OAValueTableViewCell getCellIdentifier]])
    {
        OAValueTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:[OAValueTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAValueTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAValueTableViewCell *)[nib objectAtIndex:0];
            [cell descriptionVisibility:NO];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        
        if (cell)
        {
            [cell.titleLabel setText:text];
            [cell valueVisibility:value || value.length > 0];
            [cell.valueLabel setText:value];
            cell.leftIconView.image = [param isKindOfClass:OAHazmatRoutingParameter.class] ? [param getIcon] : [[param getIcon] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.leftIconView.tintColor = [appMode getProfileColor];
        }
        return cell;
    }
    else if ([type isEqualToString:[OASwitchTableViewCell getCellIdentifier]])
    {
        OASwitchTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OASwitchTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASwitchTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASwitchTableViewCell *) nib[0];
            cell.separatorInset = UIEdgeInsetsMake(0., kPaddingToLeftOfContentWithIcon, 0., 0.);
            [cell descriptionVisibility:NO];
        }
        if (cell)
        {
            [cell.switchView removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
            [cell.switchView setOn:[param isChecked]];
            [param setControlAction:cell.switchView];

            cell.titleLabel.text = text;
            cell.leftIconView.image = [param.getIcon imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.leftIconView.tintColor = [param isChecked] ? [appMode getProfileColor] : [UIColor colorNamed:ACColorNameIconColorDisabled];

            BOOL showDivider = [param hasOptions];
            [cell dividerVisibility:showDivider];
            cell.selectionStyle = showDivider ? UITableViewCellSelectionStyleDefault : UITableViewCellSelectionStyleNone;
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
