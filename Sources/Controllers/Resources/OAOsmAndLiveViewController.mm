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
#import "OAResourcesBaseViewController.h"

#include <OsmAndCore/IncrementalChangesManager.h>

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
{
    OsmAndAppInstance _app;
}

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
    [_segmentControl setTitle:OALocalizedString(@"res_updates") forSegmentAtIndex:0];
    [_segmentControl setTitle:OALocalizedString(@"osmand_live_reports") forSegmentAtIndex:1];
}

-(void)viewDidLoad
{
    _app = [OsmAndApp instance];
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

-(CGFloat) getNavBarHeight
{
    return osmAndLiveNavBarHeight;
}

- (NSString *) getDescription:(QString) resourceId {
    uint64_t timestamp = _app.resourcesManager->getResourceTimestamp(resourceId);
    if (timestamp == -1)
        return @"";
    
    // Convert timestamp to seconds
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:(timestamp / 1000)];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"MMM dd, yyyy HH:mm"];
    NSString *description = [NSString stringWithFormat:OALocalizedString(@"osmand_live_last_changed"), [formatter stringFromDate:date]];
    return description;
}

- (void) setupView
{
    [self applySafeAreaMargins];
    [self adjustViews];
    NSMutableArray *liveEnabled = [NSMutableArray array];
    NSMutableArray *liveDisabled = [NSMutableArray array];
    for (LocalResourceItem *item : _localIndexes)
    {
        NSString *itemId = item.resourceId.toNSString();
        NSString *liveKey = [kLiveUpdatesOnPrefix stringByAppendingString:itemId];
        BOOL isLive = [[NSUserDefaults standardUserDefaults] objectForKey:liveKey] ? [[NSUserDefaults standardUserDefaults]
                                                                                      boolForKey:liveKey] : NO;
        NSString *countryName = [OAResourcesBaseViewController getCountryName:item];
        NSString *title = countryName == nil ? item.title : [NSString stringWithFormat:@"%@ %@", countryName, item.title];
        // Convert to seconds
        NSString * description = [self getDescription:item.resourceId];
        NSDictionary *listItem = @{
                                   @"id" : itemId,
                                   @"title" : title,
                                   @"description" : description,
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

- (void) adjustViews
{
    CGRect buttonFrame = _backButton.frame;
    CGRect titleFrame = _titleView.frame;
    CGFloat statusBarHeight = [OAUtilities getStatusBarHeight];
    buttonFrame.origin.y = statusBarHeight;
    titleFrame.origin.y = statusBarHeight;
    _backButton.frame = buttonFrame;
    _titleView.frame = titleFrame;
}

-(void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self applySafeAreaMargins];
        [self adjustViews];
    } completion:nil];
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
    const QString regionName = QString::fromNSString(item[@"id"]).remove(QStringLiteral(".map.obf"));
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
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            const auto& lst = _app.resourcesManager->changesManager->
                                    getUpdatesByMonth(regionName);
            for (const auto& res : lst->getItemsForUpdate())
            {
                [OAResourcesBaseViewController startBackgroundDownloadOf:res];
            }
        });
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
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            _app.resourcesManager->changesManager->deleteUpdates(regionName);
        });
        [tableView reloadData];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:true];
}

@end
