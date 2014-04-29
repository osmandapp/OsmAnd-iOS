//
//  OADownloadsViewController.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 4/1/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OADownloadsViewController.h"

#import "OsmAndApp.h"
#import "OATableViewCellWithButton.h"
#include "Localization.h"

#define Item_Download OADownloadsViewController__Item_Download
@interface Item_Download : NSObject
@property NSString* caption;
@property std::shared_ptr<const OsmAnd::ResourcesManager::ResourceInRepository> resourceInRepository;
@end
@implementation Item_Download
@end

@interface OADownloadsViewController ()

@end

@implementation OADownloadsViewController
{
    OsmAndAppInstance _app;

    BOOL _updatingRepository;

    NSMutableArray* _mainWorldRegions;
    NSMutableArray* _worldwideDownloadItems;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self ctor];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self ctor];
    }
    return self;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        [self ctor];
    }
    return self;
}

- (void)ctor
{
    _app = [OsmAndApp instance];

    _updatingRepository = NO;

    _mainWorldRegions = [[NSMutableArray alloc] init];
    _worldwideDownloadItems = [[NSMutableArray alloc] init];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self updateRepository:YES];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)obtainMainWorldRegions
{
    [_mainWorldRegions removeAllObjects];
    [_mainWorldRegions addObjectsFromArray:_app.worldRegion.subregions];
    [_mainWorldRegions sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        OAWorldRegion* worldRegion1 = obj1;
        OAWorldRegion* worldRegion2 = obj2;

        NSString* name1 = worldRegion1.localizedName;
        if (name1 == nil)
            name1 = worldRegion1.nativeName;

        NSString* name2 = worldRegion2.localizedName;
        if (name2 == nil)
            name2 = worldRegion2.nativeName;

        return [name1 localizedCaseInsensitiveCompare:name2];
    }];
}

- (void)obtainWorldwideDownloads
{
    [_worldwideDownloadItems removeAllObjects];
    const auto& resourcesInRepository = _app.resourcesManager->getResourcesInRepository();
    for(const auto& resourceInRepository : resourcesInRepository)
    {
        const auto& resourceId = resourceInRepository->id;
        if (!resourceId.startsWith(QLatin1String("world_")))
            continue;

        Item_Download* downloadItem = [[Item_Download alloc] init];
        downloadItem.resourceInRepository = resourceInRepository;
        if (resourceId == QLatin1String("world_basemap.map.obf"))
        {
            downloadItem.caption = OALocalizedString(@"Detailed overview map");
        }
        else
        {
            downloadItem.caption = resourceId.toNSString();
        }

        [_worldwideDownloadItems addObject:downloadItem];
    }
    [_worldwideDownloadItems sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        Item_Download* downloadItem1 = obj1;
        Item_Download* downloadItem2 = obj2;

        return [downloadItem1.caption localizedCaseInsensitiveCompare:downloadItem2.caption];
    }];
}

- (void)updateRepository:(BOOL)animated
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        _updatingRepository = YES;
        if (animated)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        }

        bool ok = _app.resourcesManager->updateRepository();

        if (ok)
        {
            [self obtainMainWorldRegions];
            [self obtainWorldwideDownloads];
        }

        _updatingRepository = NO;
        if (animated)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        }
    });
}

#define kMainWorldRegionsSection 0
#define kWorldwideDownloadItemsSection 1

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (_updatingRepository)
        return 1; /* unnamed section */

    return 2 /* 'By regions', 'Worldwide' */;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (_updatingRepository)
        return 1; /* activity indicator row */

    switch (section)
    {
        case kMainWorldRegionsSection:
            return [_mainWorldRegions count];

        case kWorldwideDownloadItemsSection:
            return [_worldwideDownloadItems count];

        default:
            return 0;
    }
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (_updatingRepository)
        return nil; /* unnamed section */

    switch (section)
    {
        case kMainWorldRegionsSection:
            return OALocalizedString(@"By regions");

        case kWorldwideDownloadItemsSection:
            return OALocalizedString(@"Worldwide");

        default:
            return nil;
    }
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* const submenuCell = @"submenuCell";
    static NSString* const downloadCell = @"downloadCell";
    static NSString* const activityIndicatorCell = @"activityIndicatorCell";

    NSString* cellTypeId = nil;
    NSString* caption = nil;
    if (_updatingRepository)
    {
        cellTypeId = activityIndicatorCell;
    }
    else
    {
        if (indexPath.section == kMainWorldRegionsSection)
        {
            OAWorldRegion* worldRegion = [_mainWorldRegions objectAtIndex:indexPath.row];

            cellTypeId = submenuCell;
            caption = worldRegion.localizedName;
            if (caption == nil)
                caption = worldRegion.nativeName;
        }
        else if (indexPath.section == kWorldwideDownloadItemsSection)
        {
            Item_Download* downloadItem = [_worldwideDownloadItems objectAtIndex:indexPath.row];

            cellTypeId = downloadCell;
            caption = downloadItem.caption;
        }
    }

    // Obtain reusable cell or create one
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellTypeId];
    if (cell == nil)
    {
        if ([cellTypeId isEqualToString:downloadCell])
        {
            cell = [[OATableViewCellWithButton alloc] initWithStyle:UITableViewCellStyleDefault
                                                      andButtonType:UIButtonTypeCustom
                                                    reuseIdentifier:cellTypeId];
            OATableViewCellWithButton* cellWithButton = (OATableViewCellWithButton*)cell;
            UIImage* startDownloadIcon = [UIImage imageNamed:@"menu_item_start_download_icon.png"];
            [cellWithButton.buttonView setImage:startDownloadIcon
                                       forState:UIControlStateNormal];
            UIImage* bg = [UIImage imageNamed:@"HUD_button_bg.png"];
            [cellWithButton.buttonView setBackgroundImage:bg forState:UIControlStateNormal];
            cellWithButton.buttonView.frame = CGRectMake(0.0f, 0.0f,
                                                         bg.size.width, bg.size.height);
        }
        else
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellTypeId];
    }

    // Deal with cell content
    if([cellTypeId isEqualToString:activityIndicatorCell])
    {
        UIActivityIndicatorView* activityIndicatorView = [cell.contentView.subviews firstObject];
        [activityIndicatorView startAnimating];
    }
    else
    {
        // Fill cell content
        cell.textLabel.text = caption;
    }

    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"i'm clicked");
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    /*NSMutableArray* collection = (indexPath.section == kOfflineSourcesSection) ? _offlineMapSourcesIds : _onlineMapSourcesIds;
     NSUUID* newActiveMapSourceId = [collection objectAtIndex:indexPath.row];

     _app.data.activeMapSourceId = newActiveMapSourceId;

     // For iPhone/iPod, since this menu wasn't opened in popover, return
     if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)
     [self.navigationController popViewControllerAnimated:YES];*/
}

#pragma mark -

@end
