//
//  OARouteAvoidTransportSettingsViewController.m
//  OsmAnd
//
//  Created by Paul on 8/29/18.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OARouteAvoidTransportSettingsViewController.h"
#import "OARoutePreferencesParameters.h"
#import "OsmAndApp.h"
#import "OAAppSettings.h"
#import "Localization.h"
#import "OAFavoriteItem.h"
#import "OADefaultFavorite.h"
#import "OAColors.h"
#import "OADestinationItem.h"
#import "OADestinationsHelper.h"
#import "OARoutingHelper.h"
#import "OAVoiceRouter.h"
#import "OAFileNameTranslationHelper.h"
#import "OARouteProvider.h"
#import "OAGPXDocument.h"
#import "OASwitchTableViewCell.h"
#import "OATargetPointsHelper.h"
#import "OARTargetPoint.h"
#import "OARootViewController.h"
#import "OASelectedGPXHelper.h"
#import "OAGPXDatabase.h"
#import "OAMapActions.h"
#import "OAUtilities.h"
#import "OAAvoidSpecificRoads.h"

#include <OsmAndCore/Utilities.h>

@interface OARouteAvoidTransportSettingsViewController ()

@end

@implementation OARouteAvoidTransportSettingsViewController
{
    NSArray<OALocalRoutingParameter *> *_data;
}

-(void) applyLocalization
{
    [super applyLocalization];
    self.titleView.text = OALocalizedString(@"avoid_transport_type");
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    [self.tableView setDataSource:self];
    [self.tableView setDelegate:self];
    [self setCancelButtonAsImage];
    self.tableView.separatorInset = UIEdgeInsetsMake(0., 16.0, 0., 0.);
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
    _data = [self getAvoidRoutingParameters:[self.routingHelper getAppMode]];
}

- (void) updateParameters
{
    [self setupView];
    [self.tableView reloadData];
    if (self.delegate)
        [self.delegate onSettingsChanged];
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

- (void) addRoadPressed:(id)sender
{
    [[OARootViewController instance].mapPanel openTargetViewWithImpassableRoadSelection];
}

- (CGFloat) heightForRow:(NSIndexPath *)indexPath tableView:(UITableView *)tableView
{
    OALocalRoutingParameter *param = _data[indexPath.row];
    NSString *type = [param getCellType];
    
    if ([type isEqualToString:[OASwitchTableViewCell getCellIdentifier]])
    {
        return UITableViewAutomaticDimension;
    }
    else
    {
        return 48.0;
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _data.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0)
        return OALocalizedString(@"avoid_by_type");
    
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

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self heightForRow:indexPath tableView:tableView];
}

- (UITableViewCell *) cellForRoutingParam:(OALocalRoutingParameter *)param
{
    NSString *text = [param getText];
    NSString *type = [param getCellType];
    if ([type isEqualToString:[OASwitchTableViewCell getCellIdentifier]])
    {
        OASwitchTableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:[OASwitchTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASwitchTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASwitchTableViewCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            [cell.textView setText:text];
            [cell.switchView removeTarget:NULL action:NULL forControlEvents:UIControlEventAllEvents];
            [cell.switchView setOn:[param isChecked]];
            [param setControlAction:cell.switchView];
        }
        return cell;
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OALocalRoutingParameter *item = _data[indexPath.row];
    
    return [self cellForRoutingParam:item];
}

#pragma mark - UITableViewDelegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    OALocalRoutingParameter *param = _data[indexPath.row];
    
    [param rowSelectAction:tableView indexPath:indexPath];
    
    if (self.delegate)
        [self.delegate onSettingsChanged];
}

@end
