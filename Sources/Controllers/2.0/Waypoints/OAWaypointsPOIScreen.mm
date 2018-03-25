//
//  OAWaypointsPOIScreen.m
//  OsmAnd
//
//  Created by Alexey Kulish on 23/03/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAWaypointsPOIScreen.h"
#import "OAWaypointsViewController.h"
#import "Localization.h"
#import "OsmAndApp.h"
#import "OAWaypointHelper.h"
#import "OAPOIFiltersHelper.h"
#import "OAPOIUIFilter.h"
#import "OAUtilities.h"
#import "OALocationPointWrapper.h"

#import "OALocationPointWrapper.h"
#import "OASettingsImageCell.h"

@implementation OAWaypointsPOIScreen
{
    OsmAndAppInstance _app;
    OAWaypointHelper *_waypointHelper;
    OAPOIFiltersHelper *_poiFilters;
    
    NSMutableArray* _data;
}

@synthesize waypointsScreen, tableData, vwController, tblView, title;

- (id) initWithTable:(UITableView *)tableView viewController:(OAWaypointsViewController *)viewController param:(id)param
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _waypointHelper = [OAWaypointHelper sharedInstance];
        _poiFilters = [OAPOIFiltersHelper sharedInstance];
        
        title = OALocalizedString(@"poi");
        waypointsScreen = EWaypointsScreenPOI;
        
        vwController = viewController;
        tblView = tableView;
        //tblView.separatorInset = UIEdgeInsetsMake(0, 44, 0, 0);
        
        [self initData];
    }
    return self;
}

- (void) setupView
{
    [vwController.backButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
    vwController.applyButton.hidden = NO;
    
    NSMutableArray *arr = [NSMutableArray array];
    
    [arr addObject: [@{
                      @"name" : OALocalizedString(@"shared_string_search"),
                      @"value" : [_poiFilters getCustomPOIFilter],
                      @"selectable" : @NO,
                      @"selected" : @NO,
                      @"img" : @"search_icon" } mutableCopy]];

    for (OAPOIUIFilter *f in [_poiFilters getTopDefinedPoiFilters])
    {
        [arr addObject: [@{
                          @"name" : [f getName],
                          @"selectable" : @YES,
                          @"selected" : @([_poiFilters isPoiFilterSelected:f]),
                          @"value" : f } mutableCopy]];
    }
    
    for (OAPOIUIFilter *f in [_poiFilters getSearchPoiFilters])
    {
        [arr addObject: [@{
                          @"name" : [f getName],
                          @"selectable" : @YES,
                          @"selected" : @([_poiFilters isPoiFilterSelected:f]),
                          @"value" : f } mutableCopy]];
    }
    
    _data = arr;
}

- (void) initData
{
}

- (void) applyChanges
{
    for (NSDictionary *item in _data)
    {
        OAPOIUIFilter *filter = item[@"value"];
        if ([item[@"selected"] boolValue])
            [_poiFilters addSelectedPoiFilter:filter];
        else
            [_poiFilters removeSelectedPoiFilter:filter];
    }
    
    if ([_poiFilters isShowingAnyPoi])
        [OAWaypointsViewController setRequest:EWaypointsViewControllerEnableTypeAction type:LPW_POI param:@YES];
    else
        [OAWaypointsViewController setRequest:EWaypointsViewControllerEnableTypeAction type:LPW_POI param:@NO];
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
    static NSString* const identifierCell = @"OASettingsImageCell";
    OASettingsImageCell* cell = nil;
    
    NSDictionary *item = _data[indexPath.row];
    OAPOIUIFilter *f = item[@"value"];
    BOOL selected = [item[@"selected"] boolValue];
    NSString *name = item[@"name"];
    NSString *imgName = item[@"img"];

    cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OASettingsImageCell" owner:self options:nil];
        cell = (OASettingsImageCell *)[nib objectAtIndex:0];
    }
    
    if (cell)
    {
        [cell.textView setText:name];
        if (imgName)
        {
            [cell.imgView setImage:[UIImage imageNamed:imgName]];
        }
        else
        {
            NSString *imgName = [f getIconId];
            UIImage *img = [OAUtilities getMxIcon:imgName];
            if (!img)
                img = [OAUtilities getMxIcon:@"user_defined"];
            
            [cell.imgView setImage:img];
        }
        if (selected)
            [cell setSecondaryImage:[UIImage imageNamed:@"menu_cell_selected.png"]];
        else
            [cell setSecondaryImage:nil];
    }
    
    return cell;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.row];
    BOOL selected = [item[@"selected"] boolValue];
    return [OASettingsImageCell getHeight:item[@"name"] hasSecondaryImg:selected cellWidth:tableView.bounds.size.width];
}

#pragma mark - UITableViewDelegate

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.01;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableDictionary *item = _data[indexPath.row];
    BOOL selectable = [item[@"selectable"] boolValue];
    BOOL selected = [item[@"selected"] boolValue];

    if (selectable)
    {
        item[@"selected"] = @(!selected);
        [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
