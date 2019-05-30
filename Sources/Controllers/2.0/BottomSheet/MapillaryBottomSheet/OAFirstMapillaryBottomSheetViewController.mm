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
#import "OARootViewController.h"
#import "OASizes.h"
#import "OAAppSettings.h"
#import "OADescrTitleCell.h"
#import "OADividerCell.h"
#import "OASettingSwitchNoImageCell.h"
#import "OARootViewController.h"
#import "OAMapWidgetRegistry.h"
#import "OAProducts.h"
#import "OAMapWidgetRegInfo.h"

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
                     @"type" : @"OABottomSheetHeaderIconCell",
                     @"title" : OALocalizedString(@"map_settings_mapillary"),
                     @"description" : @"",
                     @"img" : @"ic_custom_mapillary_color_logo.png"
                     }];
    
    [arr addObject:@{
                     @"type" : @"OADescrTitleCell",
                     @"title" : OALocalizedString(@"mapillary_descr"),
                     @"description" : @""
                     }];
    
    [arr addObject:@{ @"type" : @"OADividerCell" } ];
    
    [arr addObject:@{
                     @"type" : @"OASettingSwitchNoImageCell",
                     @"name" : @"enable_mapil_widget",
                     @"title" : OALocalizedString(@"mapillary_turn_on_widget"),
                     @"description" : OALocalizedString(@"mapillary_turn_on_widget_descr"),
                     @"value" : @([_mapWidgetRegistry isVisible:kInAppId_Addon_Mapillary])
                     }];
    
    
    _data = [NSArray arrayWithArray:arr];
}

- (void) initData
{
}

- (CGFloat) heightForRow:(NSIndexPath *)indexPath tableView:(UITableView *)tableView
{
    NSDictionary *item = _data[indexPath.row];
    if ([item[@"type"] isEqualToString:@"OABottomSheetHeaderIconCell"])
    {
        return [OABottomSheetHeaderIconCell getHeight:item[@"title"] cellWidth:DeviceScreenWidth];
    }
    else if ([item[@"type"] isEqualToString:@"OADescrTitleCell"])
    {
        return [OADescrTitleCell getHeight:item[@"title"] desc:item[@"description"] cellWidth:DeviceScreenWidth];
    }
    else if ([item[@"type"] isEqualToString:@"OASettingSwitchNoImageCell"])
    {
        return [OASettingSwitchNoImageCell getHeight:item[@"title"] desc:item[@"description"] cellWidth:tableView.bounds.size.width];
    }
    else if ([item[@"type"] isEqualToString:@"OADividerCell"])
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
                OAMapWidgetRegInfo *info = [_mapWidgetRegistry widgetByKey:kInAppId_Addon_Mapillary];
                [_mapWidgetRegistry setVisibility:info visible:isChecked collapsed:NO];
                [[OARootViewController instance].mapPanel recreateControls];
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
    
    
    if ([item[@"type"] isEqualToString:@"OABottomSheetHeaderIconCell"])
    {
        static NSString* const identifierCell = @"OABottomSheetHeaderIconCell";
        OABottomSheetHeaderIconCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OABottomSheetHeaderIconCell" owner:self options:nil];
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
            cell.descriptionView.text = item[@"title"];
            cell.descriptionView.textColor = [UIColor blackColor];
            cell.backgroundColor = [UIColor clearColor];
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
            cell.backgroundColor = UIColor.clearColor;
            cell.dividerColor = UIColorFromRGB(color_divider_blur);
            cell.dividerInsets = UIEdgeInsetsMake(6.0, 16.0, 4.0, 0.0);
            cell.dividerHight = 0.5;
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:@"OASettingSwitchNoImageCell"])
    {
        static NSString* const identifierCell = @"OASettingSwitchNoImageCell";
        OASettingSwitchNoImageCell* cell = nil;
        
        cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OASettingSwitchNoImageCell" owner:self options:nil];
            cell = (OASettingSwitchNoImageCell *)[nib objectAtIndex:0];
            cell.textView.numberOfLines = 0;
        }
        
        if (cell)
        {
            cell.backgroundColor = [UIColor clearColor];
            [cell.textView setText: item[@"title"]];
            [cell.descriptionView setText:item[@"description"]];
            cell.switchView.on = [item[@"value"] boolValue];
            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
            [cell.switchView addTarget:self action:@selector(applyParameter:) forControlEvents:UIControlEventValueChanged];
            cell.switchView.tintColor = [UIColor whiteColor];
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

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self heightForRow:indexPath tableView:tableView];
}

#pragma mark - UITableViewDelegate

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 1;
}

- (CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 32.0;
}

- (NSIndexPath *) tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.row];
    if (![item[@"type"] isEqualToString:@"OASwitchCell"])
        return indexPath;
    else
        return nil;
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

- (void) commonInit
{
    [super commonInit];
    [super hideDoneButton];
}

- (void)applyLocalization
{
    [self.cancelButton setTitle:OALocalizedString(@"shared_string_ok") forState:UIControlStateNormal];
}

@end
