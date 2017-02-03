//
//  OACategoriesTableViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 17/12/2016.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OACategoriesTableViewController.h"
#import "Localization.h"
#import "OAPOISearchHelper.h"
#import "OACustomPOIViewController.h"
#import "OASearchUICore.h"
#import "OAQuickSearchHelper.h"
#import "OAQuickSearchListItem.h"
#import "OASearchCoreFactory.h"
#import "OACustomSearchButton.h"

@interface OACategoriesTableViewController ()

@end

@implementation OACategoriesTableViewController
{
    OAQuickSearchTableController *_tableController;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [[OACategoriesTableViewController alloc] initWithNibName:@"OACategoriesTableViewController" bundle:nil];
    if (self)
    {
        self.view.frame = frame;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    _tableController = [[OAQuickSearchTableController alloc] initWithTableView:self.tableView];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self reloadData];
}

-(void)setTableDelegate:(id<OAQuickSearchTableDelegate>)tableDelegate
{
    _tableDelegate = tableDelegate;
    _tableController.delegate = tableDelegate;
}

- (void) generateData
{
    OASearchResultCollection *res = [[[OAQuickSearchHelper instance] getCore] shallowSearch:[OASearchAmenityTypesAPI class] text:@"" matcher:nil];
    NSMutableArray<OAQuickSearchListItem *> *rows = [NSMutableArray array];
    if (res)
    {
        for (OASearchResult *sr in [res getCurrentSearchResults])
            [rows addObject:[[OAQuickSearchListItem alloc] initWithSearchResult:sr]];
        
        [rows addObject:[[OACustomSearchButton alloc] initWithClickFunction:^(id sender) {
            if (self.delegate)
                [self.delegate createPOIUIFIlter];
        }]];
    }
    [_tableController updateData:[NSArray arrayWithArray:rows] append:NO];
}

- (void) setMapCenterCoordinate:(CLLocationCoordinate2D)mapCenterCoordinate
{
    _mapCenterCoordinate = mapCenterCoordinate;
    _searchNearMapCenter = YES;
    [_tableController setMapCenterCoordinate:mapCenterCoordinate];
}

- (void) resetMapCenterSearch
{
    _searchNearMapCenter = NO;
    [_tableController resetMapCenterSearch];
}

- (void) reloadData
{
    [self generateData];
}

@end
