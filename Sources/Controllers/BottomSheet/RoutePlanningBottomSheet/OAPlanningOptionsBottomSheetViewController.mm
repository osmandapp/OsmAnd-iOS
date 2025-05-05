//
//  OAPlanningOptionsBottomSheetViewController.m
//  OsmAnd
//
//  Created by Paul on 31.10.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAPlanningOptionsBottomSheetViewController.h"
#import "OATitleIconRoundCell.h"
#import "OATitleDescriptionIconRoundCell.h"
#import "Localization.h"
#import "OAColors.h"
#import "OsmAnd_Maps-Swift.h"
#import "OAApplicationMode.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapLayers.h"
#import "OAMeasurementToolLayer.h"
#import "OAGPXDocumentPrimitives.h"
#import "GeneratedAssetSymbols.h"

@interface OAPlanningOptionsBottomSheetViewController () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation OAPlanningOptionsBottomSheetViewController
{
    NSArray<NSArray<NSDictionary *> *> *_data;
    OAApplicationMode *_routeAppMode;
}

- (instancetype) initWithRouteAppModeKey:(NSString *)routeAppModeKey trackSnappedToRoad:(BOOL)trackSnappedToRoad addNewSegmentAllowed:(BOOL)addNewSegmentAllowed
{
    self = [super init];
    if (self)
    {
        _routeAppMode = [OAApplicationMode valueOfStringKey:routeAppModeKey def:nil];
        [self generateData:trackSnappedToRoad addNewSegmentAllowed:addNewSegmentAllowed];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.sectionHeaderHeight = 16.;
    self.tableView.separatorInset = UIEdgeInsetsMake(0., 20., 0., 0.);
    
    [self.rightButton removeFromSuperview];
    self.leftIconView.image = [UIImage imageNamed:ACImageNameIcCustomRoutes];
    self.leftIconView.tintColor = [UIColor colorNamed:ACColorNameIconColorSelected];
}

- (void) applyLocalization
{
    self.titleView.text = OALocalizedString(@"shared_string_options");
    [self.leftButton setTitle:OALocalizedString(@"shared_string_close") forState:UIControlStateNormal];
}

- (CGFloat)initialHeight
{
    return DeviceScreenHeight - DeviceScreenHeight / 5;
}

- (void) generateData:(BOOL)trackSnappedToRoad addNewSegmentAllowed:(BOOL)addNewSegmentAllowed
{
    NSMutableArray *data = [NSMutableArray new];
    
    if (addNewSegmentAllowed)
    {
        [data addObject:@[
            @{
                @"type" : [OATitleIconRoundCell getCellIdentifier],
                @"title" : OALocalizedString(@"gpx_start_new_segment"),
                @"img" : @"ic_custom_new_segment",
                @"tintColor" : [UIColor colorNamed:ACColorNameIconColorActive],
                @"key" : @"start_new_segment"
            }
        ]];
    }
    
    NSString *descr;
    NSString *icon;
    if (trackSnappedToRoad)
    {
        if (_routeAppMode == nil || _routeAppMode == OAApplicationMode.DEFAULT)
        {
            descr = OALocalizedString(@"routing_profile_straightline");
            icon = @"ic_custom_straight_line";
        } else
        {
            descr = [_routeAppMode toHumanString];
            icon = _routeAppMode.getIconName;
        }
    }
    else
    {
        descr = OALocalizedString(@"rendering_attr_undefined_name");
        icon = @"left_menu_icon_help";
    }
    
    [data addObject:@[
        @{
            @"type" : [OATitleDescriptionIconRoundCell getCellIdentifier],
            @"title" : OALocalizedString(@"route_between_points"),
            @"img" : icon,
            @"descr" : descr,
            @"key" : @"route_betw_points"
        }
    ]];
    [data addObject:@[
        @{
            @"type" : [OATitleIconRoundCell getCellIdentifier],
            @"title" : OALocalizedString(@"profile_alert_need_save_title"),
            @"img" : @"ic_custom_save_to_file",
            @"tintColor" : [UIColor colorNamed:ACColorNameIconColorActive],
            @"key" : @"save_changes"
        },
        @{
            @"type" : [OATitleIconRoundCell getCellIdentifier],
            @"title" : OALocalizedString(@"save_as_new_track"),
            @"img" : @"ic_custom_save_as_new_file",
            @"tintColor" :  [UIColor colorNamed:ACColorNameIconColorActive],
            @"key" : @"save_new_track"
        },
        @{
            @"type" : [OATitleIconRoundCell getCellIdentifier],
            @"title" : OALocalizedString(@"add_to_a_track"),
            @"img" : @"ic_custom_add_to_track",
            @"tintColor" : [UIColor colorNamed:ACColorNameIconColorActive],
            @"key" : @"add_to_track"
        }
    ]];
    
    [data addObject:@[
        @{
            @"type" : [OATitleIconRoundCell getCellIdentifier],
            @"title" : OALocalizedString(@"shared_string_navigation"),
            @"img" : @"left_menu_icon_navigation",
            @"tintColor" : [UIColor colorNamed:ACColorNameIconColorActive],
            @"key" : @"shared_string_navigation"
        },
        @{
            @"type" : [OATitleIconRoundCell getCellIdentifier],
            @"title" : OALocalizedString(@"reverse_route"),
            @"img" : @"ic_custom_swap",
            @"tintColor" : [UIColor colorNamed:ACColorNameIconColorActive],
            @"key" : @"reverse_route"
        }
    ]];
    
    [data addObject:@[
        @{
            @"type" : [OATitleIconRoundCell getCellIdentifier],
            @"title" : OALocalizedString(@"shared_string_clear_all"),
            @"img" : @"ic_custom_remove",
            @"tintColor" : [UIColor colorNamed:ACColorNameButtonBgColorDisruptive],
            @"key" : @"clear_all"
        }
    ]];
    _data = data;
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    if ([item[@"type"] isEqualToString:[OATitleIconRoundCell getCellIdentifier]])
    {
        OATitleIconRoundCell* cell = nil;
        cell = [tableView dequeueReusableCellWithIdentifier:[OATitleIconRoundCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATitleIconRoundCell getCellIdentifier] owner:self options:nil];
            cell = (OATitleIconRoundCell *)[nib objectAtIndex:0];
            cell.textColorNormal = [UIColor colorNamed:ACColorNameTextColorPrimary];
        }
        if (cell)
        {
            [cell roundCorners:(indexPath.row == 0) bottomCorners:(indexPath.row == _data[indexPath.section].count - 1)];
            cell.titleView.text = item[@"title"];
            
            
            UIColor *tintColor = item[@"tintColor"];
            if (tintColor)
            {
                cell.iconColorNormal = tintColor;
                cell.iconView.image = [UIImage templateImageNamed:item[@"img"]];
            }
            else
            {
                cell.iconView.image = [UIImage imageNamed:item[@"img"]];
            }
            cell.separatorView.hidden = indexPath.row == (NSInteger) _data[indexPath.section].count - 1;
            cell.separatorView.backgroundColor = [UIColor colorNamed:ACColorNameCustomSeparator];
        }
        [cell layoutIfNeeded];
        return cell;
    }
    else if ([item[@"type"] isEqualToString:[OATitleDescriptionIconRoundCell getCellIdentifier]])
    {
        OATitleDescriptionIconRoundCell* cell = nil;
        cell = [tableView dequeueReusableCellWithIdentifier:[OATitleDescriptionIconRoundCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATitleDescriptionIconRoundCell getCellIdentifier] owner:self options:nil];
            cell = (OATitleDescriptionIconRoundCell *)[nib objectAtIndex:0];
            cell.textColorNormal = [UIColor colorNamed:ACColorNameTextColorPrimary];
        }
        if (cell)
        {
            [cell roundCorners:(indexPath.row == 0) bottomCorners:(indexPath.row == _data[indexPath.section].count - 1)];
            cell.titleView.text = item[@"title"];
            cell.descrView.text = item[@"descr"];
            
            UIColor *tintColor = _routeAppMode && _routeAppMode != OAApplicationMode.DEFAULT ? _routeAppMode.getProfileColor : [UIColor colorNamed:ACColorNameIconColorSelected];
            if (tintColor)
            {
                cell.iconColorNormal = tintColor;
                cell.iconView.image = [UIImage templateImageNamed:item[@"img"]];
            }
            else
            {
                cell.iconView.image = [UIImage imageNamed:item[@"img"]];
            }
            cell.separatorView.hidden = indexPath.row == (NSInteger) _data[indexPath.section].count - 1;
        }
        [cell layoutIfNeeded];
        return cell;
    }
    return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _data[section].count;
}


#pragma mark - UITableViewDelegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *key = item[@"key"];
    if (self.delegate)
    {
        if ([key isEqualToString:@"start_new_segment"])
        {
            [self.delegate addNewSegmentSelected];
        }
        else if ([key isEqualToString:@"route_betw_points"])
        {
            [self hide:YES completion:^{
                [self.delegate snapToRoadOptionSelected];
            }];
            return;
        }
        else if ([key isEqualToString:@"save_changes"])
        {
            [self hide:YES completion:^{
                [self.delegate saveChangesSelected];
            }];
        }
        else if ([key isEqualToString:@"save_new_track"])
        {
            [self hide:YES completion:^{
                [self.delegate saveAsNewTrackSelected];
            }];
        }
        else if ([key isEqualToString:@"add_to_track"])
        {
            [self hide:YES completion:^{
                [self.delegate addToTrackSelected];
            }];
        }
        else if ([key isEqualToString:@"shared_string_navigation"])
        {
            [self.delegate directionsSelected];
        }
        else if ([key isEqualToString:@"reverse_route"])
        {
            [self.delegate reverseRouteSelected];
        }
        else if ([key isEqualToString:@"clear_all"])
        {
            [self.delegate clearAllSelected];
        }
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self hide:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    if ([item[@"type"] isEqualToString:[OATitleIconRoundCell getCellIdentifier]])
    {
        return [OATitleIconRoundCell getHeight:item[@"title"] cellWidth:tableView.bounds.size.width];
    }
    else if ([item[@"type"] isEqualToString:[OATitleDescriptionIconRoundCell getCellIdentifier]])
    {
        return [OATitleDescriptionIconRoundCell getHeight:item[@"title"] descr:item[@"descr"] cellWidth:tableView.bounds.size.width];
    }
    return UITableViewAutomaticDimension;
}

@end
