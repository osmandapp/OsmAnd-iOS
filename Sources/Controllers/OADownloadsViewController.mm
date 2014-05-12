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

@interface OADownloadsViewController () <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *updateActivityIndicator;

@end

@implementation OADownloadsViewController
{
    OsmAndAppInstance _app;

    BOOL _isUpdatingRepository;

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

- (void)ctor
{
    _app = [OsmAndApp instance];

    _isUpdatingRepository = NO;

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
        _isUpdatingRepository = YES;
        if (animated)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
                [self.updateActivityIndicator startAnimating];
            });
        }

        bool ok = _app.resourcesManager->updateRepository();

        if (ok)
        {
            [self obtainMainWorldRegions];
            [self obtainWorldwideDownloads];
        }

        _isUpdatingRepository = NO;
        if (animated)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.updateActivityIndicator stopAnimating];
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
    if (_isUpdatingRepository)
        return 0; // No sections at all

    return 2 /* 'By regions', 'Worldwide' */;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (_isUpdatingRepository)
        return 0; // No rows at all

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
    static NSString* const installableItemCell = @"installableItemCell";
    static NSString* const installedItemCell = @"installedItemCell";

    NSString* cellTypeId = nil;
    NSString* caption = nil;
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

        cellTypeId = installedItemCell;//TODO:depends on state
        caption = downloadItem.caption;
    }

    // Obtain reusable cell or create one
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellTypeId];
    if (cell == nil)
    {
        if ([cellTypeId isEqualToString:installableItemCell])
        {
            cell = [[OATableViewCellWithButton alloc] initWithStyle:UITableViewCellStyleDefault
                                                      andButtonType:UIButtonTypeSystem
                                                    reuseIdentifier:cellTypeId];
            OATableViewCellWithButton* cellWithButton = (OATableViewCellWithButton*)cell;
            UIImage* startDownloadIcon = [UIImage imageNamed:@"menu_item_start_download_icon.png"];
            [cellWithButton.buttonView setImage:startDownloadIcon
                                       forState:UIControlStateNormal];
            cellWithButton.buttonView.frame = CGRectMake(0.0f, 0.0f,
                                                         startDownloadIcon.size.width, startDownloadIcon.size.height);
        }
        else
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                          reuseIdentifier:cellTypeId];
            [cell setNeedsDisplay];
            [cell setNeedsLayout];
        }
    }

    // Fill cell content
    cell.textLabel.text = caption;

    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"i'm clicked");
}

- (NSIndexPath*)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Allow only selection in world regions
    if (indexPath.section != kMainWorldRegionsSection)
        return nil;

    return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section != kMainWorldRegionsSection)
        return;

    // Open region
    OAWorldRegion* worldRegion = [_mainWorldRegions objectAtIndex:indexPath.row];

    NSLog(@"need to open %@", worldRegion.regionId);
}

#pragma mark -

@end
