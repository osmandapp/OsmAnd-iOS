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
#import "OsmAnd_Maps-Swift.h"
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
#import "GeneratedAssetSymbols.h"
#import "OAPluginsHelper.h"

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
    tblView.separatorColor = [UIColor colorNamed:ACColorNameCustomSeparator];
    [[self.vwController.buttonsView viewWithTag:kButtonsDividerTag] removeFromSuperview];
    NSMutableArray *arr = [NSMutableArray array];
    [arr addObject:@{
                     @"type" : [OABottomSheetHeaderCell getCellIdentifier],
                     @"title" : OALocalizedString(@"stats_select_graph_data"),
                     @"description" : @""
                     }];

    NSMutableArray<NSArray<NSNumber *> *> *allTypes = [NSMutableArray array];
    [allTypes addObject:@[@(GPXDataSetTypeAltitude)]];
    [allTypes addObject:@[@(GPXDataSetTypeSlope)]];
    [allTypes addObject:@[@(GPXDataSetTypeSpeed)]];
    [allTypes addObject:@[@(GPXDataSetTypeAltitude), @(GPXDataSetTypeSlope)]];
    [allTypes addObject:@[@(GPXDataSetTypeAltitude), @(GPXDataSetTypeSpeed)]];
    [OAPluginsHelper getAvailableGPXDataSetTypes:vwController.analysis availableTypes:allTypes];

    for (NSInteger i = 0; i < allTypes.count; i++)
    {
        NSArray<NSNumber *> *types = allTypes[i];
        NSString *title = @"";
        NSString *iconName = @"";
        BOOL hasData = NO;
        BOOL roundTop = i == 0;
        BOOL roundBottom = i == allTypes.count;
        if (types.count == 2)
        {
            title = [NSString stringWithFormat:OALocalizedString(@"ltr_or_rtl_combine_via_slash"),
                     [OAGPXDataSetType getTitle:types.firstObject.integerValue],
                     [OAGPXDataSetType getTitle:types.lastObject.integerValue]];
            iconName = @"ic_custom_altitude_and_slope";
            hasData = [vwController.analysis hasData:[OAGPXDataSetType getDataKey:types.firstObject.integerValue]]
                    || [vwController.analysis hasData:[OAGPXDataSetType getDataKey:types.lastObject.integerValue]];
        }
        else
        {
            title = [OAGPXDataSetType getTitle:types.firstObject.integerValue];
            iconName = [OAGPXDataSetType getIconName:types.firstObject.integerValue];
            hasData = [vwController.analysis hasData:[OAGPXDataSetType getDataKey:types.firstObject.integerValue]];
        }
        [arr addObject:@{
            @"type" : [OATitleIconRoundCell getCellIdentifier],
            @"title" : title,
            @"img" : iconName,
            @"types" : types,
            @"hasData" : @(hasData),
            @"round_top" : @(roundTop),
            @"round_bottom" : @(roundBottom)
        }];
    }

    _data = [NSArray arrayWithArray:arr];
}

- (void) initData
{
}

- (CGFloat) heightForRow:(NSIndexPath *)indexPath tableView:(UITableView *)tableView
{
    NSDictionary *item = [self getItem:indexPath];
    
    if ([item[@"type"] isEqualToString:[OABottomSheetHeaderCell getCellIdentifier]])
    {
        return UITableViewAutomaticDimension;
    }
    else if ([item[@"type"] isEqualToString:[OATitleIconRoundCell getCellIdentifier]])
    {
        return [OATitleIconRoundCell getHeight:item[@"title"] cellWidth:tableView.bounds.size.width];
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
            cell.backgroundColor = UIColor.clearColor;
            cell.separatorInset = UIEdgeInsetsMake(0., 32., 0., 16.);
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if (cell)
        {
            NSArray<NSNumber *> *types = item[@"types"];

            cell.titleView.text = item[@"title"];
            cell.iconView.image = [UIImage templateImageNamed:item[@"img"]];
            cell.iconColorNormal = [UIColor colorNamed:[vwController.types isEqual:types] ? ACColorNameIconColorActive : ACColorNameIconColorDisabled];
            [cell roundCorners:[item[@"round_top"] boolValue] bottomCorners:[item[@"round_bottom"] boolValue]];

            BOOL isSpeed = [types containsObject:@(GPXDataSetTypeSpeed)] || [types containsObject:@(GPXDataSetTypeSensorSpeed)];
            cell.textColorNormal = [UIColor colorNamed:[item[@"hasData"] boolValue] && ((isSpeed && vwController.analysis.hasSpeedData) || !isSpeed) ? ACColorNameTextColorPrimary : ACColorNameButtonBgColorTertiary];
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
    {
        NSDictionary *item = [self getItem:indexPath];
        NSArray<NSNumber *> *types = item[@"types"];
        BOOL isSpeed = [types containsObject:@(GPXDataSetTypeSpeed)] || [types containsObject:@(GPXDataSetTypeSensorSpeed)];
        if ([item[@"hasData"] boolValue] && ((isSpeed && vwController.analysis.hasSpeedData) || !isSpeed))
        {
            [vwController.delegate onTypesSelected:types];
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
            [self.vwController dismiss];
        }
    };
}

@synthesize vwController;

@end

@interface OAStatisticsSelectionBottomSheetViewController ()

@end

@implementation OAStatisticsSelectionBottomSheetViewController

- (instancetype)initWithTypes:(NSArray<NSNumber *> *)types analysis:(OAGPXTrackAnalysis *)analysis;
{
    _types = types;
    _analysis = analysis;
    return [super initWithParam:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[ThemeManager shared] configureWithAppMode:[OAAppSettings sharedManager].applicationMode.get];
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
    self.tableBackgroundView.backgroundColor = [UIColor colorNamed:ACColorNameViewBg];
    self.buttonsView.subviews.firstObject.backgroundColor = [UIColor colorNamed:ACColorNameViewBg];
    [self hideDoneButton];
}

- (void)applyLocalization
{
    [self.cancelButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
}

@end
