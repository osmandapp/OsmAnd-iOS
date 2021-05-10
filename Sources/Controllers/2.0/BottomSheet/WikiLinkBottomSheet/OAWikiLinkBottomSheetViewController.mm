//
//  OAWikiLinkBottomSheetViewController.m
//  OsmAnd
//
//  Created by Paul on 4/18/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAWikiLinkBottomSheetViewController.h"
#import "Localization.h"
#import "OABottomSheetHeaderDescrButtonCell.h"
#import "OAUtilities.h"
#import "OAColors.h"
#import "OASizes.h"
#import "OAAppSettings.h"
#import "OATitleIconRoundCell.h"
#import "OADestinationItemsListViewController.h"
#import "OAWorldRegion.h"
#import "OAWikiArticleHelper.h"
#import "OAResourcesUIHelper.h"
#import "OARootViewController.h"

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
    NSDictionary <NSNumber *, NSArray *> *_data;
    NSString *_url;
    NSString *_regionName;
    
    OAWorldRegion *_worldRegion;
    OARepositoryResourceItem *_resourceItem;
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
    _resourceItem = viewController.localItem;
    
    if (viewController.localItem)
        _regionName = [viewController.localItem title];
    else
        _regionName = OALocalizedString(@"map_an_region");
    
    vwController = viewController;
    tblView = tableView;
    
    [self initData];
}

- (void) setupView
{
    tblView.separatorColor = UIColorFromRGB(color_tint_gray);
    [[self.vwController.buttonsView viewWithTag:kButtonsDividerTag] removeFromSuperview];
    NSMutableDictionary<NSNumber *, NSArray *> *dict = [NSMutableDictionary new];
    [dict setObject:@[@{
                         @"type" : [OABottomSheetHeaderDescrButtonCell getCellIdentifier],
                         @"title" : OALocalizedString(@"wiki_sheet_title"),
                         @"description" : _url,
                         @"img" : @"ic_custom_wikipedia"
    }] forKey:@(0)];
    
    [dict setObject:@[@{
                          @"type" : kTitleIconRoundCell,
                          @"title" : [NSString stringWithFormat:OALocalizedString(@"download_wiki_data"), _regionName],
                          @"img" : @"ic_custom_download",
                          @"round_bottom" : @(NO),
                          @"round_top" : @(YES),
                          @"key" : @"download_wiki_map"
                      },
                      @{
                          @"type" : kTitleIconRoundCell,
                          @"title" : OALocalizedString(@"open_wiki_online"),
                          @"img" : @"ic_custom_online",
                          @"round_bottom" : @(YES),
                          @"round_top" : @(NO),
                          @"key" : @"open_in_browser"
                      }
    ] forKey:@(1)];
    
    _data = [NSDictionary dictionaryWithDictionary:dict];
}

- (void) initData
{
}

- (void) onCloseButtonPressed:(id)sender
{
    [vwController dismiss];
}

#pragma mark - UITableViewDataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _data[@(section)].count;
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    
    if ([item[@"type"] isEqualToString:[OABottomSheetHeaderDescrButtonCell getCellIdentifier]])
    {
        static NSString* const identifierCell = [OABottomSheetHeaderDescrButtonCell getCellIdentifier];
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
    return _data[@(indexPath.section)][indexPath.row];
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
    NSDictionary *item = [self getItem:indexPath];
    if ([item[@"key"] isEqualToString:@"download_wiki_map"])
    {
        if (item)
        {
            OsmAndAppInstance app = [OsmAndApp instance];
            if ([app.downloadsManager downloadTasksWithKey:[@"resource:" stringByAppendingString:_resourceItem.resourceId.toNSString()]].count == 0)
            {
                NSString *resourceName = [OAResourcesUIHelper titleOfResource:_resourceItem.resource
                                                                     inRegion:_resourceItem.worldRegion
                                                               withRegionName:YES
                                                             withResourceType:YES];
                        
                [OAResourcesUIHelper startBackgroundDownloadOf:_resourceItem.resource resourceName:resourceName];
            }
        }
        else
        {
                OASuperViewController* resourcesViewController = [[UIStoryboard storyboardWithName:@"Resources" bundle:nil] instantiateInitialViewController];
                [[OARootViewController instance].navigationController pushViewController:resourcesViewController animated:YES];
        }
    }
    else if ([item[@"key"] isEqualToString:@"open_in_browser"])
    {
        [OAUtilities callUrl:_url];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self.vwController dismiss];
}

@synthesize vwController;

@end

@interface OAWikiLinkBottomSheetViewController ()

@end

@implementation OAWikiLinkBottomSheetViewController

- (instancetype) initWithUrl:(NSString *)url localItem:(OARepositoryResourceItem *)localItem
{
    self = [super initWithParam:url];
    if (self)
    {
        _localItem = localItem;
    }
    return self;
}

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
