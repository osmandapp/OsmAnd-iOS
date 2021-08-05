//
//  OAStatisticsSelectionBottomSheetViewController.m
//  OsmAnd
//
//  Created by Paul on 4/18/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAStatisticsSelectionBottomSheetViewController.h"
#import "OAActionConfigurationViewController.h"
#import "Localization.h"
#import "OABottomSheetHeaderCell.h"
#import "OAUtilities.h"
#import "OAColors.h"
#import "OASizes.h"
#import "OAAppSettings.h"
#import "OATitleIconRoundCell.h"
#import "OADestinationsHelper.h"
#import "OADestination.h"
#import "OAFavoriteItem.h"
#import "OATargetPointsHelper.h"
#import "OAPointDescription.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OADestinationItemsListViewController.h"

#include <OsmAndCore.h>
#include <OsmAndCore/IFavoriteLocation.h>
#include <OsmAndCore/Utilities.h>

#define kButtonsDividerTag 150
#define kMessageFieldIndex 1

@interface OAStatisticsSelectionBottomSheetScreen ()

@end

@implementation OAStatisticsSelectionBottomSheetScreen
{
    OsmAndAppInstance _app;
    OAStatisticsSelectionBottomSheetViewController *vwController;
    OATargetPointsHelper *_pointsHelper;
    NSArray* _data;
}

@synthesize tableData, tblView;

- (id) initWithTable:(UITableView *)tableView viewController:(OAStatisticsSelectionBottomSheetViewController *)viewController param:(id)param
{
    self = [super init];
    if (self)
    {
        [self initOnConstruct:tableView viewController:viewController];
    }
    return self;
}

- (void) initOnConstruct:(UITableView *)tableView viewController:(OAStatisticsSelectionBottomSheetViewController *)viewController
{
    _app = [OsmAndApp instance];
    
    vwController = viewController;
    tblView = tableView;
    
    [self initData];
}

- (void) setupView
{
    tblView.separatorColor = UIColorFromRGB(color_tint_gray);
    [[self.vwController.buttonsView viewWithTag:kButtonsDividerTag] removeFromSuperview];
    NSMutableArray *arr = [NSMutableArray array];
    [arr addObject:@{
                     @"type" : [OABottomSheetHeaderCell getCellIdentifier],
                     @"title" : OALocalizedString(@"stats_select_graph_data"),
                     @"description" : @""
                     }];
    
    [arr addObject:@{
        @"type" : [OATitleIconRoundCell getCellIdentifier],
        @"title" : OALocalizedString(@"map_widget_altitude"),
        @"img" : @"ic_custom_altitude",
        @"mode" : @(EOARouteStatisticsModeAltitude),
        @"round_bottom" : @(NO),
        @"round_top" : @(YES)
    }];
    
    [arr addObject:@{
        @"type" : [OATitleIconRoundCell getCellIdentifier],
        @"title" : OALocalizedString(@"gpx_slope"),
        @"img" : @"ic_custom_ascent",
        @"mode" : @(EOARouteStatisticsModeSlope),
        @"round_bottom" : @(NO),
        @"round_top" : @(NO)
    }];
    
    [arr addObject:@{
        @"type" : [OATitleIconRoundCell getCellIdentifier],
        @"title" : [NSString stringWithFormat:@"%@/%@", OALocalizedString(@"map_widget_altitude"), OALocalizedString(@"gpx_slope")],
        @"img" : @"ic_custom_altitude_and_slope",
        @"mode" : @(EOARouteStatisticsModeBoth),
        @"round_bottom" : @(YES),
        @"round_top" : @(NO)
    }];
    
    _data = [NSArray arrayWithArray:arr];
}

- (void) initData
{
}

- (CGFloat) heightForRow:(NSIndexPath *)indexPath tableView:(UITableView *)tableView
{
    NSDictionary *item = [self getItem:indexPath];
    
    if ([item[@"type"] isEqualToString:[OABottomSheetHeaderCell getCellIdentifier]] || [item[@"type"] isEqualToString:[OATitleIconRoundCell getCellIdentifier]])
    {
        return UITableViewAutomaticDimension;
    }
    else
    {
        return 44.0;
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
    NSDictionary *item = [self getItem:indexPath];
    
    if ([item[@"type"] isEqualToString:[OABottomSheetHeaderCell getCellIdentifier]])
    {
        OABottomSheetHeaderCell* cell = [tableView dequeueReusableCellWithIdentifier:[OABottomSheetHeaderCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OABottomSheetHeaderCell getCellIdentifier] owner:self options:nil];
            cell = (OABottomSheetHeaderCell *)[nib objectAtIndex:0];
            cell.backgroundColor = UIColor.clearColor;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.separatorInset = UIEdgeInsetsMake(0., DBL_MAX, 0., 0.);
        }
        if (cell)
        {
            cell.titleView.text = item[@"title"];
            cell.sliderView.layer.cornerRadius = 3.0;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
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
        }
        
        if (cell)
        {
            cell.backgroundColor = UIColor.clearColor;
            cell.titleView.text = item[@"title"];
            
            [cell.iconView setImage:[UIImage templateImageNamed:item[@"img"]]];
            cell.iconColorNormal = vwController.mode == (EOARouteStatisticsMode) [item[@"mode"] integerValue] ? UIColorFromRGB(color_primary_purple) : UIColorFromRGB(color_icon_inactive);
            [cell roundCorners:[item[@"round_top"] boolValue] bottomCorners:[item[@"round_bottom"] boolValue]];
            cell.separatorInset = UIEdgeInsetsMake(0., 32., 0., 16.);
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        return cell;
    }
    else
    {
        return nil;
    }
}

- (NSDictionary *) getItem:(NSIndexPath *)indexPath
{
    return _data[indexPath.row];
}

#pragma mark - UITableViewDelegate

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.01;
}

- (CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 16.0;
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section
{
    view.hidden = YES;
}

- (NSIndexPath *) tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    if (![item[@"type"] isEqualToString:[OABottomSheetHeaderCell getCellIdentifier]])
        return indexPath;
    else
        return nil;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (vwController.delegate)
        [vwController.delegate onNewModeSelected:(EOARouteStatisticsMode)[[self getItem:indexPath][@"mode"] integerValue]];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self.vwController dismiss];
}

@synthesize vwController;

@end

@interface OAStatisticsSelectionBottomSheetViewController ()

@end

@implementation OAStatisticsSelectionBottomSheetViewController

- (instancetype) initWithMode:(EOARouteStatisticsMode)mode
{
    _mode = mode;
    return [super initWithParam:nil];
}

- (void) setupView
{
    if (!self.screenObj)
        self.screenObj = [[OAStatisticsSelectionBottomSheetScreen alloc] initWithTable:self.tableView viewController:self param:self.customParam];
    
    [super setupView];
}

- (void)additionalSetup
{
    [super additionalSetup];
    self.tableBackgroundView.backgroundColor = UIColorFromRGB(color_bottom_sheet_background);
    self.buttonsView.subviews.firstObject.backgroundColor = UIColorFromRGB(color_bottom_sheet_background);;
    [self hideDoneButton];
}

- (void)applyLocalization
{
    [self.cancelButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
}

@end
