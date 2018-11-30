//
//  OAOsmAndLiveViewController.mm
//  OsmAnd
//
//  Created by Paul on 11/29/18.
//  Copyright (c) 2018 OsmAnd. All rights reserved.
//

#import "OAOsmAndLiveViewController.h"

#import "OAResourcesBaseViewController.h"
#import "OsmAndApp.h"
#include "Localization.h"
#import "OALocalResourceInfoCell.h"
#import "OAPurchasesViewController.h"
#import "OAPluginsViewController.h"
#import "OAMenuSimpleCellNoIcon.h"
#import "OAUtilities.h"
#import "OAMapCreatorHelper.h"
#import "OASizes.h"

#define kMapAvailableType @"availableMapType"
#define kMapEnabledType @"enabledMapType"

#define kLiveUpdatesOnPrefix @"live_updates_on_"

typedef OsmAnd::ResourcesManager::LocalResource OsmAndLocalResource;

@interface OAOsmAndLiveViewController ()<UITableViewDelegate, UITableViewDataSource> {
    
    NSMutableArray *_enabledData;
    NSMutableArray *_availableData;
    
    NSArray *_localIndexes;
    
    NSDateFormatter *formatter;
    
}

@end

@implementation OAOsmAndLiveViewController

static const NSInteger enabledIndex = 0;
static const NSInteger availableIndex = 1;
static const NSInteger sectionCount = 2;

- (void) setLocalResources:(NSArray *)localResources;
{
    _localIndexes = localResources;
}

-(void)applyLocalization
{
    _titleView.text = OALocalizedString(@"osmand_live_title");
    [_backButton setTitle:OALocalizedString(@"shared_string_back") forState:UIControlStateNormal];
}

-(void)viewDidLoad
{
    [super viewDidLoad];
}

-(void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    [self setupView];
}

-(UIView *) getTopView
{
    return _navBarView;
}

-(UIView *) getMiddleView
{
    return _tableView;
}

-(CGFloat) getToolBarHeight
{
    return defaultToolBarHeight;
}

- (void) setupView
{
    [self applySafeAreaMargins];
    NSMutableArray *liveEnabled = [NSMutableArray array];
    NSMutableArray *liveDisabled = [NSMutableArray array];
    for (LocalResourceItem *item : _localIndexes)
    {
        NSString *itemId = item.resourceId.toNSString();
        NSString *liveKey = [kLiveUpdatesOnPrefix stringByAppendingString:itemId];
        BOOL isLive = [[NSUserDefaults standardUserDefaults] objectForKey:liveKey] ? [[NSUserDefaults standardUserDefaults]
                                                                                      boolForKey:liveKey] : NO;
        NSDictionary *listItem = @{
                                   @"id" : itemId,
                                   @"title" : [NSString stringWithFormat:@"%@ %@", [OAResourcesBaseViewController getCountryName:item], item.title],
                                   @"description" : @"test",
                                   @"type" : isLive ? kMapEnabledType : kMapAvailableType,
                                   };

        if (isLive)
            [liveEnabled addObject:listItem];
        else
            [liveDisabled addObject:listItem];
    }
    _enabledData = [NSMutableArray arrayWithArray:liveEnabled];
    _availableData = [NSMutableArray arrayWithArray:liveDisabled];
    [self.tableView reloadData];
}

#pragma mark - UITableViewDataSource

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self heightForRow:indexPath tableView:tableView];
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self heightForRow:indexPath tableView:tableView];
}

- (CGFloat) heightForRow:(NSIndexPath *)indexPath tableView:(UITableView *)tableView
{
    NSDictionary *item = [self getItem:indexPath];
    NSString *value = item[@"description"];
    NSString *text = item[@"title"];
    
    return [OAMenuSimpleCellNoIcon getHeight:text desc:value cellWidth:tableView.bounds.size.width];
}

- (NSDictionary *) getItem:(NSIndexPath *)indexPath
{
    long section = indexPath.section;
    switch (section) {
        case enabledIndex:
            return _enabledData[indexPath.row];
        case availableIndex:
            return _availableData[indexPath.row];
        default:
            return nil;
    }
}

-(IBAction)backButtonClicked:(id)sender;
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return sectionCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == enabledIndex)
        return _enabledData.count;
    else if (section == availableIndex)
        return _availableData.count;
    return 0;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return section == enabledIndex ? OALocalizedStringUp(@"osmand_live_updates") : OALocalizedStringUp(@"osmand_live_available_maps");
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    
    OAMenuSimpleCellNoIcon *cell = (OAMenuSimpleCellNoIcon *)[tableView dequeueReusableCellWithIdentifier:@"OAMenuSimpleCellNoIcon"];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAMenuSimpleCellNoIcon" owner:self options:nil];
        cell = (OAMenuSimpleCellNoIcon *)[nib objectAtIndex:0];
    }
    
    if (cell)
    {
        cell.descriptionView.hidden = item[@"description"] == nil || [item[@"description"] length] == 0 ? YES : NO;
        cell.contentView.backgroundColor = [UIColor whiteColor];
        [cell.textView setTextColor:[UIColor blackColor]];
        [cell.textView setText:item[@"title"]];
        [cell.descriptionView setText:item[@"description"]];
    }
    return cell;
}

#pragma mark - UITableViewDelegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    NSString *prefKey = [kLiveUpdatesOnPrefix stringByAppendingString:item[@"id"]];
    NSString *type = item[@"type"];
    if ([type isEqualToString:kMapAvailableType])
    {
        [_availableData removeObjectAtIndex:indexPath.row];
        NSDictionary *newItem =  @{
                                   @"id" : item[@"id"],
                                   @"title" : item[@"title"],
                                   @"description" : item[@"description"],
                                   @"type" : kMapEnabledType,
                                   };
        [_enabledData addObject:newItem];
        [[NSUserDefaults standardUserDefaults] setBool:YES
                                                forKey:prefKey];
        
        [tableView reloadData];
    }
    else
    {
        [_enabledData removeObjectAtIndex:indexPath.row];
        NSDictionary *newItem =  @{
                                  @"id" : item[@"id"],
                                  @"title" : item[@"title"],
                                  @"description" : item[@"description"],
                                  @"type" : kMapAvailableType,
                                  };
        [_availableData addObject:newItem];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:prefKey];
        [tableView reloadData];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:true];
}

@end
