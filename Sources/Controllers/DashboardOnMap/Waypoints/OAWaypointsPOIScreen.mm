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
#import "OARootViewController.h"

#import "OALocationPointWrapper.h"
#import "OAIconTextTableViewCell.h"

@implementation OAWaypointsPOIScreen
{
    OsmAndAppInstance _app;
    OAWaypointHelper *_waypointHelper;
    OAPOIFiltersHelper *_poiFilters;
    
    NSMutableArray* _data;
    BOOL _multiSelect;
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
        
        if (param)
            _multiSelect = [param boolValue];
        else
            _multiSelect = NO;

        title = OALocalizedString(@"show_poi_over_map");
        waypointsScreen = EWaypointsScreenPOI;
        
        vwController = viewController;
        tblView = tableView;

        tblView.allowsMultipleSelectionDuringEditing = YES;
        //tblView.separatorInset = UIEdgeInsetsMake(0, 44, 0, 0);
        
        [self initData];
    }
    return self;
}

- (void) setupView
{
    BOOL hasData = _data != nil && _data.count > 0;

    [vwController.backButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
    UIButton *okButton = vwController.okButton;
    if (_multiSelect)
    {
        [okButton setTitle:OALocalizedString(@"shared_string_apply") forState:UIControlStateNormal];
        [okButton setImage:nil forState:UIControlStateNormal];
        okButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        okButton.contentEdgeInsets = UIEdgeInsetsZero;
    }
    else
    {
        [okButton setTitle:nil forState:UIControlStateNormal];
        [okButton setImage:[UIImage imageNamed:@"selection_checked"] forState:UIControlStateNormal];
        okButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
        okButton.contentEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 12);
    }
    okButton.hidden = NO;
    
    NSMutableArray *arr = [NSMutableArray array];
    NSMutableArray<NSIndexPath *> *selectedPaths = [NSMutableArray array];
    int i = hasData && [@NO isEqual:_data[0][@"selectable"]] ? 1 : 0;
    if (!_multiSelect)
    {
        [arr addObject: [@{
                           @"name" : OALocalizedString(@"shared_string_search"),
                           @"value" : [_poiFilters getCustomPOIFilter],
                           @"selectable" : @NO,
                           @"selected" : @NO,
                           @"img" : @"search_icon" } mutableCopy]];
        i++;
    }

    for (OAPOIUIFilter *f in [_poiFilters getTopDefinedPoiFilters])
    {
        BOOL selected = [_poiFilters isPoiFilterSelected:f];
        if (selected)
            [selectedPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
            
        [arr addObject: [@{
                          @"name" : [f getName],
                          @"selectable" : @YES,
                          @"selected" : @(selected),
                          @"value" : f } mutableCopy]];
        i++;
    }
    
    for (OAPOIUIFilter *f in [_poiFilters getSearchPoiFilters])
    {
        BOOL selected = [_poiFilters isPoiFilterSelected:f];
        if (selected)
            [selectedPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
        
        [arr addObject: [@{
                          @"name" : [f getName],
                          @"selectable" : @YES,
                          @"selected" : @(selected),
                          @"value" : f } mutableCopy]];
        i++;
    }
    
    _data = arr;
    
    if (_multiSelect && !tblView.editing)
    {
        if (!hasData)
            [tblView reloadData];
        
        [tblView setEditing:YES animated:YES];

        [tblView beginUpdates];
        
        if (hasData)
            [tblView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationBottom];
        
        for (NSIndexPath *p in selectedPaths)
            [tblView selectRowAtIndexPath:p animated:hasData scrollPosition:UITableViewScrollPositionNone];
        
        [tblView endUpdates];
    }
}

- (void) initData
{
}

- (BOOL) okButtonPressed
{
    if (_multiSelect)
    {
        NSArray<NSIndexPath *> *selected = [tblView indexPathsForSelectedRows];
        int i = 0;
        for (NSDictionary *item in _data)
        {
            OAPOIUIFilter *filter = item[@"value"];
            NSIndexPath *p = [NSIndexPath indexPathForRow:i++ inSection:0];
            if (selected && [selected containsObject:p])
                [_poiFilters addSelectedPoiFilter:filter];
            else
                [_poiFilters removeSelectedPoiFilter:filter];
        }
        
        if ([_poiFilters isShowingAnyPoi])
            [OAWaypointsViewController setRequest:EWaypointsViewControllerEnableTypeAction type:LPW_POI param:@YES];
        else
            [OAWaypointsViewController setRequest:EWaypointsViewControllerEnableTypeAction type:LPW_POI param:@NO];
        
        return YES;
    }
    else
    {
        _multiSelect = YES;
        [self setupView];
        return NO;
    }
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
    NSDictionary *item = _data[indexPath.row];
    OAPOIUIFilter *f = item[@"value"];
    NSString *name = item[@"name"];
    NSString *imgName = item[@"img"];
    
    OAIconTextTableViewCell* cell;
    cell = (OAIconTextTableViewCell *)[tblView dequeueReusableCellWithIdentifier:[OAIconTextTableViewCell getCellIdentifier]];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAIconTextTableViewCell getCellIdentifier] owner:self options:nil];
        cell = (OAIconTextTableViewCell *)[nib objectAtIndex:0];
        cell.textView.numberOfLines = 0;
        cell.arrowIconView.hidden = YES;
    }
    
    if (cell)
    {
        [cell.textView setText:name];
        [cell.textView setTextColor:[UIColor blackColor]];
        if (imgName)
        {
            [cell.iconView setImage:[UIImage imageNamed:imgName]];
        }
        else
        {
            NSString *imgName = [f getIconId];
            UIImage *img = [OAUtilities getMxIcon:imgName];
            if (!img)
                img = [OAUtilities getMxIcon:@"user_defined"];
            
            [cell.iconView setImage:img];
        }
    }
    
    return cell;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewAutomaticDimension;
}

#pragma mark - UITableViewDelegate

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.01;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableDictionary *item = _data[indexPath.row];
    if (!_multiSelect)
    {
        OAPOIUIFilter *filter = item[@"value"];
        if ([filter.filterId isEqualToString:CUSTOM_FILTER_ID])
        {
            [vwController closeDashboard];
            [[OARootViewController instance].mapPanel openSearch:OAQuickSearchType::REGULAR];
        }
        else
        {
            [_poiFilters clearSelectedPoiFilters];
            [_poiFilters addSelectedPoiFilter:filter];
            
            [OAWaypointsViewController setRequest:EWaypointsViewControllerEnableTypeAction type:LPW_POI param:@YES];
            
        }
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        [vwController backButtonClicked:nil];
    }
}

@end
