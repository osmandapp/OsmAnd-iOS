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

@interface OADownloadsViewController ()

@end

@implementation OADownloadsViewController
{
    OsmAndAppInstance _app;

    NSMutableArray* _mainWorldRegions;
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

    _mainWorldRegions = [[NSMutableArray alloc] init];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Obtain main world regions
    [self obtainMainWorldRegions];
    
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

#define kRegionsSection 0
#define kWorldwideSection 1
#define kMiscellaneousSection 2

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3 /* 'Regions', 'Worldwide', 'Miscellaneous' */;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section)
    {
        case kRegionsSection:
            return [_mainWorldRegions count];

        case kWorldwideSection:
            return 1;

        case kMiscellaneousSection:
            return 1;

        default:
            return 0;
    }
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section)
    {
        case kRegionsSection:
            return OALocalizedString(@"Regions");

        case kWorldwideSection:
            return OALocalizedString(@"Worldwide");

        case kMiscellaneousSection:
            return OALocalizedString(@"Miscellaneous");

        default:
            return nil;
    }
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* const submenuCell = @"submenuCell";
    static NSString* const downloadCell = @"downloadCell";

    NSString* cellTypeId = nil;
    NSString* caption = nil;
    if (indexPath.section == kRegionsSection)
    {
        OAWorldRegion* worldRegion = [_mainWorldRegions objectAtIndex:indexPath.row];

        cellTypeId = submenuCell;
        caption = worldRegion.localizedName;
        if (caption == nil)
            caption = worldRegion.nativeName;
    }
    else if (indexPath.section == kWorldwideSection)
    {
        cellTypeId = downloadCell;
        caption = OALocalizedString(@"Detailed overview map");
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

    // Fill cell content
    cell.textLabel.text = caption;

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
