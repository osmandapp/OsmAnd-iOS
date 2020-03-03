//
//  OAWikiLinkBottomSheetViewController.m
//  OsmAnd
//
//  Created by Paul on 4/18/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAWikiLinkBottomSheetViewController.h"
#import "OAActionConfigurationViewController.h"
#import "Localization.h"
#import "OABottomSheetHeaderDescrButtonCell.h"
#import "OAUtilities.h"
#import "OAColors.h"
#import "OASizes.h"
#import "OAAppSettings.h"
#import "OATitleIconRoundCell.h"
#import "OACollectionViewCell.h"
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

#define kTitleIconRoundCell @"OATitleIconRoundCell"

@interface OAWikiLinkBottomSheetScreen ()

@end

@implementation OAWikiLinkBottomSheetScreen
{
    OsmAndAppInstance _app;
    OAWikiLinkBottomSheetViewController *vwController;
    NSArray* _data;
    NSString *_url;
}

@synthesize tableData, tblView;

- (id) initWithTable:(UITableView *)tableView viewController:(OAWikiLinkBottomSheetViewController *)viewController param:(id)param
{
    self = [super init];
    if (self)
    {
        _url = param;
        [self initOnConstruct:tableView viewController:viewController];
    }
    return self;
}

- (void) initOnConstruct:(UITableView *)tableView viewController:(OAWikiLinkBottomSheetViewController *)viewController
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
                     @"type" : @"OABottomSheetHeaderDescrButtonCell",
                     @"title" : OALocalizedString(@"wiki_sheet_title"),
                     @"description" : _url,
                     @"img" : @"ic_custom_wikipedia"
                     }];
    
    [arr addObject:@{
        @"type" : kTitleIconRoundCell,
        @"title" : OALocalizedString(@"download_wiki_data"),
        @"img" : @"ic_custom_download",
        @"round_bottom" : @(NO),
        @"round_top" : @(YES)
    }];
    
    [arr addObject:@{
        @"type" : kTitleIconRoundCell,
        @"title" : OALocalizedString(@"open_wiki_online"),
        @"img" : @"ic_custom_online",
        @"round_bottom" : @(YES),
        @"round_top" : @(NO)
    }];
    
    _data = [NSArray arrayWithArray:arr];
}

- (void) initData
{
}

- (void) onCloseButtonPressed:(id)sender
{
    [vwController dismiss];
}

- (CGFloat) heightForRow:(NSIndexPath *)indexPath tableView:(UITableView *)tableView
{
    NSDictionary *item = [self getItem:indexPath];
    
    if ([item[@"type"] isEqualToString:@"OABottomSheetHeaderDescrButtonCell"])
    {
        return UITableViewAutomaticDimension;
    }
    else if ([item[@"type"] isEqualToString:kTitleIconRoundCell])
    {
        return [OATitleIconRoundCell getHeight:item[@"title"] cellWidth:tableView.bounds.size.width];
    }
    return 44.0;
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
    
    if ([item[@"type"] isEqualToString:@"OABottomSheetHeaderDescrButtonCell"])
    {
        static NSString* const identifierCell = @"OABottomSheetHeaderDescrButtonCell";
        OABottomSheetHeaderDescrButtonCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
            cell = (OABottomSheetHeaderDescrButtonCell *)[nib objectAtIndex:0];
            cell.backgroundColor = UIColor.clearColor;
        }
        if (cell)
        {
            cell.titleView.text = item[@"title"];
            cell.descrLabel.text = item[@"description"];
            cell.iconView.image = [UIImage imageNamed:item[@"img"]];
            [cell.closeButton removeTarget:NULL action:NULL forControlEvents:UIControlEventAllEvents];
            [cell.closeButton addTarget:self action:@selector(onCloseButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:kTitleIconRoundCell])
    {
        static NSString* const identifierCell = kTitleIconRoundCell;
        OATitleIconRoundCell* cell = nil;
        
        cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:kTitleIconRoundCell owner:self options:nil];
            cell = (OATitleIconRoundCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            cell.backgroundColor = UIColor.clearColor;
            cell.titleView.text = item[@"title"];
            
            [cell.iconView setImage:[[UIImage imageNamed:item[@"img"]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
            cell.iconColorNormal = UIColorFromRGB(color_primary_purple);
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
    return 16.0;
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section
{
    view.hidden = YES;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self.vwController dismiss];
}

@synthesize vwController;

@end

@interface OAWikiLinkBottomSheetViewController ()

@end

@implementation OAWikiLinkBottomSheetViewController

- (void) setupView
{
    if (!self.screenObj)
        self.screenObj = [[OAWikiLinkBottomSheetScreen alloc] initWithTable:self.tableView viewController:self param:self.customParam];
    
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
