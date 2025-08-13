//
//  OARouteAvoidSettingsViewController.m
//  OsmAnd
//
//  Created by Paul on 8/29/18.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OARouteAvoidSettingsViewController.h"
#import "OARoutePreferencesParameters.h"
#import "OsmAndApp.h"
#import "OAAppSettings.h"
#import "Localization.h"
#import "OAFavoriteItem.h"
#import "OADefaultFavorite.h"
#import "OsmAnd_Maps-Swift.h"
#import "OADestinationItem.h"
#import "OADestinationsHelper.h"
#import "OARoutingHelper.h"
#import "OAVoiceRouter.h"
#import "OAFileNameTranslationHelper.h"
#import "OARouteProvider.h"
#import "OASwitchTableViewCell.h"
#import "OATargetPointsHelper.h"
#import "OARTargetPoint.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapViewController.h"
#import "OASelectedGPXHelper.h"
#import "OAGPXDatabase.h"
#import "OAMapActions.h"
#import "OAUtilities.h"
#import "OAAvoidSpecificRoads.h"
#import "OASimpleTableViewCell.h"
#import "OAButtonTableViewCell.h"
#import "OAOsmAndFormatter.h"
#import "GeneratedAssetSymbols.h"

#include <OsmAndCore/Utilities.h>
#include <binaryRead.h>

@interface OARouteAvoidSettingsViewController ()

@end

@implementation OARouteAvoidSettingsViewController
{
    NSDictionary *_data;
    OAAvoidSpecificRoads *_avoidRoads;
    
    UIView *_tableHeaderView;
}

-(void) applyLocalization
{
    [super applyLocalization];
    self.navigationItem.title = OALocalizedString(@"impassable_road");
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    [self.tableView setDataSource:self];
    [self.tableView setDelegate:self];
    [self.tableView setEditing:YES];
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
    
    [self setCancelButtonAsImage];
    [self setupView];
}

- (void) generateData
{
    _avoidRoads = [OAAvoidSpecificRoads instance];
    NSMutableDictionary *model = [NSMutableDictionary new];
    NSMutableArray *sectionData = [NSMutableArray new];
    NSInteger section = 0;
    
    NSArray<OAAvoidRoadInfo *> *roads = [_avoidRoads getImpassableRoads];
    if (roads.count > 0)
    {
        NSMutableArray *roadList = [NSMutableArray array];
        for (OAAvoidRoadInfo *r in roads)
        {
            [roadList addObject:@{ @"title"  : r.name ? r.name : OALocalizedString(@"shared_string_road"),
                                   @"key"    : @"road",
                                   @"roadId" : @((unsigned long long)r.roadId),
                                   @"descr"  : [self.class getDescr:r],
                                   @"header" : @"",
                                   @"type"   : [OASimpleTableViewCell getCellIdentifier]} ];
        }
        
        [sectionData addObjectsFromArray:roadList];
    }
    
    [sectionData addObject:@{
        @"title" : OALocalizedString(@"shared_string_select_on_map"),
        @"type" : [OAButtonTableViewCell getCellIdentifier],
        @"key" : @"select_on_map"
    }];
    
    [model setObject:[NSArray arrayWithArray:sectionData] forKey:@(section++)];
    [sectionData removeAllObjects];
    
    [model setObject:[NSArray arrayWithArray:[self getAvoidRoutingParameters:[self.routingHelper getAppMode]]] forKey:@(section)];
    
    _data = [NSDictionary dictionaryWithDictionary:model];
}

- (void) updateParameters
{
    [self setupView];
    [self.tableView reloadData];
    if (self.delegate)
        [self.delegate onSettingsChanged];
}

+ (NSString *) getDescr:(OAAvoidRoadInfo *)roadInfo
{
    CLLocation *mapLocation = [[OARootViewController instance].mapPanel.mapViewController getMapLocation];
    float dist = [mapLocation distanceFromLocation:roadInfo.location];
    return [OAOsmAndFormatter getFormattedDistance:dist];
}

- (void) setupView
{
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.tableHeaderView = [OAUtilities setupTableHeaderViewWithText:OALocalizedString(@"select_avoid_descr") font:kHeaderDescriptionFont textColor:[UIColor colorNamed:ACColorNameTextColorSecondary] isBigTitle:NO parentViewWidth:self.view.frame.size.width];
    self.tableView.tableHeaderView.backgroundColor = [UIColor colorNamed:ACColorNameViewBg];
    [self.tableView reloadData];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        if (_tableHeaderView)
        {
            CGFloat textWidth = DeviceScreenWidth - 32.0 - OAUtilities.getLeftMargin * 2;
            UIFont *labelFont = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
            CGSize labelSize = [OAUtilities calculateTextBounds:OALocalizedString(@"select_avoid_descr") width:textWidth font:labelFont];
            _tableHeaderView.frame = CGRectMake(0.0, 0.0, DeviceScreenWidth, labelSize.height + 30.0);
            _tableHeaderView.subviews.firstObject.frame = CGRectMake(16.0 + OAUtilities.getLeftMargin, 20.0, textWidth, labelSize.height);
        }
    } completion:nil];
}

- (void)doneButtonPressed
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) addRoadPressed:(id)sender
{
    [[OARootViewController instance].mapPanel openTargetViewWithImpassableRoadSelection];
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
        return OALocalizedString(@"select_manually");
    else if (section == 1)
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
        CGFloat height = [OAUtilities calculateTextBounds:headerText width:tableView.bounds.size.width font:[UIFont preferredFontForTextStyle:UIFontTextStyleFootnote]].height;
        return MAX(38.0, height + 10.0);
    }
}

- (UITableViewCell *) cellForRoutingParam:(OALocalRoutingParameter *)param
{
    NSString *text = [param getText];
    NSString *type = [param getCellType];
    if ([type isEqualToString:[OASwitchTableViewCell getCellIdentifier]])
    {
        OASwitchTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OASwitchTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASwitchTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASwitchTableViewCell *) nib[0];
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
        }
        if (cell)
        {
            cell.titleLabel.text = text;
            [cell.switchView removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
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
    else if ([item isKindOfClass:NSDictionary.class])
    {
        NSString *text = item[@"title"];
        NSString *value = item[@"descr"];
        if ([item[@"type"] isEqualToString:[OASimpleTableViewCell getCellIdentifier]])
        {
            OASimpleTableViewCell *cell = (OASimpleTableViewCell *)[tableView dequeueReusableCellWithIdentifier:[OASimpleTableViewCell getCellIdentifier]];
            if (cell == nil)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASimpleTableViewCell getCellIdentifier] owner:self options:nil];
                cell = (OASimpleTableViewCell *)[nib objectAtIndex:0];
            }
            
            if (cell)
            {
                cell.leftIconView.image = [UIImage imageNamed:@"ic_custom_alert_color"];
                [cell descriptionVisibility:value || value.length != 0];
                cell.descriptionLabel.text = value;
                [cell.titleLabel setText:text];
            }
            return cell;
        }
        else if ([item[@"type"] isEqualToString:[OAButtonTableViewCell getCellIdentifier]])
        {
            OAButtonTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OAButtonTableViewCell getCellIdentifier]];
            if (cell == nil)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAButtonTableViewCell getCellIdentifier] owner:self options:nil];
                cell = (OAButtonTableViewCell *) nib[0];
                [cell leftIconVisibility:NO];
                [cell titleVisibility:NO];
                [cell descriptionVisibility:NO];
                cell.button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
            }
            if (cell)
            {
                [cell.button setTitle:item[@"title"] forState:UIControlStateNormal];
                [cell.button removeTarget:self action:NULL forControlEvents:UIControlEventTouchDown];
                [cell.button addTarget:self action:@selector(addRoadPressed:) forControlEvents:UIControlEventTouchDown];
            }
            return cell;
        }
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
    else
    {
        NSString *key = param[@"key"];
        OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
        if ([@"select_on_map" isEqualToString:key])
        {
            [mapPanel openTargetViewWithImpassableRoadSelection];
        }
        else if ([@"road" isEqualToString:key])
        {
            NSNumber *roadId = param[@"roadId"];
            if (roadId)
            {
                [mapPanel openTargetViewWithImpassableRoad:roadId.unsignedLongLongValue pushed:NO];
            }
        }
    }
    if (self.delegate)
        [self.delegate onSettingsChanged];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *sectionData = _data[@(indexPath.section)];
    return indexPath.section == 0 && indexPath.row < sectionData.count - 1;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        NSDictionary *data = _data[@(indexPath.section)][indexPath.row];
        NSNumber *roadId = data[@"roadId"];
        if (roadId)
        {
            OAAvoidRoadInfo *roadInfo = [_avoidRoads getRoadInfoById:roadId.unsignedLongLongValue];
            if (roadInfo)
            {
                [_avoidRoads removeImpassableRoad:roadInfo];
                
                [self generateData];
                [self.tableView reloadData];
            }
        }
    }
}

@end
