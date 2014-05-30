//
//  OAShowDownloadsViewController.mm
//  OsmAnd
//
//  Created by Feschenko Fedor on 5/25/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAShowDownloadsViewController.h"

#import <UIAlertView+Blocks.h>
#import <FFCircularProgressView.h>

#import "OsmAndApp.h"
#import "OAAutoObserverProxy.h"
#import "OATableViewCellWithButton.h"
#import "OATableViewCellWithClickableAccessoryView.h"
#import "OALocalResourceInformationViewController.h"
#import "UITableViewCell+getTableView.h"
#include "Localization.h"

#define _(name) OAShowDownloadsViewController__##name
#define ctor _(ctor)

#define DownloadedItem _(DownloadedItem)
@interface DownloadedItem : NSObject
@property NSString *caption;
@property std::shared_ptr<const OsmAnd::ResourcesManager::ResourceInRepository> resourceInRepository;
@property id<OADownloadTask> downloadTask;
@end
@implementation DownloadedItem
@end

typedef OsmAnd::ResourcesManager::ResourceType OsmAndResourceType;

@interface OAShowDownloadsViewController ()

@property OAWorldRegion *worldRegion;

@end

@implementation OAShowDownloadsViewController
{
    OsmAndAppInstance _app;
    
    NSMutableArray* _downloadItems;
    
    OAAutoObserverProxy* _localResourcesChangedObserver;
    OAAutoObserverProxy* _downloadTaskProgressObserver;
    OAAutoObserverProxy* _downloadTaskCompletedObserver;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self ctor];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self ctor];
    }
    return self;
}

- (void)ctor
{
    _app = [OsmAndApp instance];
    
    _worldRegion = nil;
    
    _downloadItems = [[NSMutableArray alloc] init];
    
    _downloadTaskProgressObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                              withHandler:@selector(onDownloadTaskProgressChanged:withKey:andValue:)];
    _downloadTaskCompletedObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                               withHandler:@selector(onDownloadTaskFinished:withKey:andValue:)];
    _localResourcesChangedObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                               withHandler:@selector(onLocalResourcesChanged:withKey:)
                                                                andObserve:_app.localResourcesChangedObservable];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _tableView.delegate = self;
    
    _tableView.dataSource = self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Deselect previously selected rows
    for (NSIndexPath *selectedIndexPath in [_tableView indexPathsForSelectedRows])
    {
        [_tableView deselectRowAtIndexPath:selectedIndexPath
                                  animated:animated];
    }
    
    [self reloadList];
}

- (void)reloadList
{
    [self loadDynamicContent];
    [_tableView reloadData];
}

- (void)loadDynamicContent
{
    [_downloadItems removeAllObjects];
    NSArray *keysOfDownloadTasks = [_app.downloadsManager keysOfDownloadTasks];
    
    for (NSString *resourceId : keysOfDownloadTasks)
    {
        id<OADownloadTask> downloadTask = [[_app.downloadsManager downloadTasksWithKey:resourceId] firstObject];
        if (downloadTask != nil && (downloadTask.state != OADownloadTaskStateFinished))
        {
            DownloadedItem *downloadedItem = [[DownloadedItem alloc] init];
            downloadedItem.downloadTask = downloadTask;
            
            [_downloadTaskProgressObserver observe:downloadTask.progressCompletedObservable];
            [_downloadTaskCompletedObserver observe:downloadTask.completedObservable];
            
//            downloadedItem.resourceInRepository = resourceId;
            downloadedItem.caption = [self titleOfResourceId:resourceId];
            [_downloadItems addObject:downloadedItem];
        }
        
    }
    [_downloadItems sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        DownloadedItem *item1 = obj1;
        DownloadedItem *item2 = obj2;
        
        return [item1.caption localizedCaseInsensitiveCompare:item2.caption];
    }];
}

- (void)cancelDownloadOf:(DownloadedItem *)item
{
    DownloadedItem *downloadedItem = (DownloadedItem*)item;
    
    [downloadedItem.downloadTask cancel];
    [self reloadList];
}

- (void)onDownloadTaskProgressChanged:(id<OAObservableProtocol>)observer withKey:(id)key andValue:(id)value
{
    id<OADownloadTask> task = key;
    NSNumber *progressCompleted = (NSNumber *)value;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.isViewLoaded)
            return;
        
        NSUInteger downloadItemIndex = [_downloadItems indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
            if (![obj isKindOfClass:[DownloadedItem class]])
                return NO;
            
            DownloadedItem *downloadedItem = (DownloadedItem*)obj;
            if (downloadedItem.downloadTask != task)
                return NO;
            
            *stop = YES;
            return YES;
        }];
        NSIndexPath *itemIndexPath = [NSIndexPath indexPathForRow:downloadItemIndex
                                                        inSection:1];
        UITableViewCell *itemCell = [_tableView cellForRowAtIndexPath:itemIndexPath];
        FFCircularProgressView *progressView = (FFCircularProgressView *)itemCell.accessoryView;
        
        [progressView stopSpinProgressBackgroundLayer];
        progressView.progress = [progressCompleted floatValue];
    });
}

- (void)onDownloadTaskFinished:(id<OAObservableProtocol>)observer withKey:(id)key andValue:(id)value
{
    id<OADownloadTask> task = key;
    NSString *localPath = task.targetPath;
    
    BOOL needsManualRowReload = YES;
    
    if (localPath != nil && task.state == OADownloadTaskStateFinished)
    {
        const auto& filePath = QString::fromNSString(localPath);
        bool ok = false;
        
        // Try to install only in case of successful download
        if (task.error == nil)
        {
            // Install or update given resource
            const auto& resourceId = QString::fromNSString([task.key substringFromIndex:[@"resource:" length]]);
            ok = _app.resourcesManager->updateFromFile(resourceId, filePath);
            if (!ok)
                ok = _app.resourcesManager->installFromRepository(resourceId, filePath);
        }
        
        [[NSFileManager defaultManager] removeItemAtPath:task.targetPath error:nil];
        
        needsManualRowReload = !ok;
    }
    
    if (needsManualRowReload)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!self.isViewLoaded)
                return;
            
            [self reloadList];

        });
    }
}

- (void)onLocalResourcesChanged:(id<OAObservableProtocol>)observer withKey:(id)key
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self reloadList];
    });
}

- (NSString *)titleOfResourceId:(NSString *)resourceId
{
    NSArray *regions = [_app.worldRegion flattenedSubregions];
    
    for (OAWorldRegion *region : regions) {
        if ([region.regionId isEqualToString:[[(NSString *)[[resourceId componentsSeparatedByString:@":"] objectAtIndex:1] componentsSeparatedByString:@"."] objectAtIndex:0]]) {
            return region.name;
        }
    }
    
    return @"";
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_downloadItems count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if ([_downloadItems count] == 0)
        return OALocalizedString(@"There is no current downloads");

    return OALocalizedString(@"Current downloads");
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Obtain reusable cell or create one
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"downloadedItemCell"];
    if (cell == nil)
    {
        FFCircularProgressView *progressView = [[FFCircularProgressView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 25.0f, 25.0f)];
        progressView.iconView = [[UIView alloc] init];
        [progressView startSpinProgressBackgroundLayer];
        cell = [[OATableViewCellWithClickableAccessoryView alloc] initWithStyle:UITableViewCellStyleDefault
                                                         andCustomAccessoryView:progressView
                                                                reuseIdentifier:@"downloadedItemCell"];
    }
    
    DownloadedItem *downloadedItem = (DownloadedItem *)[_downloadItems objectAtIndex:indexPath.row];
    
    // Fill cell content
    cell.textLabel.text = downloadedItem.caption;
    
    FFCircularProgressView *progressView = (FFCircularProgressView*)cell.accessoryView;
    float progressCompleted = downloadedItem.downloadTask.progressCompleted;
    if (progressCompleted >= 0.0f && downloadedItem.downloadTask.state == OADownloadTaskStateRunning)
    {
        [progressView stopSpinProgressBackgroundLayer];
        progressView.progress = progressCompleted;
    }
    else if (downloadedItem.downloadTask.state == OADownloadTaskStateFinished)
    {
        [progressView stopSpinProgressBackgroundLayer];
        progressView.progress = 1.0f;
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    DownloadedItem* item = [_downloadItems objectAtIndex:indexPath.row];
    
    NSString *itemName = nil;
    if (_worldRegion.superregion == nil)
        itemName = [_tableView cellForRowAtIndexPath:indexPath].textLabel.text;
    else
    {
        itemName = [NSString stringWithFormat:OALocalizedString(@"%1$@ (%2$@)"),
                    [_tableView cellForRowAtIndexPath:indexPath].textLabel.text,
                    _worldRegion.name];
    }
    
    if ([item isKindOfClass:[DownloadedItem class]])
    {
        [[[UIAlertView alloc] initWithTitle:nil
                                    message:[NSString stringWithFormat:OALocalizedString(@"You're going to cancel download of %1$@. Are you sure?"), itemName]
                           cancelButtonItem:[RIButtonItem itemWithLabel:OALocalizedString(@"Continue")]
                           otherButtonItems:[RIButtonItem itemWithLabel:OALocalizedString(@"Cancel")
                                                                 action:^{
                                                                     [self cancelDownloadOf:item];
                                                                 }], nil] show];
    }
}

#pragma mark -

@end
