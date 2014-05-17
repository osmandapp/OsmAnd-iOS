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
#include "Localization.h"

#define _(name) OADownloadsViewController__##name
#define ctor _(ctor)
#define dtor _(dtor)

@interface OADownloadsViewController ()

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *updateActivityIndicator;

@end

@implementation OADownloadsViewController
{
    OsmAndAppInstance _app;

    BOOL _isLoadingRepository;

    UIBarButtonItem* _refreshBarButton;
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

#pragma mark - OAMenuViewControllerProtocol

@synthesize menuHostViewController = _menuHostViewController;

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (_isLoadingRepository)
        return 0; // No sections at all

    return [super numberOfSectionsInTableView:tableView];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (_isLoadingRepository)
        return 0; // No sections at all

    return [super tableView:tableView numberOfRowsInSection:section];
}

#pragma mark -

@end
