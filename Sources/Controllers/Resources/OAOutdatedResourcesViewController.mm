//
//  OAOutdatedResourcesViewController.mm
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/28/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAOutdatedResourcesViewController.h"

#import <Reachability.h>
#import <UIAlertView+Blocks.h>
#import <FFCircularProgressView.h>
#import <MBProgressHUD.h>
#import <FormatterKit/TTTArrayFormatter.h>

#import "OsmAndApp.h"
#import "FFCircularProgressView+isSpinning.h"
#include "Localization.h"

@interface OAOutdatedResourcesViewController () <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation OAOutdatedResourcesViewController
{
    OsmAndAppInstance _app;

    NSObject* _dataLock;

    QHash< QString, std::shared_ptr<const OsmAnd::ResourcesManager::LocalResource> > _outdatedResources;

    NSMutableArray* _resourcesItems;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        _app = [OsmAndApp instance];

        _dataLock = [[NSObject alloc] init];
    }
    return self;
}

- (void)setupWithRegion:(OAWorldRegion*)region
       andOutdatedItems:(NSArray*)items
{
    self.region = region;
    _resourcesItems = [NSMutableArray arrayWithArray:items];
}

- (void)viewDidLoad
{
    UIBarButtonItem* refreshAllBarButton = [[UIBarButtonItem alloc] initWithTitle:OALocalizedString(@"Update all")
                                                                            style:UIBarButtonItemStylePlain
                                                                           target:self
                                                                           action:@selector(onUpdateAllBarButtonClicked)];
    self.navigationItem.rightBarButtonItem = refreshAllBarButton;
}

- (void)updateContent
{
    [self obtainDataAndItems];
    [self refreshContent];
}

- (void)refreshContent
{
    @synchronized(_dataLock)
    {
        [self.tableView reloadData];
    }
}

- (void)obtainDataAndItems
{
    @synchronized(_dataLock)
    {
        [self prepareData];
        [self collectResourcesDataAndItems];
    }
}

- (void)prepareData
{
    // Obtain all resources separately

    // IOS-199
    if (_app.debugSettings.setAllResourcesAsOutdated)
        _outdatedResources = _app.resourcesManager->getLocalResources();
    else
        _outdatedResources = _app.resourcesManager->getOutdatedInstalledResources();
}

- (void)collectResourcesDataAndItems
{
    [_resourcesItems removeAllObjects];
    for (const auto& resource : _outdatedResources)
    {
        OAWorldRegion* match = [OAResourcesBaseViewController findRegionOrAnySubregionOf:self.region
                                                                    thatContainsResource:resource->id];
        if (!match)
            continue;

        OutdatedResourceItem* item = [[OutdatedResourceItem alloc] init];
        item.resourceId = resource->id;
        item.title = [self titleOfResource:resource
                                  inRegion:match
                            withRegionName:YES];
        item.resource = resource;
        item.downloadTask = [self getDownloadTaskFor:resource->id.toNSString()];
        item.worldRegion = match;

        if (item.title == nil)
            continue;

        [_resourcesItems addObject:item];
    }
    [_resourcesItems sortUsingComparator:self.resourceItemsComparator];
}

- (void)offerDownloadAndUpdateMultiple:(NSArray*)items
{
    uint64_t totalDownloadSize = 0;
    uint64_t totalSpaceNeeded = 0;
    for (OutdatedResourceItem* item in items)
    {
        const auto resourceInRepository = _app.resourcesManager->getResourceInRepository(item.resourceId);

        totalDownloadSize += resourceInRepository->packageSize;
        totalSpaceNeeded += resourceInRepository->packageSize + resourceInRepository->size;
    }

    if (_app.freeSpaceAvailableOnDevice < totalSpaceNeeded)
    {
        NSString* stringifiedSize = [NSByteCountFormatter stringFromByteCount:totalSpaceNeeded
                                                                   countStyle:NSByteCountFormatterCountStyleFile];

        [[[UIAlertView alloc] initWithTitle:nil
                                    message:OALocalizedString(@"Not enough space to install %1$d updates. %2$@ is needed. Please free up some space.",
                                                              [items count],
                                                              stringifiedSize)
                           cancelButtonItem:[RIButtonItem itemWithLabel:OALocalizedString(@"OK")]
                           otherButtonItems:nil] show];
        return;
    }

    NSString* stringifiedSize = [NSByteCountFormatter stringFromByteCount:totalDownloadSize
                                                               countStyle:NSByteCountFormatterCountStyleFile];

    NSString* message = nil;
    if ([Reachability reachabilityForInternetConnection].currentReachabilityStatus == ReachableViaWWAN)
    {
        message = OALocalizedString(@"%1$d updates are available. %2$@ will be downloaded over cellular network. This may incur high charges. Proceed?",
                                    [items count],
                                    stringifiedSize);
    }
    else
    {
        message = OALocalizedString(@"%1$d updates are available. %2$@ will be downloaded over WiFi network. Proceed?",
                                    [items count],
                                    stringifiedSize);
    }

    [[[UIAlertView alloc] initWithTitle:nil
                                message:message
                       cancelButtonItem:[RIButtonItem itemWithLabel:OALocalizedString(@"Cancel")]
                       otherButtonItems:[RIButtonItem itemWithLabel:OALocalizedString(@"Update all")
                                                             action:^{
                                                                 for (OutdatedResourceItem* item in items)
                                                                 {
                                                                     const auto resourceInRepository = _app.resourcesManager->getResourceInRepository(item.resourceId);
                                                                     
                                                                     [self startDownloadOf:resourceInRepository];
                                                                 }
                                                             }], nil] show];
}

- (void)onUpdateAllBarButtonClicked
{
    NSMutableArray* resourcesToUpdate = [NSMutableArray array];
    @synchronized(_dataLock)
    {
        for (OutdatedResourceItem* item in _resourcesItems)
        {
            if (item.downloadTask != nil)
                continue;

            [resourcesToUpdate addObject:item];
        }
    }
    if ([resourcesToUpdate count] == 0)
        return;

    if ([resourcesToUpdate count] == 1)
        [self offerDownloadAndUpdateOf:[resourcesToUpdate firstObject]];
    else
        [self offerDownloadAndUpdateMultiple:resourcesToUpdate];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_resourcesItems count];
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return nil;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* const outdatedResourceCell = @"outdatedResourceCell";
    static NSString* const downloadingResourceCell = @"downloadingResourceCell";

    NSString* cellTypeId = nil;
    NSString* title = nil;
    NSString* subtitle = nil;

    ResourceItem* item = (ResourceItem*)[_resourcesItems objectAtIndex:indexPath.row];
    if (item.downloadTask != nil)
        cellTypeId = downloadingResourceCell;
    else if ([item isKindOfClass:[OutdatedResourceItem class]])
        cellTypeId = outdatedResourceCell;

    title = item.title;
    if (item.worldRegion.superregion != nil)
        subtitle = item.worldRegion.superregion.name;

    // Obtain reusable cell or create one
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellTypeId];
    if (cell == nil)
    {
        if ([cellTypeId isEqualToString:outdatedResourceCell])
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                          reuseIdentifier:cellTypeId];
            UIImage* iconImage = [UIImage imageNamed:@"menu_item_update_icon.png"];
            cell.accessoryView = [[UIImageView alloc] initWithImage:[iconImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        }
        else if ([cellTypeId isEqualToString:downloadingResourceCell])
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                          reuseIdentifier:cellTypeId];

            FFCircularProgressView* progressView = [[FFCircularProgressView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 25.0f, 25.0f)];
            progressView.iconView = [[UIView alloc] init];

            cell.accessoryView = progressView;
        }
    }

    // Try to allocate cell from own table, since it may be configured there
    if (cell == nil)
        cell = [self.tableView dequeueReusableCellWithIdentifier:cellTypeId];

    // Fill cell content
    cell.textLabel.text = title;
    if (cell.detailTextLabel != nil)
        cell.detailTextLabel.text = subtitle;
    if ([cellTypeId isEqualToString:downloadingResourceCell])
    {
        FFCircularProgressView* progressView = (FFCircularProgressView*)cell.accessoryView;

        float progressCompleted = item.downloadTask.progressCompleted;
        if (progressCompleted >= 0.0f && item.downloadTask.state == OADownloadTaskStateRunning)
        {
            [progressView stopSpinProgressBackgroundLayer];
            progressView.progress = progressCompleted;
        }
        else if (item.downloadTask.state == OADownloadTaskStateFinished)
        {
            [progressView stopSpinProgressBackgroundLayer];
            progressView.progress = 1.0f;
        }
        else
        {
            if (!progressView.isSpinning)
                [progressView startSpinProgressBackgroundLayer];
        }
    }

    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.1f;
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    id item = [_resourcesItems objectAtIndex:indexPath.row];

    if (item == nil)
        return;

    [self onItemClicked:item];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id item = [_resourcesItems objectAtIndex:indexPath.row];

    if (item != nil)
        [self onItemClicked:item];

    [tableView deselectRowAtIndexPath:indexPath animated:true];
}

#pragma mark -

@end
