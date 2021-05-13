//
//  OAPluginResetBottomSheet.m
//  OsmAnd
//
//  Created by nnngrach on 14.08.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAPluginResetBottomSheetViewController.h"
#import "Localization.h"
#import "OABottomSheetHeaderButtonCell.h"
#import "OAUtilities.h"
#import "OAColors.h"
#import "OAMapPanelViewController.h"
#import "OARootViewController.h"
#import "OASizes.h"
#import "OAAppSettings.h"
#import "OADescrTitleCell.h"
#import "OADividerCell.h"
#import "OAMapWidgetRegistry.h"
#import "OAProducts.h"
#import "OAMapWidgetRegInfo.h"
#import "OAApplicationMode.h"
#import "OATitleTwoIconsRoundCell.h"
#import "OAAppData.h"
#import "OsmAndApp.h"
#import "OAMapWidgetRegistry.h"
#import "OARootViewController.h"
#import "OAMapStyleSettings.h"
#import "OASettingsHelper.h"

#define kButtonsTag 1
#define kButtonsDividerTag 150
#define kBottomSheetHeaderButtonCell @"OABottomSheetHeaderButtonCell"
#define kTitleTwoIconsRoundCell @"OATitleTwoIconsRoundCell"
#define kDescrTitleCell @"OADescrTitleCell"
#define kDividerCell @"OADividerCell"

@interface OAPluginResetBottomSheetScreen ()

@end

@implementation OAPluginResetBottomSheetScreen
{
    OsmAndAppInstance _app;
    OAPluginResetBottomSheetViewController *vwController;
    OAMapWidgetRegistry *_mapWidgetRegistry;
    NSArray* _data;
    OAApplicationMode *_appMode;
}
@synthesize tableData, tblView;

- (id) initWithTable:(UITableView *)tableView viewController:(OAPluginResetBottomSheetViewController *)viewController param:(id)param
{
    self = [super init];
    if (self)
    {
        _appMode = (OAApplicationMode *)param;
        [self initOnConstruct:tableView viewController:viewController];
    }
    return self;
}

- (void) initOnConstruct:(UITableView *)tableView viewController:(OAPluginResetBottomSheetViewController *)viewController
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
    [[vwController.buttonsView viewWithTag:kButtonsDividerTag] removeFromSuperview];
    NSMutableArray *model = [NSMutableArray new];
    NSMutableArray *arr = [NSMutableArray array];
    
    [arr addObject:@{
                     @"type" : kBottomSheetHeaderButtonCell,
                     @"title" : OALocalizedString(@"reset_to_default"),
                     @"description" : @"",
                     @"img" : @"ic_custom_reset.png"
                     }];
    [model addObject:[NSArray arrayWithArray:arr]];
    
    [arr removeAllObjects];
    [arr addObject:@{
           @"type" : kTitleTwoIconsRoundCell,
           @"title" : _appMode.toHumanString,
           @"img" : _appMode.getIconName,
           @"color" : UIColorFromRGB(_appMode.getIconColor),
           @"key" : @"swap_points",
           @"round_bottom" : @(YES),
           @"round_top" : @(YES)
       }];
    [model addObject:[NSArray arrayWithArray:arr]];
    
    [arr removeAllObjects];
    [arr addObject:@{
                     @"type" : kDescrTitleCell,
                     @"title" : OALocalizedString(@"reset_profile_action_descr"),
                     @"description" : @""
                     }];
    [arr addObject:@{ @"type" : kDividerCell } ];
    [model addObject:[NSArray arrayWithArray:arr]];

    _data = [NSArray arrayWithArray:model];
}

- (NSDictionary *) getItem:(NSIndexPath *)indexPath
{
    return _data[indexPath.section][indexPath.row];
}

- (void) initData
{
}

- (CGFloat) heightForRow:(NSIndexPath *)indexPath tableView:(UITableView *)tableView
{
    NSDictionary *item = [self getItem:indexPath];
    NSString *type = item[@"type"];
    if ([type isEqualToString:kBottomSheetHeaderButtonCell] || [type isEqualToString:kDescrTitleCell])
    {
        return UITableViewAutomaticDimension;
    }
    else if ([type isEqualToString:kTitleTwoIconsRoundCell])
    {
        return UITableViewAutomaticDimension;
    }
    else if ([type isEqualToString:kDividerCell])
    {
        return [OADividerCell cellHeight:0.5 dividerInsets:UIEdgeInsetsMake(0, 0, 8, 0)];
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
    NSArray *sectionData = _data[section];
    return sectionData.count;
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    
    if ([item[@"type"] isEqualToString:kBottomSheetHeaderButtonCell])
    {
        static NSString* const identifierCell = kBottomSheetHeaderButtonCell;
        OABottomSheetHeaderDescrButtonCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:kBottomSheetHeaderButtonCell owner:self options:nil];
            cell = (OABottomSheetHeaderButtonCell *)[nib objectAtIndex:0];
            cell.backgroundColor = UIColor.clearColor;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.iconView.tintColor = UIColorFromRGB(color_primary_purple);
        }
        if (cell)
        {
            cell.titleView.text = item[@"title"];
            [cell.iconView setImage:[UIImage templateImageNamed:item[@"img"]]];
            cell.iconView.hidden = !cell.iconView.image;
            [cell.closeButton removeTarget:NULL action:NULL forControlEvents:UIControlEventAllEvents];
            [cell.closeButton addTarget:self action:@selector(onCloseButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:kTitleTwoIconsRoundCell])
    {
        static NSString* const identifierCell = kTitleTwoIconsRoundCell;
        OATitleTwoIconsRoundCell* cell = nil;
        
        cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:kTitleTwoIconsRoundCell owner:self options:nil];
            cell = (OATitleTwoIconsRoundCell *)[nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.backgroundColor = UIColor.clearColor;
            cell.separatorInset = UIEdgeInsetsMake(0., 32., 0., 16.);
        }
        if (cell)
        {
            cell.titleView.text = item[@"title"];
            if (![item[@"skip_tint"] boolValue])
            {
                [cell.leftIconView setImage:[UIImage templateImageNamed:item[@"img"]]];
                cell.leftIconView.tintColor = item[@"color"];
                cell.rightIconView.hidden = YES;
            }
            else
            {
                [cell.leftIconView setImage:[UIImage imageNamed:item[@"img"]]];
                cell.rightIconView.hidden = YES;
            }
            [cell roundCorners:[item[@"round_top"] boolValue] bottomCorners:[item[@"round_bottom"] boolValue]];
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:kDescrTitleCell])
    {
        OADescrTitleCell* cell;
        cell = (OADescrTitleCell *)[self.tblView dequeueReusableCellWithIdentifier:kDescrTitleCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:kDescrTitleCell owner:self options:nil];
            cell = (OADescrTitleCell *)[nib objectAtIndex:0];
            cell.backgroundColor = UIColor.clearColor;
            cell.contentView.backgroundColor = UIColor.clearColor;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.descriptionView.textColor = [UIColor blackColor];
            cell.descriptionView.backgroundColor = UIColor.clearColor;
            cell.textView.hidden = YES;
        }
        if (cell)
        {
            cell.descriptionView.text = item[@"title"];
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:kDividerCell])
    {
        static NSString* const identifierCell = kDividerCell;
        OADividerCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:kDividerCell owner:self options:nil];
            cell = (OADividerCell *)[nib objectAtIndex:0];
            cell.backgroundColor = UIColor.clearColor;
            cell.dividerColor = UIColorFromRGB(color_divider_blur);
            cell.dividerInsets = UIEdgeInsetsMake(16, 0, 8, 0);
            cell.dividerHight = 0.5;
        }
        return cell;
    }
    else
    {
        return nil;
    }
}

- (void) onCloseButtonPressed:(id)sender
{
    [vwController dismiss];
}

#pragma mark - UITableViewDelegate

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self heightForRow:indexPath tableView:tableView];
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.001;
}

- (CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 16.0;
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section
{
    view.hidden = YES;
}

@end

@interface OAPluginResetBottomSheetViewController ()

@end

@implementation OAPluginResetBottomSheetViewController

- (void) setupView
{
    if (!self.screenObj)
        self.screenObj = [[OAPluginResetBottomSheetScreen alloc] initWithTable:self.tableView viewController:self param:self.customParam];
    
    [super setupView];
}

- (void) setupButtons
{
    [super setupButtons];
    self.doneButton.backgroundColor = UIColorFromRGB(color_bottom_sheet_secondary);
    [self.doneButton setTitleColor:UIColorFromRGB(color_primary_red) forState:UIControlStateNormal];
    self.doneButton.tag = kButtonsTag;
    self.cancelButton.tag = kButtonsTag;
}

- (void)additionalSetup
{
    [super additionalSetup];
    self.tableBackgroundView.backgroundColor = UIColorFromRGB(color_bottom_sheet_background);
    self.buttonsView.backgroundColor = UIColorFromRGB(color_bottom_sheet_background);
 
    for (UIView *v in self.buttonsView.subviews)
    {
        if (v.tag != kButtonsTag)
            v.backgroundColor = UIColor.clearColor;
    }
}

- (void)applyLocalization
{
    [self.cancelButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
    [self.doneButton setTitle:OALocalizedString(@"shared_string_reset") forState:UIControlStateNormal];
}

-(void) doneButtonPressed:(id)sender
{
    if (self.delegate)
        [self.delegate onPluginSettingsReset];
    
    [self dismiss];
}

@end
