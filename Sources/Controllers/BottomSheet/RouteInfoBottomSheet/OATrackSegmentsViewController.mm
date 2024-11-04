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
#import "OAColors.h"
#import "OAApplicationMode.h"
#import "OAGPXTrackCell.h"
#import "OAGPXDatabase.h"
#import "OsmAndApp.h"
#import "OARoutingHelper.h"
#import "OARoutePreferencesParameters.h"
#import "OARouteProvider.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapActions.h"
#import "OAMeasurementEditingContext.h"
#import "OAGpxData.h"
#import "OATargetPointsHelper.h"
#import "OAGPXUIHelper.h"
#import "OAOsmAndFormatter.h"
#import "OASavingTrackHelper.h"
#import "OsmAndSharedWrapper.h"
#import "OsmAnd_Maps-Swift.h"

@interface OATrackSegmentsViewController () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation OATrackSegmentsViewController
{
    OASWptPt *_point;
    NSArray<NSDictionary *> *_data;
    
    OASGpxFile *_gpx;
    
    UIView *_tableHeaderView;
}

- (instancetype) initWithFile:(OASGpxFile *)gpx
{
    self = [super init];
    if (self)
    {
        _gpx = gpx;
        [self generateData];
    }
    return self;
}

- (instancetype) initWithFilepath:(NSString *)filepath isCurrentTrack:(BOOL)isCurrentTrack
{
    self = [super init];
    if (self)
    {
        if (isCurrentTrack) {
             _gpx = [OASavingTrackHelper.sharedInstance currentTrack];
        } else {
            OASKFile *file = [[OASKFile alloc] initWithFilePath:filepath];
            OASGpxFile *gpxFile = [OASGpxUtilities.shared loadGpxFileFile:file];
            _gpx = gpxFile;
        }
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
    
    _tableHeaderView = [OAUtilities setupTableHeaderViewWithText:self.getLocalizedDescription font:kHeaderDescriptionFont textColor:UIColor.blackColor isBigTitle:NO parentViewWidth:self.view.frame.size.width];
    self.tableView.tableHeaderView = _tableHeaderView;
}

- (void) applyLocalization
{
    self.titleLabel.font = [UIFont scaledSystemFontOfSize:17 weight:UIFontWeightMedium];
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
        fileName = OALocalizedString(@"shared_string_gpx_track");
    return fileName;
}

- (void) generateData
{
    NSMutableArray *data = [NSMutableArray new];
    NSString * fileName = [self getFileName];
    
    OAGPXDatabase *db = [OAGPXDatabase sharedDb];
    OASGpxDataItem *gpxData = [db getGPXItem:[OAUtilities getGpxShortPath:_gpx.path]];
    
    [data addObject:
     @{
         @"type" : [OAGPXTrackCell getCellIdentifier],
         @"title" : gpxData ? [gpxData getNiceTitle] : fileName,
         @"distance" : gpxData ? [OAOsmAndFormatter getFormattedDistance:gpxData.totalDistance] : @"",
         @"time" : gpxData ? [OAOsmAndFormatter getFormattedTimeInterval:gpxData.timeSpan / 1000 shortFormat:YES] : @"",
         @"wpt" : gpxData ? [NSString stringWithFormat:@"%d", gpxData.wptPoints] : @"",
         @"img" : @"ic_custom_trip"
     }
     ];
    
    NSInteger idx = 1;
    for (OASTrkSegment *seg in [_gpx getNonEmptyTrkSegmentsRoutesOnly:NO])
    {
        long segmentTime = [OAGPXUIHelper getSegmentTime:seg];
        double segmentDist = [OAGPXUIHelper getSegmentDistance:seg];

        NSString *segmentTitle = [self getTrackSegmentTitle:seg];
        if (!segmentTitle)
            segmentTitle = [NSString stringWithFormat:OALocalizedString(@"segments_count"), idx];

        NSMutableDictionary *item = [NSMutableDictionary new];
        item[@"title"] = segmentTitle;
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

- (NSString *)getTrackSegmentTitle:(OASTrkSegment *)segment
{
    OASTrack *track = [self getTrack:segment];
    if (track)
        return [OAGPXUIHelper buildTrackSegmentName:_gpx track:track segment:segment];
    return nil;
}

- (OASTrack *)getTrack:(OASTrkSegment *)segment
{
    for (OASTrack *trk in _gpx.tracks)
    {
        if ([trk.segments containsObject:segment])
            return trk;
    }
    return nil;
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
    if (self.startNavigationOnSelect)
        [self startNavigation:indexPath.row - 1 gpx:_gpx];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) startNavigation:(NSInteger)position gpx:(OASGpxFile *)gpx;
{
    [OAAppSettings.sharedManager.gpxRouteSegment set:position];

    [OARootViewController.instance.mapPanel.mapActions setGPXRouteParamsWithDocument:gpx path:gpx.path];
    [OARoutingHelper.sharedInstance recalculateRouteDueToSettingsChange];
    [[OATargetPointsHelper sharedInstance] updateRouteAndRefresh:YES];

    OAGPXRouteParamsBuilder *paramsBuilder = OARoutingHelper.sharedInstance.getCurrentGPXRoute;
    if (paramsBuilder)
    {
        [paramsBuilder setSelectedSegment:position];
        NSArray<CLLocation *> *ps = [paramsBuilder getPoints];
        if (ps.count > 0)
        {
            OATargetPointsHelper *tg = [OATargetPointsHelper sharedInstance];
            [tg clearStartPoint:NO];
            CLLocation *loc = ps.lastObject;
            [tg navigateToPoint:loc updateRoute:YES intermediate:-1];
        }
    }

    [OARootViewController.instance.mapPanel.mapActions stopNavigationWithoutConfirm];
    [OARootViewController.instance.mapPanel.mapActions enterRoutePlanningModeGivenGpx:gpx
                                                                      path:[gpx.path lastPathComponent]
                                                                      from:nil
                                                                  fromName:nil
                                            useIntermediatePointsByDefault:YES
                                                                showDialog:YES];
    
    [self dismissViewController];
}

@end
