//
//  OAPluginResetBottomSheet.m
//  OsmAnd
//
//  Created by nnngrach on 14.08.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAPluginResetBottomSheetViewController.h"
#import "Localization.h"
#import "OABottomSheetHeaderDescrButtonCell.h"
#import "OAUtilities.h"
#import "OAColors.h"
#import "OAMapPanelViewController.h"
#import "OARootViewController.h"
#import "OASizes.h"
#import "OAAppSettings.h"
#import "OADescrTitleCell.h"
#import "OADividerCell.h"
#import "OASettingSwitchNoImageCell.h"
#import "OAMapWidgetRegistry.h"
#import "OAProducts.h"
#import "OAMapWidgetRegInfo.h"
#import "OAApplicationMode.h"
#import "OATitleTwoIconsRoundCell.h"
#import "OAAppData.h"
#import "OsmAndApp.h"
#import "OAMapWidgetRegistry.h"
#import "OARootViewController.h"

#define kButtonsDividerTag 150
#define kTitleIconRoundCell @"OATitleTwoIconsRoundCell"
#define update_vidgests_notification @"update_vidgests_notification"
#define reset_vidgests_notification @"reset_vidgests_notification"
#define reseting_appmode_key @"appMode"

@interface OAPluginResetBottomSheetScreen ()

@end

@implementation OAPluginResetBottomSheetScreen
{
    OsmAndAppInstance _app;
    OAPluginResetBottomSheetViewController *vwController;
    OAMapWidgetRegistry *_mapWidgetRegistry;
    NSDictionary* _data;
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
    [[self.vwController.buttonsView viewWithTag:kButtonsDividerTag] removeFromSuperview];
    NSMutableDictionary *model = [NSMutableDictionary new];
    NSMutableArray *arr = [NSMutableArray array];
    
    [arr addObject:@{
                     @"type" : @"OABottomSheetHeaderDescrButtonCell",
                     @"title" : OALocalizedString(@"reset_to_default"),
                     @"description" : @"",
                     @"img" : @"ic_custom_reset.png"
                     }];
    [model setObject:[NSArray arrayWithArray:arr] forKey:@(0)];
    
    [arr removeAllObjects];
    [arr addObject:@{
           @"type" : kTitleIconRoundCell,
           @"title" : _appMode.toHumanString,
           @"img" : _appMode.getIconName,
           @"key" : @"swap_points",
           @"round_bottom" : @(YES),
           @"round_top" : @(YES)
       }];
    [model setObject:[NSArray arrayWithArray:arr] forKey:@(1)];
    
    [arr removeAllObjects];
    [arr addObject:@{
                     @"type" : @"OADescrTitleCell",
                     @"title" : OALocalizedString(@"reset_profile_action_descr"),
                     @"description" : @""
                     }];
    [arr addObject:@{ @"type" : @"OADividerCell" } ];
    [model setObject:[NSArray arrayWithArray:arr] forKey:@(2)];
     
    _data = [NSDictionary dictionaryWithDictionary:model];
}

- (void) updateWithAppMode:(OAApplicationMode *)appMode
{
    _appMode = appMode;
    [self setupView];
    [self.tblView reloadData];
}

- (NSDictionary *) getItem:(NSIndexPath *)indexPath
{
    return _data[@(indexPath.section)][indexPath.row];
}

- (void) initData
{
}

- (CGFloat) heightForRow:(NSIndexPath *)indexPath tableView:(UITableView *)tableView
{
    NSDictionary *item = [self getItem:indexPath];
    if ([item[@"type"] isEqualToString:@"OABottomSheetHeaderDescrButtonCell"])
    {
        return UITableViewAutomaticDimension;
    }
    else if ([item[@"type"] isEqualToString:@"OADescrTitleCell"])
    {
        return [OADescrTitleCell getHeight:item[@"title"] desc:item[@"description"] cellWidth:DeviceScreenWidth];
    }
    else if ([item[@"type"] isEqualToString:@"OASettingSwitchNoImageCell"])
    {
        return [OASettingSwitchNoImageCell getHeight:item[@"title"] desc:item[@"description"] cellWidth:tableView.bounds.size.width];
    }
    else if ([item[@"type"] isEqualToString:kTitleIconRoundCell])
    {
        return [OATitleTwoIconsRoundCell getHeight:item[@"title"] cellWidth:tableView.bounds.size.width];
    }
    else if ([item[@"type"] isEqualToString:@"OADividerCell"])
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
    NSArray *sectionData = _data[@(section)];
    return sectionData.count;
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    
    if ([item[@"type"] isEqualToString:@"OABottomSheetHeaderDescrButtonCell"])
    {
        static NSString* const identifierCell = @"OABottomSheetHeaderDescrButtonCell";
        OABottomSheetHeaderDescrButtonCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OABottomSheetHeaderButtonCell" owner:self options:nil];
            cell = (OABottomSheetHeaderDescrButtonCell *)[nib objectAtIndex:0];
        }
        if (cell)
        {
            cell.backgroundColor = UIColor.clearColor;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.titleView.text = item[@"title"];
            [cell.iconView setImage:[[UIImage imageNamed:item[@"img"]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
            cell.iconView.tintColor = UIColorFromRGB(color_primary_purple);
            cell.iconView.hidden = !cell.iconView.image;
            [cell.closeButton removeTarget:NULL action:NULL forControlEvents:UIControlEventAllEvents];
            [cell.closeButton addTarget:self action:@selector(onCloseButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:kTitleIconRoundCell])
    {
        static NSString* const identifierCell = kTitleIconRoundCell;
        OATitleTwoIconsRoundCell* cell = nil;
        
        cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:kTitleIconRoundCell owner:self options:nil];
            cell = (OATitleTwoIconsRoundCell *)[nib objectAtIndex:0];
        }
        if (cell)
        {
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.backgroundColor = UIColor.clearColor;
            cell.titleView.text = item[@"title"];
            if (![item[@"skip_tint"] boolValue])
            {
                [cell.leftIconView setImage:[[UIImage imageNamed:item[@"img"]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
                cell.leftIconView.tintColor = UIColorFromRGB(color_primary_purple);
                cell.rightIconView.hidden = YES;
            }
            else
            {
                [cell.leftIconView setImage:[UIImage imageNamed:item[@"img"]]];
                cell.rightIconView.hidden = YES;
            }
            [cell roundCorners:[item[@"round_top"] boolValue] bottomCorners:[item[@"round_bottom"] boolValue]];
            cell.separatorInset = UIEdgeInsetsMake(0., 32., 0., 16.);
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:@"OADescrTitleCell"])
    {
        OADescrTitleCell* cell;
        cell = (OADescrTitleCell *)[self.tblView dequeueReusableCellWithIdentifier:@"OADescrTitleCell"];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OADescrTitleCell" owner:self options:nil];
            cell = (OADescrTitleCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            cell.backgroundColor = UIColor.clearColor;
            cell.contentView.backgroundColor = UIColor.clearColor;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.descriptionView.text = item[@"title"];
            cell.descriptionView.textColor = [UIColor blackColor];
            cell.descriptionView.backgroundColor = UIColor.clearColor;
            cell.textView.hidden = YES;
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:@"OADividerCell"])
    {
        static NSString* const identifierCell = @"OADividerCell";
        OADividerCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OADividerCell" owner:self options:nil];
            cell = (OADividerCell *)[nib objectAtIndex:0];
        }
        cell.backgroundColor = UIColor.clearColor;
        cell.dividerColor = UIColorFromRGB(color_divider_blur);
        cell.dividerInsets = UIEdgeInsetsMake(16, 0, 8, 0);
        cell.dividerHight = 0.5;
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

@synthesize vwController;

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
}

- (void)additionalSetup
{
    [super additionalSetup];
    self.tableBackgroundView.backgroundColor = UIColorFromRGB(color_bottom_sheet_background);
    self.buttonsView.backgroundColor = UIColorFromRGB(color_bottom_sheet_background);
    self.buttonsView.subviews.firstObject.backgroundColor = UIColor.clearColor;
}

- (void)applyLocalization
{
    [self.cancelButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
    [self.doneButton setTitle:OALocalizedString(@"shared_string_reset") forState:UIControlStateNormal];
}

-(void) doneButtonPressed:(id)sender
{
    OAApplicationMode * menuAppMode = (OAApplicationMode *)self.customParam;
    
    [self resetProfileSettingsForAppMode: menuAppMode];
    
    if (menuAppMode.isCustomProfile)
        menuAppMode = [self readBackupForAppMode:menuAppMode];
    
    if (self.delegate)
        [self.delegate updateViewControllerWithAppMode:menuAppMode];
    
    [self dismiss];
}

-(OAApplicationMode *) readBackupForAppMode:(OAApplicationMode *)appMode
{
    NSString *backupFilePath = [[[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"osfBackup"] stringByAppendingPathComponent:appMode.stringKey] stringByAppendingPathExtension:@"plst"];
    NSDictionary *backup = [NSDictionary dictionaryWithContentsOfFile:backupFilePath];
    
    if (backup && backup[@"appMode"])
    {
        [OAApplicationMode deleteCustomModes:@[appMode]];
        appMode = [OAApplicationMode fromModeBean:[OAApplicationModeBean fromJson:backup[@"appMode"]]];
        [OAApplicationMode saveProfile:appMode];
        self.customParam = appMode;
        return appMode;
    }
    return appMode;
}

-(void) resetProfileSettingsForAppMode:(OAApplicationMode *)appMode
{
    [OAAppSettings.sharedManager resetAllProfileSettingsForMode:appMode];
    [OAAppData.defaults resetProfileSettingsForMode:appMode];
    [OsmAndApp.instance resetMapStyleForAppMode:appMode.stringKey];
    NSDictionary* appModeDict = [NSDictionary dictionaryWithObject:appMode forKey:reseting_appmode_key];
    [[NSNotificationCenter defaultCenter] postNotificationName:reset_vidgests_notification object:nil userInfo:appModeDict];
    [[NSNotificationCenter defaultCenter] postNotificationName:update_vidgests_notification object:nil userInfo:nil];
}

@end
