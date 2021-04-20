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
#import "OAQuickSearchButtonListItem.h"

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
        
        [rows addObject:[[OAQuickSearchButtonListItem alloc] initWithIcon:[UIImage imageNamed:@"search_icon"] text:OALocalizedString(@"custom_search") onClickFunction:^(id sender) {
            if (self.delegate)
                [self.delegate createPOIUIFilter];
        }]];

        if (self.delegate) {
            NSArray<OAPOIUIFilter *> *customFilters = [self.delegate getCustomFilters];
            if (customFilters.count > 0) {
                [rows addObject:[[OAQuickSearchButtonListItem alloc] initWithIcon:[UIImage imageNamed:@"ic_custom_remove"] text:OALocalizedString(@"delete_custom_categories") onClickFunction:^(id sender) {
                    [self.delegate showRemoveFiltersScreen:customFilters];
                }]];
            }
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
