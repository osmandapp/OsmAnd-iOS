//
//  OAFirstMapillaryBottomSheetViewController.m
//  OsmAnd
//
//  Created by Paul on 4/4/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//


#import "OAFirstMapillaryBottomSheetViewController.h"
#import "Localization.h"
#import "OABottomSheetHeaderIconCell.h"
#import "OAUtilities.h"
#import "OAColors.h"
#import "OAMapPanelViewController.h"
#import "OASizes.h"
#import "OAAppSettings.h"
#import "OASimpleTableViewCell.h"
#import "OADividerCell.h"
#import "OASwitchTableViewCell.h"
#import "OARootViewController.h"
#import "OAMapWidgetRegistry.h"
#import "OAProducts.h"
#import "OAMapWidgetRegInfo.h"
#import "OsmAnd_Maps-Swift.h"

#define kButtonsDividerTag 150

@interface OAFirstMapillaryBottomSheetScreen ()

@end

@implementation OAFirstMapillaryBottomSheetScreen
{
    OsmAndAppInstance _app;
    OAFirstMapillaryBottomSheetViewController *vwController;
    OAMapWidgetRegistry *_mapWidgetRegistry;
    NSArray* _data;
}



@synthesize tableData, tblView;

- (id) initWithTable:(UITableView *)tableView viewController:(OAFirstMapillaryBottomSheetViewController *)viewController param:(id)param
{
    self = [super init];
    if (self)
    {
        [self initOnConstruct:tableView viewController:viewController];
    }
    return self;
}

- (void) initOnConstruct:(UITableView *)tableView viewController:(OAFirstMapillaryBottomSheetViewController *)viewController
{
    _app = [OsmAndApp instance];
    _mapWidgetRegistry = [OARootViewController instance].mapPanel.mapWidgetRegistry;
    
    vwController = viewController;
    tblView = tableView;
    tblView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    [self initData];
}

- (void) setupView
{
    [[self.vwController.buttonsView viewWithTag:kButtonsDividerTag] removeFromSuperview];
    NSMutableArray *arr = [NSMutableArray array];
    [arr addObject:@{
                     @"type" : [OABottomSheetHeaderIconCell getCellIdentifier],
                     @"title" : OALocalizedString(@"mapillary"),
                     @"description" : @"",
                     @"img" : @"ic_custom_mapillary_color_logo.png"
                     }];
    
    [arr addObject:@{
                     @"type" : [OASimpleTableViewCell getCellIdentifier],
                     @"title" : OALocalizedString(@"mapillary_descr"),
                     @"description" : @""
                     }];
    
    [arr addObject:@{ @"type" : [OADividerCell getCellIdentifier] } ];

    OAMapWidgetInfo *mapWidgetInfo = [_mapWidgetRegistry getWidgetInfoById:kInAppId_Addon_Mapillary];
    [arr addObject:@{
        @"type" : [OASwitchTableViewCell getCellIdentifier],
        @"name" : @"enable_mapil_widget",
        @"title" : OALocalizedString(@"mapillary_turn_on_widget"),
        @"description" : OALocalizedString(@"mapillary_turn_on_widget_descr"),
        @"value" : @([mapWidgetInfo isEnabledForAppMode:[[OAAppSettings sharedManager].applicationMode get]])
    }];

    _data = [NSArray arrayWithArray:arr];
}

- (void) initData
{
}

- (CGFloat) heightForRow:(NSIndexPath *)indexPath tableView:(UITableView *)tableView
{
    NSDictionary *item = _data[indexPath.row];
    if ([item[@"type"] isEqualToString:[OABottomSheetHeaderIconCell getCellIdentifier]] || [item[@"type"] isEqualToString:[OASimpleTableViewCell getCellIdentifier]] || [item[@"type"] isEqualToString:[OASwitchTableViewCell getCellIdentifier]])
    {
        return UITableViewAutomaticDimension;
    }
    else if ([item[@"type"] isEqualToString:[OADividerCell getCellIdentifier]])
    {
        return [OADividerCell cellHeight:0.5 dividerInsets:UIEdgeInsetsMake(6.0, 44.0, 4.0, 0.0)];
    }
    else
    {
        return 44.0;
    }
}

- (void) applyParameter:(id)sender
{
    if ([sender isKindOfClass:[UISwitch class]])
    {
        UISwitch *sw = (UISwitch *) sender;
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:sw.tag & 0x3FF inSection:sw.tag >> 10];
        NSDictionary *item = [self getItem:indexPath];
        NSString *name = item[@"name"];
        if (name)
        {
            BOOL isChecked = sw.on;
            if ([name isEqualToString:@"enable_mapil_widget"])
            {
                OAMapWidgetInfo *info = [_mapWidgetRegistry getWidgetInfoById:kInAppId_Addon_Mapillary];
                if (info)
                {
                    [_mapWidgetRegistry enableDisableWidgetForMode:[[OAAppSettings sharedManager].applicationMode get]
                                                        widgetInfo:info
                                                           enabled:@(isChecked)
                                                  recreateControls:YES];
                }
            }
        }
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
    if ([item[@"type"] isEqualToString:[OABottomSheetHeaderIconCell getCellIdentifier]])
    {
        OABottomSheetHeaderIconCell* cell = [tableView dequeueReusableCellWithIdentifier:[OABottomSheetHeaderIconCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OABottomSheetHeaderIconCell getCellIdentifier] owner:self options:nil];
            cell = (OABottomSheetHeaderIconCell *)[nib objectAtIndex:0];
            cell.backgroundColor = UIColor.clearColor;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if (cell)
        {
            cell.titleView.text = item[@"title"];
            cell.iconView.image = [UIImage imageNamed:item[@"img"]];
            cell.iconView.hidden = !cell.iconView.image;
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:[OASimpleTableViewCell getCellIdentifier]])
    {
        OASimpleTableViewCell *cell = [self.tblView dequeueReusableCellWithIdentifier:[OASimpleTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASimpleTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASimpleTableViewCell *) nib[0];
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
            cell.backgroundColor = [UIColor clearColor];
            cell.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
        }
        if (cell)
        {
            cell.titleLabel.text = item[@"title"];
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
            cell.dividerInsets = UIEdgeInsetsMake(6.0, 16.0, 4.0, 0.0);
            cell.dividerHight = 0.5;
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:[OASwitchTableViewCell getCellIdentifier]])
    {
        OASwitchTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OASwitchTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASwitchTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASwitchTableViewCell *) nib[0];
            cell.backgroundColor = [UIColor clearColor];
            [cell leftIconVisibility:NO];
        }
        if (cell)
        {
            cell.titleLabel.text = item[@"title"];
            cell.descriptionLabel.text = item[@"description"];

            cell.switchView.on = [item[@"value"] boolValue];
            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
            [cell.switchView removeTarget:nil action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.switchView addTarget:self action:@selector(applyParameter:) forControlEvents:UIControlEventValueChanged];
        }
        return cell;
    }
    return nil;
}

- (NSDictionary *) getItem:(NSIndexPath *)indexPath
{
    return _data[indexPath.row];
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self heightForRow:indexPath tableView:tableView];
}

#pragma mark - UITableViewDelegate

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.001;
}

- (CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 32.0;
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section
{
    view.hidden = YES;
}

@synthesize vwController;

@end

@interface OAFirstMapillaryBottomSheetViewController ()

@end

@implementation OAFirstMapillaryBottomSheetViewController

- (void) setupView
{
    if (!self.screenObj)
        self.screenObj = [[OAFirstMapillaryBottomSheetScreen alloc] initWithTable:self.tableView viewController:self param:nil];
    
    [super setupView];
}

- (void)additionalSetup
{
    [super additionalSetup];
    [super hideDoneButton];
}

- (void)applyLocalization
{
    [self.cancelButton setTitle:OALocalizedString(@"shared_string_ok") forState:UIControlStateNormal];
}

@end
