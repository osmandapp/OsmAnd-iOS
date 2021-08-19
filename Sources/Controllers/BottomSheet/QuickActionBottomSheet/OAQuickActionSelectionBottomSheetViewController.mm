//
//  OAQuickActionSelectionBottomSheetViewController.m
//  OsmAnd
//
//  Created by Paul on 4/18/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAQuickActionSelectionBottomSheetViewController.h"
#import "OAActionConfigurationViewController.h"
#import "Localization.h"
#import "OABottomSheetHeaderCell.h"
#import "OAUtilities.h"
#import "OAColors.h"
#import "OAMapPanelViewController.h"
#import "OARootViewController.h"
#import "OASizes.h"
#import "OAAppSettings.h"
#import "OASwitchableAction.h"
#import "OAMenuSimpleCell.h"
#import "OAMapSource.h"
#import "OAMapStyleAction.h"

#define kButtonsDividerTag 150
#define kMessageFieldIndex 1

@interface OAQuickActionSelectionBottomSheetScreen ()

@end

@implementation OAQuickActionSelectionBottomSheetScreen
{
    OsmAndAppInstance _app;
    OAQuickActionSelectionBottomSheetViewController *vwController;
    NSArray* _data;
    
    OASwitchableAction *_action;
    EOAMapSourceType _type;
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
    NSArray *params = _action.loadListFromParams;
    [arr addObject:@{
                     @"type" : [OABottomSheetHeaderCell getCellIdentifier],
                     @"title" : _action.getDescrTitle,
                     @"description" : @""
                     }];
    if (vwController.type == EOAMapSourceTypeStyle)
    {
        if ([_action isKindOfClass:OAMapStyleAction.class])
        {
            OAMapStyleAction *mapStyleAction = (OAMapStyleAction *) _action;
            for (NSString *param in params)
            {
                OAMapSource *source = mapStyleAction.offlineMapSources[param];
                if (!source)
                    continue;
                [arr addObject:@{
                    @"type" : [OAMenuSimpleCell getCellIdentifier],
                    @"title" : param,
                    @"source" : source,
                    @"img" : [NSString stringWithFormat:@"img_mapstyle_%@", [source.resourceId stringByReplacingOccurrencesOfString:@".render.xml" withString:@""]]
                }];
            }
        }
    }
    else
    {
        for (NSArray *pair in params)
        {
            [arr addObject:@{
                             @"type" : [OAMenuSimpleCell getCellIdentifier],
                             @"title" : pair.lastObject,
                             @"value" : pair.firstObject,
                             @"param" : pair,
                             @"img" : @"ic_custom_map_style"
                             }];
        }
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
    else if ([item[@"type"] isEqualToString:[OAMenuSimpleCell getCellIdentifier]])
    {
        OAMenuSimpleCell* cell = nil;
        cell = [tableView dequeueReusableCellWithIdentifier:[OAMenuSimpleCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAMenuSimpleCell getCellIdentifier] owner:self options:nil];
            cell = (OAMenuSimpleCell *)[nib objectAtIndex:0];
            cell.backgroundColor = UIColor.clearColor;
        }
        
        if (cell)
        {
            UIImage *img = nil;
            NSString *imgName = item[@"img"];
            if (imgName)
                img = [UIImage imageNamed:imgName];
            
            cell.textView.text = item[@"title"];
            NSString *desc = item[@"descr"];
            cell.descriptionView.text = desc;
            cell.descriptionView.hidden = desc.length == 0;
            cell.imgView.image = img;
            if (!cell.accessoryView)
                cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"menu_cell_selected"]];
            if ([cell needsUpdateConstraints])
                [cell setNeedsUpdateConstraints];
            BOOL isActive;
            switch (vwController.type)
            {
                case EOAMapSourceTypeSource:
                case EOAMapSourceTypeStyle:
                {
                    isActive = [_app.data.lastMapSource.name isEqualToString:item[@"title"]];
                    break;
                }
                case EOAMapSourceTypeOverlay:
                {
                    isActive = [_app.data.overlayMapSource.name isEqualToString:item[@"title"]]
                    || (_app.data.overlayMapSource == nil && [item[@"value"] isEqualToString:@"no_overlay"]);
                    break;
                }
                case EOAMapSourceTypeUnderlay:
                {
                    isActive = [_app.data.underlayMapSource.name isEqualToString:item[@"title"]]
                    || (_app.data.underlayMapSource == nil && [item[@"value"] isEqualToString:@"no_underlay"]);
                    break;
                }
                default:
                {
                    isActive = NO;
                    break;
                }
            }
            cell.accessoryView.hidden = !isActive;
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
    if (vwController.type == EOAMapSourceTypeStyle)
    {
        OAMapSource *newMapSource = item[@"source"];
        _app.data.lastMapSource = newMapSource;
    }
    else
    {
        [_action executeWithParams:item[@"param"]];
    }
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

@interface OAQuickActionSelectionBottomSheetViewController ()

@end

@implementation OAQuickActionSelectionBottomSheetViewController

- (instancetype) initWithAction:(OASwitchableAction *)action type:(EOAMapSourceType)type
{
    _type = type;
    return [super initWithParam:action];
}

- (void) setupView
{
    if (!self.screenObj)
        self.screenObj = [[OAQuickActionSelectionBottomSheetScreen alloc] initWithTable:self.tableView viewController:self param:self.customParam];
    
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
    [self.doneButton setTitle:OALocalizedString(@"edit_action") forState:UIControlStateNormal];
}

@end
