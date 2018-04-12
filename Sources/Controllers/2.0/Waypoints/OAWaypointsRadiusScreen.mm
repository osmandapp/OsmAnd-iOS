//
//  OAWaypointsRadiusScreen.m
//  OsmAnd
//
//  Created by Alexey Kulish on 23/03/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAWaypointsRadiusScreen.h"
#import "OAWaypointsViewController.h"
#import "Localization.h"
#import "OsmAndApp.h"
#import "OAWaypointHelper.h"
#import "OALocationPointWrapper.h"
#import "OASettingsTableViewCell.h"

@implementation OAWaypointsRadiusScreen
{
    OsmAndAppInstance _app;
    OAWaypointHelper *_waypointHelper;
    
    int _type;
    NSArray* _data;
}

@synthesize waypointsScreen, tableData, vwController, tblView, title;

- (id) initWithTable:(UITableView *)tableView viewController:(OAWaypointsViewController *)viewController param:(id)param
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _waypointHelper = [OAWaypointHelper sharedInstance];
        
        _type = ((NSNumber *)param).intValue;
        
        title = OALocalizedString(@"search_radius");
        waypointsScreen = EWaypointsScreenRadius;
        
        vwController = viewController;
        tblView = tableView;
        //tblView.separatorInset = UIEdgeInsetsMake(0, 44, 0, 0);
        
        [self initData];
    }
    return self;
}

- (void) setupView
{
    NSMutableArray *arr = [NSMutableArray array];
    int selectedRadius = [_waypointHelper getSearchDeviationRadius:_type];
    for (NSNumber *i in LPW_SEARCH_RADIUS_VALUES)
    {
        [arr addObject:
            @{
              @"name" : [_app getFormattedDistance:i.intValue],
              @"value" : i,
              @"img" : i.intValue == selectedRadius ? @"menu_cell_selected.png" : @"" }];
    }
    
    _data = [NSArray arrayWithArray:arr];
}

- (void) initData
{
}

- (CGFloat) heightForRow:(NSIndexPath *)indexPath tableView:(UITableView *)tableView
{
    NSDictionary *item = _data[indexPath.row];
    return [OASettingsTableViewCell getHeight:[item objectForKey:@"name"] value:@"" cellWidth:tableView.bounds.size.width];
}

#pragma mark - UITableViewDataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _data.count;
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* const identifierCell = @"OASettingsTableViewCell";
    OASettingsTableViewCell* cell = nil;
    
    cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OASettingsCell" owner:self options:nil];
        cell = (OASettingsTableViewCell *)[nib objectAtIndex:0];
    }
    
    if (cell)
    {
        [cell.textView setText: [_data[indexPath.row] objectForKey:@"name"]];
        [cell.descriptionView setText:@""];
        NSString *imgName = [_data[indexPath.row] objectForKey:@"img"];
        if (imgName.length > 0)
            [cell.iconView setImage:[UIImage imageNamed:imgName]];
        else
            [cell.iconView setImage:nil];
    }
    
    return cell;
    
}

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self heightForRow:indexPath tableView:tableView];
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self heightForRow:indexPath tableView:tableView];
}

#pragma mark - UITableViewDelegate

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.01;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.row];
    NSNumber *radius = [item objectForKey:@"value"];
    
    [OAWaypointsViewController setRequest:EWaypointsViewControllerChangeRadiusAction type:_type param:radius];

    [self setupView];
    [tableView reloadData];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [vwController backButtonClicked:nil];
}

@end
