//
//  OAProfileSelectionBottomSheetViewController.m
//  OsmAnd
//
//  Created by nnngrach on 30.12.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAProfileSelectionBottomSheetViewController.h"
#import "OAActionConfigurationViewController.h"
#import "Localization.h"
#import "OABottomSheetHeaderCell.h"
#import "OAUtilities.h"
#import "OAColors.h"
#import "OAMapPanelViewController.h"
#import "OARootViewController.h"
#import "OASizes.h"
#import "OAAppSettings.h"
#import "OASimpleTableViewCell.h"
#import "OAMapSource.h"
#import "OAMapStyleAction.h"

#define kButtonsDividerTag 150

@implementation OAProfileSelectionBottomSheetScreen
{
    OsmAndAppInstance _app;
    OAQuickActionSelectionBottomSheetViewController *vwController;
    NSArray* _data;
    OASwitchableAction *_action;
}

@synthesize tableData, tblView;

- (id) initWithTable:(UITableView *)tableView viewController:(OAQuickActionSelectionBottomSheetViewController *)viewController param:(id)param
{
    self = [super init];
    if (self)
    {
        _action = param;
        [self initOnConstruct:tableView viewController:viewController];
    }
    return self;
}

- (void) initOnConstruct:(UITableView *)tableView viewController:(OAQuickActionSelectionBottomSheetViewController *)viewController
{
    _app = [OsmAndApp instance];
    
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
                     @"type" : [OABottomSheetHeaderCell getCellIdentifier],
                     @"title" : _action.getDescrTitle,
                     @"description" : @""
                     }];
    
    NSArray *stringKeys = [_action loadListFromParams];
    for (int i = 0; i < stringKeys.count; i++)
    {
        OAApplicationMode *mode = [OAApplicationMode valueOfStringKey:stringKeys[i] def:nil];
        if (!mode)
            continue;

        [arr addObject:@{
            @"type" : [OASimpleTableViewCell getCellIdentifier],
            @"title" : [mode toHumanString],
            @"param" : stringKeys[i],
            @"img" : [mode getIconName],
            @"iconColor" : [mode getProfileColor]
        }];
    }
    _data = [NSArray arrayWithArray:arr];
}

- (void) initData
{
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
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:[OASimpleTableViewCell getCellIdentifier]])
    {
        OASimpleTableViewCell* cell = nil;
        
        cell = [tableView dequeueReusableCellWithIdentifier:[OASimpleTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASimpleTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASimpleTableViewCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            NSString *imgName = item[@"img"];
            UIColor *imgColor = item[@"iconColor"];
            if (imgName && imgColor)
            {
                cell.leftIconView.image = [UIImage templateImageNamed:imgName];
                cell.leftIconView.tintColor = imgColor;
            }
            else if (imgName)
            {
                cell.leftIconView.image = [UIImage imageNamed:imgName];
                cell.leftIconView.tintColor = nil;
            }
            
            cell.titleLabel.text = item[@"title"];
            NSString *desc = item[@"descr"];
            cell.descriptionLabel.text = desc;
            [cell descriptionVisibility:desc.length != 0];
            BOOL isActive = [item[@"param"] isEqualToString:[OAAppSettings sharedManager].applicationMode.get.stringKey];
            cell.accessoryType = isActive ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
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
    return 0.001;
}

- (CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 10.0;
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section
{
    view.hidden = YES;
}

- (NSIndexPath *) tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.row];
    if (![item[@"type"] isEqualToString:[OABottomSheetHeaderCell getCellIdentifier]])
        return indexPath;
    else
        return nil;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.row];
    [_action executeWithParams:@[item[@"param"]]];
    [tableView deselectRowAtIndexPath:indexPath animated:true];
    [self.vwController dismiss];
}

- (void)doneButtonPressed
{
    OAActionConfigurationViewController *actionScreen = [[OAActionConfigurationViewController alloc] initWithAction:_action isNew:NO];
    [[OARootViewController instance].navigationController pushViewController:actionScreen animated:YES];
    [self.vwController dismiss];
}

@synthesize vwController;

@end

@interface OAProfileSelectionBottomSheetViewController ()

@end

@implementation OAProfileSelectionBottomSheetViewController

- (void) setupView
{
    if (!self.screenObj)
        self.screenObj = [[OAProfileSelectionBottomSheetScreen alloc] initWithTable:self.tableView viewController:self param:self.customParam];
    
    [super setupView];
}

- (void)additionalSetup
{
    [super additionalSetup];
    self.doneButton.layer.borderWidth = 2.0;
    self.doneButton.layer.borderColor = UIColorFromRGB(color_primary_purple).CGColor;
    [self.doneButton setBackgroundColor:[UIColorFromRGB(color_coordinates_background) colorWithAlphaComponent:.1]];
    [self.doneButton setTitleColor:UIColorFromRGB(color_primary_purple) forState:UIControlStateNormal];
}

- (void)applyLocalization
{
    [self.cancelButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
    [self.doneButton setTitle:OALocalizedString(@"quick_action_edit_action") forState:UIControlStateNormal];
}

@end
