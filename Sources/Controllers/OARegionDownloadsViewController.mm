//
//  OARegionDownloadsViewController.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 5/12/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OARegionDownloadsViewController.h"

#import "OsmAndApp.h"
#import "OATableViewCellWithButton.h"
#include "Localization.h"

#define Item_Download OARegionDownloadsViewController__Item_Download
@interface Item_Download : NSObject
@property NSString* caption;
@property std::shared_ptr<const OsmAnd::ResourcesManager::ResourceInRepository> resourceInRepository;
@end
@implementation Item_Download
@end

typedef OsmAnd::ResourcesManager::ResourceType OsmAndResourceType;

@interface OARegionDownloadsViewController ()

@end

@implementation OARegionDownloadsViewController
{
    OsmAndAppInstance _app;

    OAWorldRegion* _worldRegion;

    NSInteger _subregionsSection;
    NSInteger _downloadsSection;

    NSMutableArray* _subregions;
    NSMutableArray* _downloadItems;
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

    _worldRegion = nil;

    _subregionsSection = -1;
    _downloadsSection = -1;

    _subregions = [[NSMutableArray alloc] init];
    _downloadItems = [[NSMutableArray alloc] init];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
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

- (void)prepareForRegion:(OAWorldRegion*)region
{
    const auto& resourcesInRepository = _app.resourcesManager->getResourcesInRepository();

    _worldRegion = region;
    NSInteger lastUnallocatedSection = 0;

    // Set the title
    self.title = _worldRegion.localizedName;
    if (self.title == nil)
        self.title = _worldRegion.nativeName;

    // Get subregions sorted by alphabet
    [_subregions removeAllObjects];
    for(OAWorldRegion* subregion in _worldRegion.subregions)
    {
        // If subregions has no own subregions, ensure that it has at least something to download
        if ([subregion.subregions count] == 0)
        {
            const QString subregionId = QString::fromNSString(subregion.regionId);
            BOOL hasAtLeastOneDownload = NO;
            for(const auto& resourceInRepository : resourcesInRepository)
            {
                if (!resourceInRepository->id.startsWith(subregionId))
                    continue;

                hasAtLeastOneDownload = YES;
                break;
            }

            if (!hasAtLeastOneDownload)
                continue;
        }

        [_subregions addObject:subregion];
    }
    [_subregions sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        OAWorldRegion* region1 = obj1;
        NSString* title1 = region1.localizedName != nil ? region1.localizedName : region1.nativeName;
        OAWorldRegion* region2 = obj2;
        NSString* title2 = region2.localizedName != nil ? region2.localizedName : region2.nativeName;

        return [title1 localizedCaseInsensitiveCompare:title2];
    }];
    if ([_subregions count] > 0)
        _subregionsSection = lastUnallocatedSection++;
    else
        _subregionsSection = -1;

    // Get downloads
    const QString regionId = QString::fromNSString(_worldRegion.regionId);
    [_downloadItems removeAllObjects];
    for(const auto& resourceInRepository : resourcesInRepository)
    {
        const auto& resourceId = resourceInRepository->id;
        if (!resourceId.startsWith(regionId))
            continue;

        Item_Download* downloadItem = [[Item_Download alloc] init];
        downloadItem.resourceInRepository = resourceInRepository;
        switch(resourceInRepository->type)
        {
            case OsmAndResourceType::MapRegion:
                if ([_worldRegion.subregions count] > 0)
                    downloadItem.caption = OALocalizedString(@"Map of entire region");
                else
                    downloadItem.caption = OALocalizedString(@"Map of the region");
                break;

            default:
                downloadItem.caption = resourceId.toNSString();
        }

        [_downloadItems addObject:downloadItem];
    }
    [_downloadItems sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        Item_Download* downloadItem1 = obj1;
        Item_Download* downloadItem2 = obj2;

        return [downloadItem1.caption localizedCaseInsensitiveCompare:downloadItem2.caption];
    }];
    if ([_downloadItems count] > 0)
        _downloadsSection = lastUnallocatedSection++;
    else
        _downloadsSection = -1;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger sectionsCount = 0;

    if (_subregionsSection >= 0)
        sectionsCount++;
    if (_downloadsSection >= 0)
        sectionsCount++;

    return sectionsCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == _subregionsSection)
        return [_subregions count];
    if (section == _downloadsSection)
        return [_downloadItems count];

    return 0;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == _subregionsSection)
        return OALocalizedString(@"Regions");
    if (section == _downloadsSection)
        return OALocalizedString(@"Downloads");

    return nil;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* const submenuCell = @"submenuCell";
    static NSString* const installableItemCell = @"installableItemCell";
    static NSString* const installedItemCell = @"installedItemCell";

    NSString* cellTypeId = nil;
    NSString* caption = nil;
    if (indexPath.section == _subregionsSection)
    {
        OAWorldRegion* worldRegion = [_subregions objectAtIndex:indexPath.row];

        cellTypeId = submenuCell;
        caption = worldRegion.localizedName;
        if (caption == nil)
            caption = worldRegion.nativeName;
    }
    else if (indexPath.section == _downloadsSection)
    {
        Item_Download* downloadItem = [_downloadItems objectAtIndex:indexPath.row];

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
    if (indexPath.section != _subregionsSection)
        return nil;

    return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section != _subregionsSection)
        return;

    // Open region that was selected
    OAWorldRegion* worldRegion = [_subregions objectAtIndex:indexPath.row];
    [self performSegueWithIdentifier:@"openSubregion" sender:worldRegion];
}

#pragma mark - Navigation

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    if ([identifier isEqualToString:@"openSubregion"] && [sender isKindOfClass:[OAWorldRegion class]])
        return YES;

    return NO;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"openSubregion"] && [sender isKindOfClass:[OAWorldRegion class]])
    {
        OARegionDownloadsViewController* regionDownloadsViewController = [segue destinationViewController];
        [regionDownloadsViewController prepareForRegion:(OAWorldRegion*)sender];
    }
}

#pragma mark -

@end
