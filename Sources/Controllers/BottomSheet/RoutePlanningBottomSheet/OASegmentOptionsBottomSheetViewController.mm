//
//  OASegmentOptionsBottomSheetViewController.m
//  OsmAnd
//
//  Created by Paul on 31.10.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OASegmentOptionsBottomSheetViewController.h"
#import "OATitleIconRoundCell.h"
#import "OASegmentedControllCell.h"
#import "Localization.h"
#import "OAColors.h"
#import "OAApplicationMode.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapLayers.h"
#import "OAMeasurementToolLayer.h"
#import "OAGPXDocumentPrimitives.h"
#import "OAOsmAndFormatter.h"

@interface OASegmentOptionsBottomSheetViewController () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation OASegmentOptionsBottomSheetViewController
{
    NSArray<NSArray<NSDictionary *> *> *_data;
    
    UIView *_tableHeaderView;
    
    EOARouteBetweenPointsDialogMode _dialogMode;
    EOARouteBetweenPointsDialogType _dialogType;
    
    OAApplicationMode *_appMode;
}

- (instancetype) initWithType:(EOARouteBetweenPointsDialogType)dialogType dialogMode:(EOARouteBetweenPointsDialogMode)dialogMode appMode:(OAApplicationMode *)appMode
{
    self = [super init];
    if (self)
    {
        _dialogMode = dialogMode;
        _dialogType = dialogType;
        _appMode = appMode;
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
    
    _tableHeaderView = [OAUtilities setupTableHeaderViewWithText:OALocalizedString(@"route_betw_points_descr") font:[UIFont systemFontOfSize:15.] textColor:UIColor.blackColor lineSpacing:0. isTitle:NO];
    self.tableView.tableHeaderView = _tableHeaderView;
    
    [self.rightButton removeFromSuperview];
    [self.leftIconView setImage:[UIImage imageNamed:@"ic_custom_routes"]];
}

- (void) applyLocalization
{
    self.titleView.text = OALocalizedString(@"route_betw_points");
    [self.leftButton setTitle:OALocalizedString(@"shared_string_close") forState:UIControlStateNormal];
}

- (void) generateData
{
    NSMutableArray *data = [NSMutableArray new];
    
    [data addObject:@[
        @{
            @"type" : [OASegmentedControllCell getCellIdentifier],
            @"first_item_title" : [self getButtonText:EOARouteBetweenPointsDialogModeSingle],
            @"second_item_title" : [self getButtonText:EOARouteBetweenPointsDialogModeAll]
        }
    ]];
    
    [data addObject:@[
        @{
            @"type" : [OATitleIconRoundCell getCellIdentifier],
            @"title" : OALocalizedString(@"nav_type_straight_line"),
            @"img" : @"ic_custom_straight_line",
            @"tintColor" : UIColorFromRGB(color_primary_purple),
            @"key" : @"straight_line_mode"
        }
    ]];
    
    NSMutableArray *sectionData = [NSMutableArray new];
    
    for (OAApplicationMode *mode in OAApplicationMode.values)
    {
        if ([mode.getRoutingProfile isEqualToString:@"public_transport"] || mode == OAApplicationMode.DEFAULT)
            continue;
        
        [sectionData addObject:
            @{
                @"type" : [OATitleIconRoundCell getCellIdentifier],
                @"title" : mode.toHumanString,
                @"img" : mode.getIconName,
                @"tintColor" : UIColorFromRGB(mode.getIconColor),
                @"mode" : mode
            }
        ];
    }
    
    [data addObject:sectionData];
    
    _data = data;
}

- (NSString *) getButtonText:(EOARouteBetweenPointsDialogMode)dialogMode
{
    switch (_dialogType) {
        case EOADialogTypeWholeRouteCalculation:
        {
            switch (dialogMode)
            {
                case EOARouteBetweenPointsDialogModeSingle:
                    return OALocalizedString(@"next_seg");
                case EOARouteBetweenPointsDialogModeAll:
                    return OALocalizedString(@"whole_track");
            }
            break;
        }
        case EOADialogTypeNextRouteCalculation:
        {
            NSString *nextDescr = [self getDescription:NO dialogMode:dialogMode];
            switch (dialogMode)
            {
                case EOARouteBetweenPointsDialogModeSingle:
                    return [NSString stringWithFormat:OALocalizedString(@"next_seg_dist"), nextDescr];
                case EOARouteBetweenPointsDialogModeAll:
                    return [NSString stringWithFormat:OALocalizedString(@"next_segs_dist"), nextDescr];
            }
            break;
        }
        case EOADialogTypePrevRouteCalculation:
        {
            NSString *prevDescr = [self getDescription:YES dialogMode:dialogMode];
            switch (dialogMode) {
                case EOARouteBetweenPointsDialogModeSingle:
                    return [NSString stringWithFormat:OALocalizedString(@"prev_seg_dist"), prevDescr];
                case EOARouteBetweenPointsDialogModeAll:
                    return [NSString stringWithFormat:OALocalizedString(@"prev_segs_dist"), prevDescr];
            }
            break;
        }
    }
    return @"";
}

- (NSString *) getDescription:(BOOL)before dialogMode:(EOARouteBetweenPointsDialogMode)dialogMode
{
    OAMeasurementEditingContext *editingCtx = OARootViewController.instance.mapPanel.mapViewController.mapLayers.routePlanningLayer.editingCtx;
    NSInteger pos = editingCtx.selectedPointPosition;
    NSArray<OAGpxTrkPt *> *points = editingCtx.getPoints;
    
    double dist = 0;
    if (dialogMode == EOARouteBetweenPointsDialogModeSingle)
    {
        OAGpxTrkPt *selectedPoint = points[pos];
        OAGpxTrkPt *second = points[before ? pos - 1 : pos + 1];
        dist += getDistance(selectedPoint.getLatitude, selectedPoint.getLongitude, second.getLatitude, second.getLongitude);
    }
    else
    {
        NSInteger startIdx, endIdx;
        if (before)
        {
            startIdx = 1;
            endIdx = pos;
        }
        else
        {
            startIdx = pos + 1;
            endIdx = points.count - 1;
        }
        for (NSInteger i = startIdx; i <= endIdx; i++)
        {
            OAGpxTrkPt *first = points[i - 1];
            OAGpxTrkPt *second = points[i];
            dist += getDistance(first.getLatitude, first.getLongitude, second.getLatitude, second.getLongitude);
        }
    }
    return [OAOsmAndFormatter getFormattedDistance:dist];
}

- (NSString *) getFooterText:(EOARouteBetweenPointsDialogMode)dialogMode
{
    switch (_dialogType)
    {
        case EOADialogTypeWholeRouteCalculation:
        {
            switch (dialogMode) {
                case EOARouteBetweenPointsDialogModeSingle:
                    return OALocalizedString(@"next_seg_descr");
                case EOARouteBetweenPointsDialogModeAll:
                    return OALocalizedString(@"whole_track_descr");
            }
            break;
        }
        case EOADialogTypeNextRouteCalculation:
        {
            switch (dialogMode)
            {
                case EOARouteBetweenPointsDialogModeSingle:
                    return OALocalizedString(@"selected_seg_recalc_descr");
                case EOARouteBetweenPointsDialogModeAll:
                    return OALocalizedString(@"next_segs_recalc_descr");
            }
            break;
        }
        case EOADialogTypePrevRouteCalculation:
        {
            switch (dialogMode) {
                case EOARouteBetweenPointsDialogModeSingle:
                    return OALocalizedString(@"selected_seg_recalc_descr");
                case EOARouteBetweenPointsDialogModeAll:
                    return OALocalizedString(@"prev_segs_recalc_descr");
            }
            break;
        }
    }
    return @"";
}

- (void) segmentChanged:(id)sender
{
    UISegmentedControl *segment = (UISegmentedControl*)sender;
    if (segment)
    {
        [self.tableView beginUpdates];
        _dialogMode = (EOARouteBetweenPointsDialogMode) segment.selectedSegmentIndex;
        [self.tableView footerViewForSection:0].textLabel.text = [self tableView:self.tableView titleForFooterInSection:0];
        [[self.tableView footerViewForSection:0] sizeToFit];
        [self.tableView endUpdates];
    }
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    
    if ([item[@"type"] isEqualToString:[OASegmentedControllCell getCellIdentifier]])
    {
        OASegmentedControllCell* cell = nil;
        cell = [tableView dequeueReusableCellWithIdentifier:[OASegmentedControllCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASegmentedControllCell getCellIdentifier] owner:self options:nil];
            cell = (OASegmentedControllCell *)[nib objectAtIndex:0];
            cell.backgroundColor = UIColor.clearColor;
            cell.segmentedControl.backgroundColor = [UIColorFromRGB(color_primary_purple) colorWithAlphaComponent:.1];
            
            if (@available(iOS 13.0, *))
                cell.segmentedControl.selectedSegmentTintColor = UIColorFromRGB(color_primary_purple);
            else
                cell.segmentedControl.tintColor = UIColorFromRGB(color_primary_purple);
            UIFont *font = [UIFont systemFontOfSize:15. weight:UIFontWeightSemibold];
            [cell.segmentedControl setTitleTextAttributes:@{NSForegroundColorAttributeName : UIColor.whiteColor, NSFontAttributeName : font} forState:UIControlStateSelected];
            [cell.segmentedControl setTitleTextAttributes:@{NSForegroundColorAttributeName : UIColorFromRGB(color_primary_purple), NSFontAttributeName : font} forState:UIControlStateNormal];
        }
        if (cell)
        {
            [cell.segmentedControl setTitle:item[@"first_item_title"] forSegmentAtIndex:0];
            [cell.segmentedControl setTitle:item[@"second_item_title"] forSegmentAtIndex:1];
            [cell.segmentedControl removeTarget:nil action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.segmentedControl addTarget:self action:@selector(segmentChanged:) forControlEvents:UIControlEventValueChanged];
            [cell.segmentedControl setSelectedSegmentIndex:_dialogMode == EOARouteBetweenPointsDialogModeSingle ? 0 : 1];
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:[OATitleIconRoundCell getCellIdentifier]])
    {
        OATitleIconRoundCell* cell = nil;
        cell = [tableView dequeueReusableCellWithIdentifier:[OATitleIconRoundCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATitleIconRoundCell getCellIdentifier] owner:self options:nil];
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
                cell.iconView.image = [UIImage templateImageNamed:item[@"img"]];
            }
            else
            {
                cell.iconView.image = [UIImage imageNamed:item[@"img"]];
            }
            cell.separatorView.hidden = indexPath.row == (NSInteger) _data[indexPath.section].count - 1;
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

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if (section == 0)
        return [self getFooterText:_dialogMode];
    return nil;
}

#pragma mark - UItableViewDelegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *key = item[@"key"];
    if (self.delegate)
    {
        if ([key isEqualToString:@"straight_line_mode"])
            [self.delegate onApplicationModeChanged:OAApplicationMode.DEFAULT dialogType:_dialogType dialogMode:_dialogMode];
        else
            [self.delegate onApplicationModeChanged:item[@"mode"] dialogType:_dialogType dialogMode:_dialogMode];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self hide:YES];
}

@end
