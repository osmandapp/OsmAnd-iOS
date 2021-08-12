//
//  OATargetOptionsBottomSheetViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 10/04/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OATargetOptionsBottomSheetViewController.h"
#import "OAAddDestinationBottomSheetViewController.h"
#import "OARootViewController.h"
#import "Localization.h"
#import "OATargetPoint.h"
#import "OARTargetPoint.h"
#import "OATargetPointsHelper.h"
#import "OAWaypointHelper.h"
#import "OAWaypointUIHelper.h"
#import "OAMenuSimpleCell.h"
#import "OAWaypointHeaderCell.h"
#import "OADividerCell.h"
#import "OAUtilities.h"
#import "OAColors.h"

@interface OATargetOptionsBottomSheetScreen () <OAWaypointSelectionDelegate>

@end


@implementation OATargetOptionsBottomSheetScreen
{
    OsmAndAppInstance _app;
    OATargetPointsHelper *_targetPointsHelper;
    OAWaypointHelper *_waypointHelper;
    
    NSArray* _data;
    id<OATargetOptionsDelegate> _targetOptionsDelegate;

}

@synthesize tableData, vwController, tblView;

- (id) initWithTable:(UITableView *)tableView viewController:(OATargetOptionsBottomSheetViewController *)viewController
{
    self = [super init];
    if (self)
    {
        [self initOnConstruct:tableView viewController:viewController];
    }
    return self;
}

- (id) initWithTable:(UITableView *)tableView viewController:(OATargetOptionsBottomSheetViewController *)viewController param:(id)param
{
    self = [super init];
    if (self)
    {
        _targetOptionsDelegate = param;
        [self initOnConstruct:tableView viewController:viewController];
    }
    return self;
}

- (void) initOnConstruct:(UITableView *)tableView viewController:(OATargetOptionsBottomSheetViewController *)viewController
{
    _app = [OsmAndApp instance];
    _targetPointsHelper = [OATargetPointsHelper sharedInstance];
    _waypointHelper = [OAWaypointHelper sharedInstance];
    
    vwController = viewController;
    tblView = tableView;
    tblView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    [self initData];
}

- (void) setupView
{
    NSMutableArray *arr = [NSMutableArray array];
    [arr addObject:@{ @"title" : OALocalizedString(@"shared_string_options"),
                      @"type" : [OAWaypointHeaderCell getCellIdentifier] } ];
    
    [arr addObject:@{ @"title" : OALocalizedString(@"intermediate_items_sort_by_distance"),
                      @"key" : @"intermediate_items_sort_by_distance",
                      @"img" : @"ic_action_sort_door_to_door",
                      @"type" : [OAMenuSimpleCell getCellIdentifier] } ];
    
    [arr addObject:@{ @"title" : OALocalizedString(@"switch_start_finish"),
                      @"key" : @"switch_start_finish",
                      @"img" : @"ic_action_sort_reverse_order",
                      @"type" : [OAMenuSimpleCell getCellIdentifier] } ];
    
    [arr addObject:@{ @"type" : [OADividerCell getCellIdentifier] } ];
    
    [arr addObject:@{ @"title" : OALocalizedString(@"add_waypoint_short"),
                      @"key" : @"add_waypoint",
                      @"img" : @"ic_action_plus",
                      @"type" : [OAMenuSimpleCell getCellIdentifier] } ];
    
    [arr addObject:@{ @"title" : OALocalizedString(@"clear_all_intermediates"),
                      @"key" : @"clear_all_intermediates",
                      @"img" : @"ic_action_clear_all",
                      @"type" : [OAMenuSimpleCell getCellIdentifier] } ];
    
    _data = [NSArray arrayWithArray:arr];
}

- (void) initData
{
}

- (CGFloat) heightForRow:(NSIndexPath *)indexPath tableView:(UITableView *)tableView
{
    NSDictionary *item = _data[indexPath.row];
    if ([item[@"type"] isEqualToString:[OAMenuSimpleCell getCellIdentifier]])
    {
        return UITableViewAutomaticDimension;
    }
    else if ([item[@"type"] isEqualToString:[OAWaypointHeaderCell getCellIdentifier]])
    {
        return 44.0;
    }
    else if ([item[@"type"] isEqualToString:[OADividerCell getCellIdentifier]])
    {
        return [OADividerCell cellHeight:0.5 dividerInsets:UIEdgeInsetsMake(6.0, 70.0, 4.0, 0.0)];
    }
    else
    {
        return 44.0;
    }
}

- (void) updateRouteInfoMenu
{
    [[OARootViewController instance].mapPanel updateRouteInfo];
}

- (void) closeRouteInfoMenu
{
    [[OARootViewController instance].mapPanel closeRouteInfo];
}

#pragma mark - OAWaypointSelectionDialogDelegate

- (void) waypointSelectionDialogComplete:(BOOL)selectionDone showMap:(BOOL)showMap calculatingRoute:(BOOL)calculatingRoute
{
    if (showMap)
    {
        [vwController dismiss];
    }
    else if (selectionDone && _targetOptionsDelegate)
    {
        [_targetOptionsDelegate targetOptionsUpdateControls:calculatingRoute];
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

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.row];
    
    if ([item[@"type"] isEqualToString:[OAMenuSimpleCell getCellIdentifier]])
    {
        OAMenuSimpleCell* cell = nil;
        cell = [tableView dequeueReusableCellWithIdentifier:[OAMenuSimpleCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAMenuSimpleCell getCellIdentifier] owner:self options:nil];
            cell = (OAMenuSimpleCell *)[nib objectAtIndex:0];
            cell.backgroundColor = UIColor.clearColor;
            cell.textView.textColor = UIColorFromRGB(color_menu_button);
            cell.descriptionView.textColor = UIColorFromRGB(color_secondary_text_blur);
        }
        
        if (cell)
        {
            UIImage *img = nil;
            NSString *imgName = item[@"img"];
            if (imgName)
                img = [UIImage imageNamed:imgName];
            
            cell.textView.text = item[@"title"];
            NSString *desc = item[@"description"];
            cell.descriptionView.text = desc;
            cell.descriptionView.hidden = desc.length == 0;
            cell.imgView.image = img;
            if ([cell needsUpdateConstraints])
                [cell setNeedsUpdateConstraints];
        }
        
        return cell;
    }
    else if ([item[@"type"] isEqualToString:[OAWaypointHeaderCell getCellIdentifier]])
    {
        OAWaypointHeaderCell* cell = [tableView dequeueReusableCellWithIdentifier:[OAWaypointHeaderCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAWaypointHeaderCell getCellIdentifier] owner:self options:nil];
            cell = (OAWaypointHeaderCell *)[nib objectAtIndex:0];
            cell.backgroundColor = UIColor.clearColor;
            cell.progressView.hidden = YES;
            cell.switchView.hidden = YES;
            cell.imageButton.hidden = YES;
            cell.textButton.hidden = YES;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if (cell)
        {
            cell.titleView.text = item[@"title"];
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:[OADividerCell getCellIdentifier]])
    {
        OADividerCell* cell = [tableView dequeueReusableCellWithIdentifier:[OADividerCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OADividerCell getCellIdentifier] owner:self options:nil];
            cell = (OADividerCell *)[nib objectAtIndex:0];
            cell.backgroundColor = UIColor.clearColor;
            cell.dividerColor = UIColorFromRGB(color_divider_blur);
            cell.dividerInsets = UIEdgeInsetsMake(6.0, 70.0, 4.0, 0.0);
            cell.dividerHight = 0.5;
        }
        return cell;
    }
    else
    {
        return nil;
    }
}

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self heightForRow:indexPath tableView:tableView];
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self heightForRow:indexPath tableView:tableView];
}

#pragma mark - UITableViewDelegate

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.01;
}

- (CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.01;
}

- (NSIndexPath *) tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.row];
    if ([item[@"type"] isEqualToString:[OAMenuSimpleCell getCellIdentifier]])
        return indexPath;
    else
        return nil;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.row];
    NSString *key = item[@"key"];
    if ([key isEqualToString:@"intermediate_items_sort_by_distance"])
    {
        [OAWaypointUIHelper sortAllTargets:^{
            if (_targetOptionsDelegate)
                [_targetOptionsDelegate targetOptionsUpdateControls:YES];
        }];
    }
    else if ([key isEqualToString:@"switch_start_finish"])
    {
        [OAWaypointUIHelper switchStartAndFinish:^{
            if (_targetOptionsDelegate)
                [_targetOptionsDelegate targetOptionsUpdateControls:YES];
        }];
    }
    else if ([key isEqualToString:@"add_waypoint"])
    {
        OAAddDestinationBottomSheetViewController *addDest = [[OAAddDestinationBottomSheetViewController alloc] initWithType:EOADestinationTypeIntermediate];
        addDest.delegate = self;
        [addDest show];
    }
    else if ([key isEqualToString:@"clear_all_intermediates"])
    {
        if ([_targetPointsHelper getIntermediatePoints].count > 0)
        {
            [_targetPointsHelper clearAllIntermediatePoints:NO];
            
            if (_targetOptionsDelegate)
                [_targetOptionsDelegate targetOptionsUpdateControls:YES];
            
            [_targetPointsHelper updateRouteAndRefresh:YES];
        }
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [vwController dismiss];
}

@end

@interface OATargetOptionsBottomSheetViewController ()

@end

@implementation OATargetOptionsBottomSheetViewController

- (instancetype) initWithDelegate:(id<OATargetOptionsDelegate>)targetOptionsDelegate
{
    return [super initWithParam:targetOptionsDelegate];
}

- (id<OATargetOptionsDelegate>) targetOptionsDelegate
{
    return self.customParam;
}

- (void) setupView
{
    if (!self.screenObj)
        self.screenObj = [[OATargetOptionsBottomSheetScreen alloc] initWithTable:self.tableView viewController:self param:self.targetOptionsDelegate];
    
    [super setupView];
}

@end
