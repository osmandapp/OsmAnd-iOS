//
//  OATrackSegmentsBottomSheetViewController.m
//  OsmAnd
//
//  Created by Paul on 31.10.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OATrackSegmentsViewController.h"
#import "OAOpenAddTrackViewController.h"
#import "OARoutePlanningHudViewController.h"
#import "Localization.h"
#import "OAGPXDocumentPrimitives.h"
#import "OAColors.h"
#import "OAApplicationMode.h"
#import "OAGPXTrackCell.h"
#import "OAGPXDatabase.h"
#import "OsmAndApp.h"
#import "OARoutingHelper.h"
#import "OAGPXDocument.h"
#import "OARoutingHelper.h"
#import "OARoutePreferencesParameters.h"
#import "OARouteProvider.h"
#import "OAGPXMutableDocument.h"
#import "OARootViewController.h"
#import "OAMeasurementEditingContext.h"
#import "OAGpxData.h"
#import "OAGpxInfo.h"
#import "OATargetPointsHelper.h"
#import "OAGPXUIHelper.h"
#import "OAOsmAndFormatter.h"

@interface OATrackSegmentsViewController () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation OATrackSegmentsViewController
{
    OAGpxTrkPt *_point;
    NSArray<NSDictionary *> *_data;
    
    OAGPXDocument *_gpx;
    
    UIView *_tableHeaderView;
}

- (instancetype) initWithFile:(OAGPXDocument *)gpx
{
    self = [super init];
    if (self)
    {
        _gpx = gpx;
        [self generateData];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorInset = UIEdgeInsetsMake(0., 20., 0., 0.);
    self.cancelButton.hidden = YES;
    
    _tableHeaderView = [OAUtilities setupTableHeaderViewWithText:self.getLocalizedDescription font:[UIFont systemFontOfSize:15] textColor:UIColor.blackColor lineSpacing:0. isTitle:NO];
    self.tableView.tableHeaderView = _tableHeaderView;
}

- (void) applyLocalization
{
    self.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightMedium];
    self.titleLabel.text = OALocalizedString(@"select_segment");
}

- (NSString *) getFileName
{
    NSString *fileName = nil;
    if (_gpx.path.length > 0)
        fileName = [_gpx.path.lastPathComponent stringByDeletingPathExtension];
    else if (_gpx.tracks.count > 0)
        fileName = _gpx.tracks.firstObject.name;
    
    if (fileName == nil || fileName.length == 0)
        fileName = OALocalizedString(@"track");
    return fileName;
}

- (void) generateData
{
    NSMutableArray *data = [NSMutableArray new];
    NSString * fileName = [self getFileName];
    
    OAGPXDatabase *db = [OAGPXDatabase sharedDb];
    OAGPX *gpxData = [db getGPXItem:[OAUtilities getGpxShortPath:_gpx.path]];
    
    [data addObject:
     @{
         @"type" : [OAGPXTrackCell getCellIdentifier],
         @"title" : gpxData ? [gpxData getNiceTitle] : fileName,
         @"distance" : gpxData ? [OAOsmAndFormatter getFormattedDistance:gpxData.totalDistance] : @"",
         @"time" : gpxData ? [OAOsmAndFormatter getFormattedTimeInterval:gpxData.timeSpan shortFormat:YES] : @"",
         @"wpt" : gpxData ? [NSString stringWithFormat:@"%d", gpxData.wptPoints] : @"",
         @"img" : @"ic_custom_trip"
     }
     ];
    
    NSInteger idx = 1;
    for (OAGpxTrkSeg *seg in [_gpx getNonEmptyTrkSegments:NO])
    {
        long segmentTime = [OAGPXUIHelper getSegmentTime:seg];
        double segmentDist = [OAGPXUIHelper getSegmentDistance:seg];
        
        NSMutableDictionary *item = [NSMutableDictionary new];
        item[@"title"] = [NSString stringWithFormat:OALocalizedString(@"segnet_num"), (int) idx];
        item[@"type"] = [OAGPXTrackCell getCellIdentifier];
        item[@"img"] = @"ic_custom_join_segments";
        item[@"distance"] = [OAOsmAndFormatter getFormattedDistance:segmentDist];
        
        if (segmentTime != 1)
            item[@"time"] = [OAOsmAndFormatter getFormattedTimeInterval:segmentTime shortFormat:YES];
        
        [data addObject:item];
        idx++;
    }
    
    _data = data;
}

- (NSString *) getLocalizedDescription
{
    return [NSString stringWithFormat:OALocalizedString(@"track_multiple_segments_select"), [[self getFileName] stringByAppendingPathExtension:@"gpx"]];
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.row];
    NSString *type = item[@"type"];
    
    if ([type isEqualToString:[OAGPXTrackCell getCellIdentifier]])
    {
        OAGPXTrackCell* cell = nil;
        cell = [tableView dequeueReusableCellWithIdentifier:[OAGPXTrackCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAGPXTrackCell getCellIdentifier] owner:self options:nil];
            cell = (OAGPXTrackCell *)[nib objectAtIndex:0];
            cell.separatorInset = UIEdgeInsetsZero;
            [cell setRightButtonVisibility:NO];
            cell.distanceImageView.tintColor = UIColorFromRGB(color_tint_gray);
            cell.timeImageView.tintColor = UIColorFromRGB(color_tint_gray);
            cell.wptImageView.tintColor = UIColorFromRGB(color_tint_gray);
        }
        if (cell)
        {
            if (indexPath.row > 0)
                cell.separatorInset = UIEdgeInsetsMake(0., 70., 0., 0.);
            else
                cell.separatorInset = UIEdgeInsetsZero;
            
            cell.leftIconImageView.image = [UIImage imageNamed:item[@"img"]];
            cell.titleLabel.text = item[@"title"];
            cell.distanceLabel.text = item[@"distance"];
            cell.distanceImageView.hidden = !cell.distanceLabel.text || cell.distanceLabel.text.length == 0;
            cell.timeLabel.text = item[@"time"];
            cell.timeImageView.hidden = !cell.timeLabel.text || cell.timeLabel.text.length == 0;
            cell.wptLabel.text = item[@"wpt"];
            cell.wptImageView.hidden = !cell.wptLabel.text || cell.wptLabel.text.length == 0;
        }
        return cell;
    }
    return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _data.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.001;
}

#pragma mark - UItableViewDelegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.delegate)
        [self.delegate onSegmentSelected:indexPath.row - 1 gpx:_gpx];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
