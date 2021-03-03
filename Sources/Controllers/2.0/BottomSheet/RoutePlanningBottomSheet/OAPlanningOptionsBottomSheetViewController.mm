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
#import "OAApplicationMode.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapLayers.h"
#import "OAMeasurementToolLayer.h"
#import "OAGPXDocumentPrimitives.h"

#define kIconTitleIconRoundCell @"OATitleIconRoundCell"
#define kTitleDescrIconRoundCell @"OATitleDescriptionIconRoundCell"

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
    [self.leftIconView setImage:[UIImage imageNamed:@"ic_custom_routes"]];
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
                @"type" : kIconTitleIconRoundCell,
                @"title" : OALocalizedString(@"track_new_segment"),
                @"img" : @"ic_custom_new_segment",
                @"tintColor" : UIColorFromRGB(color_primary_purple),
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
            descr = OALocalizedString(@"nav_type_straight_line");
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
            @"type" : kTitleDescrIconRoundCell,
            @"title" : OALocalizedString(@"route_betw_points"),
            @"img" : icon,
            @"descr" : descr,
            @"key" : @"route_betw_points"
        }
    ]];
    [data addObject:@[
        @{
            @"type" : kIconTitleIconRoundCell,
            @"title" : OALocalizedString(@"save_changes"),
            @"img" : @"ic_custom_save_to_file",
            @"tintColor" : UIColorFromRGB(color_primary_purple),
            @"key" : @"save_changes"
        },
        @{
            @"type" : kIconTitleIconRoundCell,
            @"title" : OALocalizedString(@"save_new_track"),
            @"img" : @"ic_custom_save_as_new_file",
            @"tintColor" : UIColorFromRGB(color_primary_purple),
            @"key" : @"save_new_track"
        },
        @{
            @"type" : kIconTitleIconRoundCell,
            @"title" : OALocalizedString(@"add_to_track"),
            @"img" : @"ic_custom_add_to_track",
            @"tintColor" : UIColorFromRGB(color_primary_purple),
            @"key" : @"add_to_track"
        }
    ]];
    
    [data addObject:@[
        @{
            @"type" : kIconTitleIconRoundCell,
            @"title" : OALocalizedString(@"get_directions"),
            @"img" : @"left_menu_icon_navigation",
            @"tintColor" : UIColorFromRGB(color_primary_purple),
            @"key" : @"get_directions"
        },
        @{
            @"type" : kIconTitleIconRoundCell,
            @"title" : OALocalizedString(@"reverse_route"),
            @"img" : @"ic_custom_swap",
            @"tintColor" : UIColorFromRGB(color_primary_purple),
            @"key" : @"reverse_route"
        }
    ]];
    
    [data addObject:@[
        @{
            @"type" : kIconTitleIconRoundCell,
            @"title" : OALocalizedString(@"shared_string_clear_all"),
            @"img" : @"ic_custom_remove",
            @"tintColor" : UIColorFromRGB(color_primary_red),
            @"key" : @"clear_all"
        }
    ]];
    _data = data;
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    if ([item[@"type"] isEqualToString:kIconTitleIconRoundCell])
    {
        static NSString* const identifierCell = kIconTitleIconRoundCell;
        OATitleIconRoundCell* cell = nil;
        
        cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:kIconTitleIconRoundCell owner:self options:nil];
            cell = (OATitleIconRoundCell *)[nib objectAtIndex:0];
            cell.backgroundColor = UIColor.clearColor;
            cell.textColorNormal = UIColor.blackColor;
        }
        if (cell)
        {
            [cell roundCorners:(indexPath.row == 0) bottomCorners:(indexPath.row == _data[indexPath.section].count - 1)];
            cell.titleView.text = item[@"title"];
            
            
            UIColor *tintColor = item[@"tintColor"];
            if (tintColor)
            {
                cell.iconColorNormal = tintColor;
                cell.iconView.image = [[UIImage imageNamed:item[@"img"]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            }
            else
            {
                cell.iconView.image = [UIImage imageNamed:item[@"img"]];
            }
            cell.separatorView.hidden = indexPath.row == _data[indexPath.section].count - 1;
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:kTitleDescrIconRoundCell])
    {
        static NSString* const identifierCell = kTitleDescrIconRoundCell;
        OATitleDescriptionIconRoundCell* cell = nil;
        
        cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:kTitleDescrIconRoundCell owner:self options:nil];
            cell = (OATitleDescriptionIconRoundCell *)[nib objectAtIndex:0];
            cell.backgroundColor = UIColor.clearColor;
            cell.textColorNormal = UIColor.blackColor;
        }
        if (cell)
        {
            [cell roundCorners:(indexPath.row == 0) bottomCorners:(indexPath.row == _data[indexPath.section].count - 1)];
            cell.titleView.text = item[@"title"];
            cell.descrView.text = item[@"descr"];
            
            UIColor *tintColor = _routeAppMode && _routeAppMode != OAApplicationMode.DEFAULT ? UIColorFromRGB(_routeAppMode.getIconColor) : UIColorFromRGB(color_osmand_orange);
            if (tintColor)
            {
                cell.iconColorNormal = tintColor;
                cell.iconView.image = [[UIImage imageNamed:item[@"img"]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            }
            else
            {
                cell.iconView.image = [UIImage imageNamed:item[@"img"]];
            }
            cell.separatorView.hidden = indexPath.row == _data[indexPath.section].count - 1;
        }
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


#pragma mark - UItableViewDelegate

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
            [self dismissViewControllerAnimated:NO completion:nil];
            [self.delegate snapToRoadOptionSelected];
            return;
        }
        else if ([key isEqualToString:@"save_changes"])
        {
            [self.delegate saveChangesSelected];
        }
        else if ([key isEqualToString:@"save_new_track"])
        {
            [self dismissViewControllerAnimated:NO completion:nil];
            [self.delegate saveAsNewTrackSelected];
        }
        else if ([key isEqualToString:@"add_to_track"])
        {
            [self dismissViewControllerAnimated:NO completion:nil];
            [self.delegate addToTrackSelected];
        }
        else if ([key isEqualToString:@"get_directions"])
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
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
