//
//  OADownloadsViewController.mm
//  OsmAnd
//
//  Created by Alexey Pelykh on 4/1/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OADownloadsViewController.h"

#import <Reachability.h>
#import <UIAlertView+Blocks.h>

#import "OsmAndApp.h"
#import "OAOptionsPanelViewController.h"
#import "OARegionDownloadsViewController.h"
#import "UITableViewCell+getTableView.h"
#import "OATableViewCell.h"
#include "Localization.h"

#define _(name) OADownloadsViewController__##name
#define ctor _(ctor)
#define dtor _(dtor)

@interface OADownloadsViewController () <UISearchDisplayDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *updateActivityIndicator;

@end

@implementation OADownloadsViewController
{
    OsmAndAppInstance _app;

    BOOL _isLoadingRepository;

    UIBarButtonItem* _refreshBarButton;

    NSArray* _searchResults;
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

    _isLoadingRepository = NO;

    _refreshBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                                                      target:self
                                                                      action:@selector(onUpdateRepositoryAndRefresh)];

    _searchResults = nil;

    // Link to root world region
    self.worldRegion = _app.worldRegion;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Add a button to refresh repository
    self.navigationItem.rightBarButtonItem = _refreshBarButton;

    // Update repository if needed or load from cache
    if (!_app.resourcesManager->isRepositoryAvailable())
    {
        if ([Reachability reachabilityForInternetConnection].currentReachabilityStatus != NotReachable)
            [self updateRepositoryAndReloadListAnimated];
        else
            [self showNoInternetAlert];
    }
}

- (void)showNoInternetAlert
{
    [[[UIAlertView alloc] initWithTitle:OALocalizedString(@"No Internet connection")
                                message:OALocalizedString(@"Internet connection is required to download maps. Please check your Internet connection.")
                       cancelButtonItem:[RIButtonItem itemWithLabel:OALocalizedString(@"OK")
                                                             action:^{
                                                                 OAOptionsPanelViewController* menuHostViewController = (OAOptionsPanelViewController*)self.menuHostViewController;
                                                                 [menuHostViewController dismissLastOpenedMenuAnimated:YES];
                                                             }]
                       otherButtonItems:nil] show];
}

- (void)onUpdateRepositoryAndRefresh
{
    if ([Reachability reachabilityForInternetConnection].currentReachabilityStatus != NotReachable)
        [self updateRepositoryAndReloadListAnimated];
    else
        [self showNoInternetAlert];
}

- (void)updateRepositoryAndReloadListAnimated
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            _isLoadingRepository = YES;
            _refreshBarButton.enabled = NO;
            [self.tableView reloadData];
            [self.updateActivityIndicator startAnimating];
        });

        _app.resourcesManager->updateRepository();

        dispatch_async(dispatch_get_main_queue(), ^{
            _isLoadingRepository = NO;
            [self.updateActivityIndicator stopAnimating];
            [self reloadList];
            _refreshBarButton.enabled = YES;
        });
    });
}

- (void)filterContentForSearchText:(NSString*)searchString
{
    NSMutableArray *beginsWith = [[_app.worldRegion.flattenedSubregions filteredArrayUsingPredicate:
                           [NSPredicate predicateWithFormat:@"%K BEGINSWITH[c] %@", @"name", searchString]] mutableCopy];
    [beginsWith sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        OAWorldRegion *item1 = obj1;
        OAWorldRegion *item2 = obj2;
        
        return [item1.name localizedCaseInsensitiveCompare:item2.name];
    }];
    
    NSMutableArray *contains = [[_app.worldRegion.flattenedSubregions filteredArrayUsingPredicate:
                          [NSPredicate predicateWithFormat:@"(name CONTAINS[c] %@) AND NOT (name BEGINSWITH[c] %@)", searchString]] mutableCopy];

    [contains sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        OAWorldRegion *item1 = obj1;
        OAWorldRegion *item2 = obj2;
        
        return [item1.name localizedCaseInsensitiveCompare:item2.name];
    }];
    
    [beginsWith addObjectsFromArray:contains];

    _searchResults = [beginsWith copy];
}

#pragma mark - OAMenuViewControllerProtocol

@synthesize menuHostViewController = _menuHostViewController;

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (tableView == self.searchDisplayController.searchResultsTableView)
        return 1;

    if (_isLoadingRepository)
        return 0; // No sections at all

    return [super numberOfSectionsInTableView:tableView];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.searchDisplayController.searchResultsTableView)
        return [_searchResults count];

    if (_isLoadingRepository)
        return 0; // No sections at all

    return [super tableView:tableView numberOfRowsInSection:section];
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.searchDisplayController.searchResultsTableView)
    {
        static NSString* const subregionItemCell = @"subregionItemCell";

        OAWorldRegion* worldRegion = [_searchResults objectAtIndex:indexPath.row];

        UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:subregionItemCell];
        if (cell == nil)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                          reuseIdentifier:subregionItemCell];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        cell.textLabel.text = worldRegion.name;

        return cell;
    }

    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}
#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.searchDisplayController.searchResultsTableView)
    {
        [self performSegueWithIdentifier:@"openSubregion" sender:[tableView cellForRowAtIndexPath:indexPath]];
        return;
    }
}

#pragma mark - UISearchDisplayDelegate

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    [self filterContentForSearchText:searchString];

    return YES;
}

#pragma mark - Navigation

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    UITableView* tableView = nil;
    if ([sender isKindOfClass:[OATableViewCell class]] || [[sender class] isSubclassOfClass:[OATableViewCell class]])
    {
        OATableViewCell* cell = (OATableViewCell*)sender;
        tableView = cell.tableView;
    }
    else if ([sender isKindOfClass:[UITableViewCell class]] || [[sender class] isSubclassOfClass:[UITableViewCell class]])
    {
        UITableViewCell* cell = (UITableViewCell*)sender;
        tableView = [cell getTableView];
    }

    if (tableView == self.searchDisplayController.searchResultsTableView)
    {
        NSIndexPath* selectedItemPath = [tableView indexPathForSelectedRow];

        if (selectedItemPath != nil &&
            [identifier isEqualToString:@"openSubregion"])
        {
            return (selectedItemPath.row < [_searchResults count]);
        }

        return NO;
    }

    return [super shouldPerformSegueWithIdentifier:identifier sender:sender];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    UITableView* tableView = nil;
    if ([sender isKindOfClass:[OATableViewCell class]] || [[sender class] isSubclassOfClass:[OATableViewCell class]])
    {
        OATableViewCell* cell = (OATableViewCell*)sender;
        tableView = cell.tableView;
    }
    else if ([sender isKindOfClass:[UITableViewCell class]] || [[sender class] isSubclassOfClass:[UITableViewCell class]])
    {
        UITableViewCell* cell = (UITableViewCell*)sender;
        tableView = [cell getTableView];
    }

    if (tableView == self.searchDisplayController.searchResultsTableView)
    {
        NSIndexPath* selectedItemPath = [tableView indexPathForSelectedRow];

        if (selectedItemPath != nil &&
            [segue.identifier isEqualToString:@"openSubregion"])
        {
            OARegionDownloadsViewController* regionDownloadsViewController = [segue destinationViewController];
            regionDownloadsViewController.worldRegion = [_searchResults objectAtIndex:selectedItemPath.row];
        }
        return;
    }

    [super prepareForSegue:segue sender:sender];
}

#pragma mark -

@end
