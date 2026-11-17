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
#import "OsmAnd_Maps-Swift.h"
#import "GeneratedAssetSymbols.h"

@interface OACategoriesTableViewController ()

@end

@implementation OACategoriesTableViewController
{
    NSUInteger _dataRequest;
    BOOL _dataRequestInvalidated;
    OAQuickSearchTableController *_tableController;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithNibName:@"OACategoriesTableViewController" bundle:nil];
    if (self)
    {
        self.view.frame = frame;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.separatorColor = [SeparatorAppearance color];

    _tableController = [[OAQuickSearchTableController alloc] initWithTableView:self.tableView];
}

-(void)viewWillAppear:(BOOL)animated
{
    _dataRequestInvalidated = NO;
    [super viewWillAppear:animated];
    [self reloadData];
}

- (void)viewDidDisappear:(BOOL)animated
{
    _dataRequestInvalidated = YES;
    ++_dataRequest;
    [super viewDidDisappear:animated];
}

-(void)setTableDelegate:(id<OAQuickSearchTableDelegate>)tableDelegate
{
    _tableDelegate = tableDelegate;
    _tableController.delegate = tableDelegate;
}

- (void)generateData
{
    if (_dataRequestInvalidated)
        return;
    NSUInteger request = ++_dataRequest;
    __weak __typeof(self) weakSelf = self;
    [[[OAQuickSearchHelper instance] getCore] shallowSearchAsync:OASearchAmenityTypesAPI.class text:@"" matcher:nil completion:^(OASearchResultCollection *res) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong __typeof(weakSelf) self = weakSelf;
            if (self && request == self->_dataRequest)
                [self updateDataWithResults:res];
        });
    }];
}

- (void)updateDataWithResults:(OASearchResultCollection *)res
{
    NSMutableArray<OAQuickSearchListItem *> *rows = [NSMutableArray array];
    if (res)
    {
        for (OASearchResult *sr in [res getCurrentSearchResults])
            [rows addObject:[[OAQuickSearchListItem alloc] initWithSearchResult:sr]];

        [rows addObject:[[OAQuickSearchButtonListItem alloc] initWithIcon:[UIImage imageNamed:ACImageNameIcCustomAdd] text:OALocalizedString(@"add_custom_category") actionButton:YES onClickFunction:^(id sender) {
            if (self.delegate)
                [self.delegate showCreateFilterScreen];
        }]];

        NSArray<OAPOIUIFilter *> *allFilters = [self.delegate getSortedFiltersIncludeInactive];
        if (allFilters.count > 0)
        {
            [rows addObject:[[OAQuickSearchButtonListItem alloc] initWithIcon:[UIImage imageNamed:ACImageNameIcCustomEdit] text:OALocalizedString(@"rearrange_categories") actionButton:YES onClickFunction:^(id sender) {
                if (self.delegate)
                    [self.delegate showRearrangeFiltersScreen:allFilters];
            }]];
        }
        NSArray<OAPOIUIFilter *> *customFilters = [self.delegate getCustomFilters];
        if (customFilters.count > 0)
        {
            [rows addObject:[[OAQuickSearchButtonListItem alloc] initWithIcon:[UIImage imageNamed:ACImageNameIcCustomRemove] text:OALocalizedString(@"delete_custom_categories") actionButton:YES onClickFunction:^(id sender) {
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
