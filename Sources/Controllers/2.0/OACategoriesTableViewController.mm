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

@interface OACategoriesTableViewController ()

@end

@implementation OACategoriesTableViewController

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
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return [OAPOISearchHelper getHeightForHeader];
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return [OAPOISearchHelper getHeightForFooter];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [OAPOISearchHelper getHeightForRowAtIndexPath:indexPath tableView:tableView dataArray:_dataArray dataPoiArray:nil showCoordinates:NO];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [OAPOISearchHelper getNumberOfRows:_dataArray dataPoiArray:nil currentScope:EPOIScopeUndefined showCoordinates:NO showTopList:YES poiInList:NO searchRadiusIndex:0 searchRadiusIndexMax:0];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [OAPOISearchHelper getCellForRowAtIndexPath:indexPath tableView:tableView dataArray:_dataArray dataPoiArray:nil currentScope:EPOIScopeUndefined poiInList:NO showCoordinates:NO foundCoords:nil showTopList:YES searchRadiusIndex:0 searchRadiusIndexMax:0 searchNearMapCenter:_searchNearMapCenter];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.delegate && indexPath.row < _dataArray.count)
    {
        [self.delegate didSelectCategoryItem:_dataArray[indexPath.row]];
    }
}

@end
