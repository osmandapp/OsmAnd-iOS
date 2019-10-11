//
//  OARouteTripSettingsViewController.m
//  OsmAnd
//
//  Created by Paul on 8/29/18.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OARouteTripSettingsViewController.h"
#import "OARoutePreferencesParameters.h"
#import "OsmAndApp.h"
#import "OAAppSettings.h"
#import "Localization.h"
#import "OAColors.h"
#import "OARoutingHelper.h"
#import "OAVoiceRouter.h"
#import "OAFileNameTranslationHelper.h"
#import "OARouteProvider.h"
#import "OAGPXDocument.h"
#import "OASwitchTableViewCell.h"
#import "OARootViewController.h"
#import "OASelectedGPXHelper.h"
#import "OAGPXDatabase.h"
#import "OAUtilities.h"
#import "OAIconTextButtonCell.h"
#import "OAGPXDatabase.h"
#import "OAMultiIconTextDescCell.h"
#import "OAMapActions.h"
#import "OATargetPointsHelper.h"


@interface OARouteTripSettingsViewController ()

@end

@implementation OARouteTripSettingsViewController
{
    NSDictionary *_data;
}

-(void) applyLocalization
{
    [super applyLocalization];
    self.titleView.text = OALocalizedString(@"gpx_navigation");
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    [self.tableView setDataSource:self];
    [self.tableView setDelegate:self];
    [self setCancelButtonAsImage];
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
    NSMutableDictionary *model = [NSMutableDictionary new];
    NSInteger section = 0;
    [model setObject:[self getRoutingParametersGpx:[self.routingHelper getAppMode]] forKey:@(section++)];
    
    NSArray *gpxList = [[[OAGPXDatabase sharedDb] gpxList] sortedArrayUsingComparator:^NSComparisonResult(OAGPX *obj1, OAGPX *obj2) {
        return [obj2.importDate compare:obj1.importDate];
    }];
    [model setObject:gpxList forKey:@(section++)];
    
    _data = [NSDictionary dictionaryWithDictionary:model];
}

- (void) setupView
{
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

- (NSString *) getDescription:(OAGPX *)gpx
{
    NSString *dist = [[OsmAndApp instance] getFormattedDistance:gpx.totalDistance];
    NSString *wpts = [NSString stringWithFormat:@"%@: %d", OALocalizedString(@"gpx_waypoints"), gpx.wptPoints];
    return [NSString stringWithFormat:@"%@ • %@", dist, wpts];
}

- (void) updateParameters
{
    [self generateData];
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

- (CGFloat) heightForRow:(NSIndexPath *)indexPath tableView:(UITableView *)tableView
{
    id param = _data[@(indexPath.section)][indexPath.row];
    NSString *type;
    NSString *text;
    NSString *value;
    if ([param isKindOfClass:OALocalRoutingParameter.class])
    {
        type = [param getCellType];
        text = [param getText];
        value = [param getValue];
    }
    else if ([param isKindOfClass:OAGPX.class])
    {
        OAGPX *gpx = (OAGPX *)param;
        type = @"OAMultiIconTextDescCell";
        text = [gpx getNiceTitle];
        value = [self getDescription:gpx];
    }
    
    if ([type isEqualToString:@"OASwitchCell"])
    {
        return [OASwitchTableViewCell getHeight:text cellWidth:tableView.bounds.size.width];
    }
    else if ([type isEqualToString:@"OAMultiIconTextDescCell"])
    {
        return [OAMultiIconTextDescCell getHeight:text value:value cellWidth:DeviceScreenWidth];
    }
    else
    {
        return 44.0;
    }
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
        return OALocalizedString(@"shared_string_options");
    else if (section == 1)
        return OALocalizedString(@"menu_all_trips");
    return nil;
}

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self heightForRow:indexPath tableView:tableView];
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self heightForRow:indexPath tableView:tableView];
}

- (UITableViewCell *) cellForRoutingParam:(OALocalRoutingParameter *)param
{
    NSString *text = [param getText];
    NSString *type = [param getCellType];
    if ([type isEqualToString:@"OASwitchCell"])
    {
        static NSString* const identifierCell = @"OASwitchTableViewCell";
        OASwitchTableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OASwitchCell" owner:self options:nil];
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
    id item = _data[@(indexPath.section)][indexPath.row];
    if ([item isKindOfClass:OALocalRoutingParameter.class])
    {
        return [self cellForRoutingParam:(OALocalRoutingParameter *)item];
        
    }
    else if ([item isKindOfClass:OAGPX.class])
    {
        OAGPX *gpx = (OAGPX *)item;
        OAMultiIconTextDescCell* cell;
        cell = (OAMultiIconTextDescCell *)[tableView dequeueReusableCellWithIdentifier:@"OAMultiIconTextDescCell"];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAMultiIconTextDescCell" owner:self options:nil];
            cell = (OAMultiIconTextDescCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            [cell.textView setText:gpx.getNiceTitle];
            [cell.descView setText:[self getDescription:gpx]];
            [cell.iconView setImage:[UIImage imageNamed:@"ic_custom_trip"]];
            
            OAGPXRouteParamsBuilder *currentGPXRoute = [self.routingHelper getCurrentGPXRoute];
            if (currentGPXRoute && [currentGPXRoute.file.fileName isEqualToString:gpx.gpxFileName])
                [cell.overflowButton setImage:[UIImage imageNamed:@"menu_cell_selected.png"] forState:UIControlStateNormal];
            else
                [cell.overflowButton setImage:nil forState:UIControlStateNormal];
            cell.overflowButton.userInteractionEnabled = NO;
            cell.separatorInset = UIEdgeInsetsMake(0.0, 62.0, 0.0, 0.0);
        }
        return cell;
    }

    return nil;
}

#pragma mark - UITableViewDelegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    id param = _data[@(indexPath.section)][indexPath.row];
    if ([param isKindOfClass:OALocalRoutingParameter.class])
    {
        [param rowSelectAction:tableView indexPath:indexPath];
    }
    else if ([param isKindOfClass:OAGPX.class])
    {
        OAGPX *gpx = (OAGPX *)param;
        OAGPXRouteParamsBuilder *currentGPXRoute = [self.routingHelper getCurrentGPXRoute];
        
        if (currentGPXRoute && [currentGPXRoute.file.fileName isEqualToString:gpx.gpxFileName])
        {
            [self.routingHelper setGpxParams:nil];
            self.settings.followTheGpxRoute = nil;
            [self.routingHelper recalculateRouteDueToSettingsChange];
            [self updateParameters];
        }
        else
        {
            [[OAAppSettings sharedManager] showGpx:@[gpx.gpxFileName]];
            [[OARootViewController instance].mapPanel.mapActions setGPXRouteParams:gpx];
            [self updateParameters];
            [self.routingHelper recalculateRouteDueToSettingsChange];
            [[OATargetPointsHelper sharedInstance] updateRouteAndRefresh:YES];
        }
    }
    
}

@end
