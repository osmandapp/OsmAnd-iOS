//
//  OAAddressTableViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 23/05/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAAddressTableViewController.h"
#import "Localization.h"
#import "OASearchUICore.h"
#import "OAQuickSearchHelper.h"
#import "OAQuickSearchListItem.h"
#import "OASearchCoreFactory.h"

@interface OAAddressTableViewController ()

@end

@implementation OAAddressTableViewController
{
    OAQuickSearchTableController *_tableController;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [[OAAddressTableViewController alloc] initWithNibName:@"OAAddressTableViewController" bundle:nil];
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

- (void) setData:(NSArray<NSArray<OAQuickSearchListItem *> *> *)rows
{
    [_tableController updateData:rows append:NO];
}

- (void) reloadData
{
    if (self.delegate)
        [self.delegate reloadAddressData];
}

- (void) updateDistanceAndDirection
{
    [_tableController updateDistanceAndDirection];
}

@end
