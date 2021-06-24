//
//  OACategoriesTableViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 17/12/2016.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OACategoriesTableViewController.h"
#import "Localization.h"
#import "OACustomPOIViewController.h"
#import "OASearchUICore.h"
#import "OAQuickSearchHelper.h"
#import "OAQuickSearchListItem.h"
#import "OASearchCoreFactory.h"
#import "OAPOIUIFilter.h"
#import "OAQuickSearchButtonListItem.h"
#import "OAPOIFiltersHelper.h"
#import "OAQuickSearchEmptyResultListItem.h"

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

        if (rows.count > 0)
            [rows addObject:[[OAQuickSearchEmptyResultListItem alloc] initSeparator]];

        [rows addObject:[[OAQuickSearchButtonListItem alloc] initWithIcon:[UIImage imageNamed:@"ic_custom_add"] text:OALocalizedString(@"add_custom_category") actionButton:YES onClickFunction:^(id sender) {
            if (self.delegate)
                [self.delegate showCreateFilterScreen];
        }]];

        NSArray<OAPOIUIFilter *> *allFilters = [self.delegate getSortedFiltersIncludeInactive];
        if (allFilters.count > 0)
        {
            [rows addObject:[[OAQuickSearchButtonListItem alloc] initWithIcon:[UIImage imageNamed:@"ic_custom_edit"] text:OALocalizedString(@"rearrange_categories") actionButton:YES onClickFunction:^(id sender) {
                if (self.delegate)
                    [self.delegate showRearrangeFiltersScreen:allFilters];
            }]];
        }
        NSArray<OAPOIUIFilter *> *customFilters = [self.delegate getCustomFilters];
        if (customFilters.count > 0)
        {
            [rows addObject:[[OAQuickSearchButtonListItem alloc] initWithIcon:[UIImage imageNamed:@"ic_custom_remove"] text:OALocalizedString(@"delete_custom_categories") actionButton:YES onClickFunction:^(id sender) {
                if (self.delegate)
                    [self.delegate showDeleteFiltersScreen:customFilters];
            }]];
        }
    }
    [_tableController updateData:@[[NSArray arrayWithArray:rows]] append:NO];
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
