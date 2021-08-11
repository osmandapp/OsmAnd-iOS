//
//  OAPointOptionsBottomSheetViewController.m
//  OsmAnd
//
//  Created by Paul on 31.10.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAPointOptionsBottomSheetViewController.h"
#import "OATitleIconRoundCell.h"
#import "Localization.h"
#import "OAGPXDocumentPrimitives.h"
#import "OAColors.h"
#import "OAApplicationMode.h"
#import "OAMapLayers.h"

@interface OAPointOptionsBottomSheetViewController () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation OAPointOptionsBottomSheetViewController
{
    OAGpxTrkPt *_point;
    NSInteger _pointIndex;
    NSArray<NSArray<NSDictionary *> *> *_data;
    
    OAMeasurementEditingContext *_editingCtx;
}

- (instancetype) initWithPoint:(OAGpxTrkPt *)point index:(NSInteger)pointIndex editingContext:(OAMeasurementEditingContext *)editingContext
{
    self = [super init];
    if (self) {
        _point = point;
        _pointIndex = pointIndex;
        _editingCtx = editingContext;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.sectionHeaderHeight = 16.;
    [self.rightButton removeFromSuperview];
    [self.leftIconView setImage:[UIImage imageNamed:@"ic_custom_routes"]];
}

- (void) applyLocalization
{
    self.titleView.text = [NSString stringWithFormat:OALocalizedString(@"point_num"), _pointIndex + 1];
    [self.leftButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
}

- (void) generateData
{
    NSMutableArray *data = [NSMutableArray new];
    [data addObject:@[
        @{
            @"type" : [OATitleIconRoundCell getCellIdentifier],
            @"title" : OALocalizedString(@"move_point"),
            @"img" : @"ic_custom_change_object_position",
            @"key" : @"move_point"
        }
    ]];
    
    [data addObject:@[
        @{
            @"type" : [OATitleIconRoundCell getCellIdentifier],
            @"title" : OALocalizedString(@"add_before"),
            @"img" : @"ic_custom_add_point_before",
            @"key" : @"add_points",
            @"value" : @(EOAAddPointModeBefore)
        },
        @{
            @"type" : [OATitleIconRoundCell getCellIdentifier],
            @"title" : OALocalizedString(@"add_after"),
            @"img" : @"ic_custom_add_point_after",
            @"key" : @"add_points",
            @"value" : @(EOAAddPointModeAfter)
        }
    ]];
    
    [data addObject:@[
        @{
            @"type" : [OATitleIconRoundCell getCellIdentifier],
            @"title" : OALocalizedString(@"trim_before"),
            @"img" : @"ic_custom_trim_before",
            @"key" : @"trim_before",
            @"value" : @(EOAClearPointsModeBefore)
        },
        @{
            @"type" : [OATitleIconRoundCell getCellIdentifier],
            @"title" : OALocalizedString(@"trim_after"),
            @"img" : @"ic_custom_trim_after",
            @"key" : @"trim_after",
            @"value" : @(EOAClearPointsModeAfter)
        }
    ]];
    
    if ([_editingCtx isFirstPointSelected:YES])
    {
        // skip
    }
    else if ([_editingCtx isLastPointSelected:YES])
    {
        [data addObject:@[
            @{
                @"type" : [OATitleIconRoundCell getCellIdentifier],
                @"title" : OALocalizedString(@"track_new_segment"),
                @"img" : @"ic_custom_new_segment",
                @"key" : @"new_segment"
            }
        ]];
    }
    else if ([_editingCtx isFirstPointSelected:NO] || [_editingCtx isLastPointSelected:NO])
    {
        [data addObject:@[
            @{
                @"type" : [OATitleIconRoundCell getCellIdentifier],
                @"title" : OALocalizedString(@"join_segments"),
                @"img" : @"ic_custom_join_segments",
                @"key" : @"join_segments"
            }
        ]];
    }
    else
    {
        BOOL splitBefore = [_editingCtx canSplit:NO];
        BOOL splitAfter = [_editingCtx canSplit:YES];
        if (splitBefore && splitAfter)
        {
            [data addObject:@[
                @{
                    @"type" : [OATitleIconRoundCell getCellIdentifier],
                    @"title" : OALocalizedString(@"split_before"),
                    @"img" : @"ic_custom_split_before",
                    @"key" : @"split_before"
                },
                @{
                    @"type" : [OATitleIconRoundCell getCellIdentifier],
                    @"title" : OALocalizedString(@"split_after"),
                    @"img" : @"ic_custom_split_after",
                    @"key" : @"split_after"
                }
            ]];
        }
        else if (splitBefore)
        {
            [data addObject:@[
                @{
                    @"type" : [OATitleIconRoundCell getCellIdentifier],
                    @"title" : OALocalizedString(@"split_before"),
                    @"img" : @"ic_custom_split_before",
                    @"key" : @"split_before"
                }
            ]];
        }
        else if (splitAfter)
        {
            [data addObject:@[
                @{
                    @"type" : [OATitleIconRoundCell getCellIdentifier],
                    @"title" : OALocalizedString(@"split_after"),
                    @"img" : @"ic_custom_split_after",
                    @"key" : @"split_after"
                }
            ]];
        }
    }
    
    [data addObject:@[
        @{
            @"type" : [OATitleIconRoundCell getCellIdentifier],
            @"title" : OALocalizedString(@"change_route_type_before"),
            @"img" : [self getRouteTypeIcon:YES],
            @"key" : @"change_route_before",
        },
        @{
            @"type" : [OATitleIconRoundCell getCellIdentifier],
            @"title" : OALocalizedString(@"change_route_type_after"),
            @"img" : [self getRouteTypeIcon:NO],
            @"key" : @"change_route_after",
            
        }
    ]];
    
    [data addObject:@[
        @{
            @"type" : [OATitleIconRoundCell getCellIdentifier],
            @"title" : OALocalizedString(@"delete_point"),
            @"img" : @"ic_custom_remove_outlined",
            @"custom_color" : UIColorFromRGB(color_primary_red),
            @"key" : @"delete_point"
        }
    ]];
    _data = data;
}

- (NSString *) getRouteTypeIcon:(BOOL)before
{
    OAApplicationMode *routeAppMode = before ? _editingCtx.getBeforeSelectedPointAppMode : _editingCtx.getSelectedPointAppMode;
    NSString *icon;
    if (OAApplicationMode.DEFAULT == routeAppMode)
        icon = @"ic_custom_straight_line";
    else
        icon = routeAppMode.getIconName;
        
    return icon;
}

- (BOOL)isActiveCell:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    if ([item[@"key"] isEqualToString:@"trim_before"])
        return ![_editingCtx isFirstPointSelected:NO];
    else if ([item[@"key"] isEqualToString:@"trim_after"])
        return ![_editingCtx isLastPointSelected:NO];
    else if ([item[@"key"] isEqualToString:@"split_after"])
        return [_editingCtx canSplit:YES];
    else if ([item[@"key"] isEqualToString:@"split_before"])
        return [_editingCtx canSplit:NO];
    else if ([item[@"key"] isEqualToString:@"change_route_before"])
        return ![_editingCtx isFirstPointSelected:NO] && ![_editingCtx isApproximationNeeded];
    else if ([item[@"key"] isEqualToString:@"change_route_after"])
        return ![_editingCtx isLastPointSelected:NO] && ![_editingCtx isApproximationNeeded];

    return YES;
}

- (void) onBottomSheetDismissed
{
    if (self.delegate)
        [self.delegate onClearSelection];
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
            cell.backgroundColor = UIColor.clearColor;
        }
        if (cell)
        {
            [cell roundCorners:(indexPath.row == 0) bottomCorners:(indexPath.row == _data[indexPath.section].count - 1)];
            cell.titleView.text = item[@"title"];

            UIColor *tintColor = item[@"custom_color"];
            if (tintColor)
            {
                cell.iconColorNormal = tintColor;
                cell.textColorNormal = tintColor;
                cell.iconView.image = [UIImage templateImageNamed:item[@"img"]];
            }
            else
            {
                BOOL isActiveCell =  [self isActiveCell:indexPath];
                cell.iconColorNormal = isActiveCell ? UIColorFromRGB(color_chart_orange) : UIColorFromRGB(color_tint_gray);
                cell.textColorNormal = isActiveCell ? [UIColor blackColor] : [UIColor lightGrayColor];
                cell.iconView.image = [UIImage templateImageNamed:item[@"img"]];
                cell.separatorView.hidden = indexPath.row == (NSInteger) _data[indexPath.section].count - 1;
            }
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

- (NSIndexPath *) tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self isActiveCell:indexPath] ? indexPath : nil;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *key = item[@"key"];
    if ([key isEqualToString:@"move_point"])
    {
        if (self.delegate)
            [self.delegate onMovePoint:_pointIndex];
    }
    else if ([key hasPrefix:@"trim"])
    {
        EOAClearPointsMode mode = (EOAClearPointsMode) [item[@"value"] integerValue];
        if (self.delegate)
            [self.delegate onClearPoints:mode];
    }
    else if ([key isEqualToString:@"add_points"])
    {
        EOAAddPointMode type = (EOAAddPointMode) [item[@"value"] integerValue];
        if (self.delegate)
            [self.delegate onAddPoints:type];
    }
    else if ([key isEqualToString:@"delete_point"])
    {
        if (self.delegate)
            [self.delegate onDeletePoint];
    }
    else if ([key isEqualToString:@"change_route_before"])
    {
        [self hide:YES];
        if (self.delegate)
            [self.delegate onChangeRouteTypeBefore];
        return;
    }
    else if ([key isEqualToString:@"change_route_after"])
    {
        [self hide:YES];
        if (self.delegate)
            [self.delegate onChangeRouteTypeAfter];
        return;
    }
    else if ([key isEqualToString:@"new_segment"])
    {
        [self hide:YES];
        if (self.delegate)
            [self.delegate onSplitPointsAfter];
        return;
    }
    else if ([key isEqualToString:@"join_segments"])
    {
        [self hide:YES];
        if (self.delegate)
            [self.delegate onJoinPoints];
        return;
    }
    else if ([key isEqualToString:@"split_before"])
    {
        [self hide:YES];
        if (self.delegate)
            [self.delegate onSplitPointsBefore];
        return;
    }
    else if ([key isEqualToString:@"split_after"])
    {
        [self hide:YES];
        if (self.delegate)
            [self.delegate onSplitPointsAfter];
        return;
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self hide:YES];
}

@end
