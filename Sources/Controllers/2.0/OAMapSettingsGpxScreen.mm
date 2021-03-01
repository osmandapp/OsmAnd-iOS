//
//  OAMapSettingsGpxScreen.m
//  OsmAnd
//
//  Created by Alexey Kulish on 23/02/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAMapSettingsGpxScreen.h"
#import "OAMapSettingsViewController.h"
#import "OAMapStyleSettings.h"
#import "OAGPXTableViewCell.h"
#import "OAGPXDatabase.h"
#import "OARootViewController.h"
#import "Localization.h"
#import "OASavingTrackHelper.h"
#import "OAGPXMutableDocument.h"

@implementation OAMapSettingsGpxScreen
{
    OsmAndAppInstance _app;
    OAAppSettings *_settings;

    NSArray *gpxList;
    BOOL hasCurrentTrack;
    OASavingTrackHelper *helper;
}

@synthesize settingsScreen, tableData, vwController, tblView, title, isOnlineMapSource;


- (id) initWithTable:(UITableView *)tableView viewController:(OAMapSettingsViewController *)viewController
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _settings = [OAAppSettings sharedManager];

        helper = [OASavingTrackHelper sharedInstance];
        hasCurrentTrack = [helper hasData] || _settings.mapSettingTrackRecording;
        
        settingsScreen = EMapSettingsScreenGpx;
        
        vwController = viewController;
        tblView = tableView;
        
        [self commonInit];
        [self initData];
    }
    return self;
}

- (void) dealloc
{
    [self deinit];
}

- (void) commonInit
{
}

- (void) deinit
{
}

- (void) initData
{
    gpxList = [[[OAGPXDatabase sharedDb] gpxList] sortedArrayUsingComparator:^NSComparisonResult(OAGPX *obj1, OAGPX *obj2) {
        return [obj2.importDate compare:obj1.importDate];
    }];
}

- (void) setupView
{
    title = OALocalizedString(@"tracks");
}

#pragma mark - UITableViewDataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return gpxList.count + (hasCurrentTrack ? 1 : 0);
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OAGPXTableViewCell* cell;
    static NSString* const reusableIdentifierPoint = @"OAGPXTableViewCell";
    
    cell = (OAGPXTableViewCell *)[tableView dequeueReusableCellWithIdentifier:reusableIdentifierPoint];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAGPXCell" owner:self options:nil];
        cell = (OAGPXTableViewCell *)[nib objectAtIndex:0];
    }

    if (hasCurrentTrack && indexPath.row == 0)
    {
        if (cell)
        {
            [cell.textView setText:OALocalizedString(@"track_recording_name")];
            [cell.descriptionDistanceView setText:[_app getFormattedDistance:helper.distance]];
            [cell.descriptionPointsView setText:[NSString stringWithFormat:@"%d %@", helper.points, [OALocalizedString(@"gpx_points") lowercaseStringWithLocale:[NSLocale currentLocale]]]];
            
            if (_settings.mapSettingShowRecordingTrack)
                [cell.iconView setImage:[UIImage imageNamed:@"menu_cell_selected.png"]];
            else
                [cell.iconView setImage:nil];
        }
    }
    else
    {
        if (cell)
        {
            OAGPX* item = [gpxList objectAtIndex:indexPath.row - (hasCurrentTrack ? 1 : 0)];
            [cell.textView setText:[item getNiceTitle]];
            [cell.descriptionDistanceView setText:[_app getFormattedDistance:item.totalDistance]];
            [cell.descriptionPointsView setText:[NSString stringWithFormat:@"%d %@", item.wptPoints, [OALocalizedString(@"gpx_points") lowercaseStringWithLocale:[NSLocale currentLocale]]]];
            
            NSArray *visible = _settings.mapSettingVisibleGpx;
            
            if ([visible containsObject:item.file])
                [cell.iconView setImage:[UIImage imageNamed:@"menu_cell_selected.png"]];
            else
                [cell.iconView setImage:nil];
        }
    }
    
    return cell;
}


#pragma mark - UITableViewDelegate

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.01;
}

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50.0;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (hasCurrentTrack && indexPath.row == 0)
    {
        if (_settings.mapSettingShowRecordingTrack)
        {
            _settings.mapSettingShowRecordingTrack = NO;
        }
        else
        {
            _settings.mapSettingShowRecordingTrack = YES;
            [helper.currentTrack applyBounds];
            OAGpxBounds bounds = helper.currentTrack.bounds;

            [[OARootViewController instance].mapPanel prepareMapForReuse:nil mapBounds:bounds newAzimuth:0.0 newElevationAngle:90.0 animated:NO];
        }
        [[[OsmAndApp instance] updateRecTrackOnMapObservable] notifyEvent];
    }
    else
    {
        NSArray *visible = _settings.mapSettingVisibleGpx;
        OAGPX *gpx = gpxList[indexPath.row - (hasCurrentTrack ? 1 : 0)];
        if ([visible containsObject:gpx.file])
        {
            [_settings hideGpx:@[gpx.file]];
        }
        else
        {
            [_settings showGpx:@[gpx.file]];

            [[OARootViewController instance].mapPanel prepareMapForReuse:nil mapBounds:gpx.bounds newAzimuth:0.0 newElevationAngle:90.0 animated:NO];
        }
    }
    
    [tableView reloadData];
}

@end
