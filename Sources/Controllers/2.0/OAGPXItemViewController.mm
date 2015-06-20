//
//  OAGPXItemViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 16/02/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAGPXItemViewController.h"
#import "OAGPXDetailsTableViewCell.h"
#import "OAGPXElevationTableViewCell.h"
#import "OsmAndApp.h"
#import "OAGPXDatabase.h"
#import "OAGPXDocumentPrimitives.h"
#import "OAGPXDocument.h"
#import "OAGPXPointListViewController.h"

#import "OAMapRendererView.h"
#import "OARootViewController.h"
#import "OANativeUtilities.h"
#import "Localization.h"
#import "OAUtilities.h"
#import "OASavingTrackHelper.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>


@interface OAGPXItemViewController ()<UIDocumentInteractionControllerDelegate> {

    OsmAndAppInstance _app;
    NSDateFormatter *dateTimeFormatter;
    
    OAMapViewController *_mapViewController;
    
    BOOL _startEndTimeExists;
}

@property (nonatomic) OAGPXDocument *doc;
@property (strong, nonatomic) UIDocumentInteractionController* exportController;

@end

@implementation OAGPXItemViewController
{
    OASavingTrackHelper *_savingHelper;
}

- (id)initWithGPXItem:(OAGPX *)gpxItem
{
    self = [super init];
    if (self) {
        _app = [OsmAndApp instance];
        self.gpx = gpxItem;
        NSString *path = [_app.gpxPath stringByAppendingPathComponent:self.gpx.gpxFileName];
        self.doc = [[OAGPXDocument alloc] initWithGpxFile:path];
        
    }
    return self;
}

- (id)initWithCurrentGPXItem
{
    self = [super init];
    if (self) {
        _app = [OsmAndApp instance];
        _savingHelper = [OASavingTrackHelper sharedInstance];
        
        [self updateCurrentGPXData];
        
        _showCurrentTrack = YES;
        
    }
    return self;
}

- (id)initWithCurrentGPXItemNoToolbar
{
    self = [super init];
    if (self) {
        _app = [OsmAndApp instance];
        _savingHelper = [OASavingTrackHelper sharedInstance];
        
        [self updateCurrentGPXData];
        
        _showCurrentTrack = YES;        
    }
    return self;
}

- (void)updateCurrentGPXData
{
    OAGPX* item = [_savingHelper getCurrentGPX];
    item.gpxTitle = OALocalizedString(@"track_recording_name");
    
    self.gpx = item;
    self.doc = (OAGPXDocument*)_savingHelper.currentTrack;
}

- (BOOL)supportFullScreen
{
    return YES;
}

-(BOOL)hasTopToolbar
{
    return YES;
}

- (BOOL)shouldShowToolbar:(BOOL)isViewVisible;
{
    return YES;
}

- (CGFloat)contentHeight
{
    CGFloat h = 0.0;
    for (NSInteger i = 0; i < [_tableView numberOfSections]; i++)
    {
        h += 44.0;
        h += [self.tableView numberOfRowsInSection:i] * 44.0;
    }
    return MIN(160.0, h);
}

- (void)applyLocalization
{
    [self.buttonCancel setTitle:OALocalizedString(@"shared_string_back") forState:UIControlStateNormal];
    [self.buttonCancel setImage:[UIImage imageNamed:@"menu_icon_back"] forState:UIControlStateNormal];
    [self.buttonCancel setTintColor:[UIColor whiteColor]];
    self.buttonCancel.titleEdgeInsets = UIEdgeInsetsMake(0.0, 12.0, 0.0, 0.0);
    self.buttonCancel.imageEdgeInsets = UIEdgeInsetsMake(0.0, -12.0, 0.0, 0.0);
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    dateTimeFormatter = [[NSDateFormatter alloc] init];
    dateTimeFormatter.dateStyle = NSDateFormatterShortStyle;
    dateTimeFormatter.timeStyle = NSDateFormatterMediumStyle;
    
    self.titleView.text = [self.gpx getNiceTitle];
    _startEndTimeExists = self.gpx.startTime > 0 && self.gpx.endTime > 0;
    
    if (self.showCurrentTrack)
    {
        // todo
        //[self.deleteButton removeFromSuperview];
        //[self.exportButton removeFromSuperview];
    }
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    _mapViewController = [OARootViewController instance].mapPanel.mapViewController;
    
    // todo
    //[[OARootViewController instance].mapPanel prepareMapForReuse:self.mapView mapBounds:self.gpx.bounds newAzimuth:0.0 newElevationAngle:90.0 animated:NO];
    
    if (self.showCurrentTrack)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_mapViewController hideTempGpxTrack];
            [_mapViewController showRecGpxTrack];
        });
    }
    else
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_mapViewController showTempGpxTrack:self.gpx.gpxFileName];
        });
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    // todo
    //if (_showTrackOnExit)
    //    [_mapViewController keepTempGpxTrackVisible];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)threeDotsClicked:(id)sender
{
    //
}

- (IBAction)segmentClicked:(id)sender
{
    //
}

- (IBAction)showPointsClicked:(id)sender
{
    // todo
    OAGPXPointListViewController* controller = [[OAGPXPointListViewController alloc] initWithLocationMarks:self.doc.locationMarks];
    [self.navigationController pushViewController:controller animated:YES];
}

- (IBAction)exportClicked:(id)sender
{
    
    NSURL* gpxUrl = [NSURL fileURLWithPath:[_app.gpxPath stringByAppendingPathComponent:_gpx.gpxFileName]];
    _exportController = [UIDocumentInteractionController interactionControllerWithURL:gpxUrl];
    _exportController.UTI = @"net.osmand.gpx";
    _exportController.delegate = self;
    _exportController.name = _gpx.gpxFileName;
    [_exportController presentOptionsMenuFromRect:CGRectZero
                                           inView:self.view
                                         animated:YES];
}

- (IBAction)deleteClicked:(id)sender
{
    UIAlertView* removeAlert = [[UIAlertView alloc] initWithTitle:@"" message:OALocalizedString(@"gpx_remove") delegate:self cancelButtonTitle:OALocalizedString(@"shared_string_no") otherButtonTitles:OALocalizedString(@"shared_string_yes"), nil];
    [removeAlert show];
}

#pragma mark - UIDocumentInteractionControllerDelegate

- (void)documentInteractionControllerDidDismissOptionsMenu:(UIDocumentInteractionController *)controller
{
    if (controller == _exportController)
        _exportController = nil;
}

- (void)documentInteractionControllerDidDismissOpenInMenu:(UIDocumentInteractionController *)controller
{
    if (controller == _exportController)
        _exportController = nil;
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (_startEndTimeExists)
        return 3;
    else
        return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return OALocalizedString(@"gpx_stat");
        case 1:
            if (_startEndTimeExists)
                return OALocalizedString(@"gpx_route_time");
        case 2:
            return OALocalizedString(@"gpx_uphldownhl");
            
        default:
            return @"";
    }
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    switch (section) {
        case 0:
            if (self.gpx.avgSpeed > 0)
                return 3;
            else
                return 2;
        case 1:
            if (_startEndTimeExists)
                return 2;
        case 2:
            return 4;
            
        default:
            return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString* const reusableIdentifierPoint = @"OAGPXDetailsTableViewCell";

    switch (indexPath.section) {
        case 0: // Statistics
        {
            OAGPXDetailsTableViewCell* cell;
            cell = (OAGPXDetailsTableViewCell *)[tableView dequeueReusableCellWithIdentifier:reusableIdentifierPoint];
            if (cell == nil)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAGPXDetailCell" owner:self options:nil];
                cell = (OAGPXDetailsTableViewCell *)[nib objectAtIndex:0];
            }
            
            switch (indexPath.row) {
                case 0: // Distance
                {
                    [cell.textView setText:OALocalizedString(@"gpx_distance")];
                    [cell.descView setText:[_app getFormattedDistance:self.gpx.totalDistance]];
                    cell.iconView.hidden = YES;
                    break;
                }
                case 1: // Waypoints
                {
                    [cell.textView setText:OALocalizedString(@"gpx_waypoints")];
                    [cell.descView setText:[NSString stringWithFormat:@"%d", self.gpx.wptPoints]];
                    if (self.gpx.wptPoints > 0) {
                        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
                        cell.iconView.hidden = NO;
                    } else {
                        cell.iconView.hidden = YES;
                    }
                    break;
                }
                case 2: // Avg Speed
                {
                    [cell.textView setText:OALocalizedString(@"gpx_average_speed")];
                    [cell.descView setText:[_app getFormattedSpeed:self.gpx.avgSpeed]];
                    cell.iconView.hidden = YES;
                    break;
                }
                    
                default:
                    break;
            }
            
            return cell;
        }
        case 1: // Route Time
        if (_startEndTimeExists) {
            OAGPXDetailsTableViewCell* cell;
            cell = (OAGPXDetailsTableViewCell *)[tableView dequeueReusableCellWithIdentifier:reusableIdentifierPoint];
            if (cell == nil)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAGPXDetailCell" owner:self options:nil];
                cell = (OAGPXDetailsTableViewCell *)[nib objectAtIndex:0];
            }
            
            switch (indexPath.row) {
                case 0: // Distance
                {
                    [cell.textView setText:OALocalizedString(@"gpx_start")];
                    [cell.descView setText:[dateTimeFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:self.gpx.startTime]]];
                    cell.iconView.hidden = YES;
                    break;
                }
                case 1: // Avg Speed
                {
                    [cell.textView setText:OALocalizedString(@"gpx_finish")];
                    [cell.descView setText:[dateTimeFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:self.gpx.endTime]]];
                    cell.iconView.hidden = YES;
                    break;
                }
                    
                default:
                    break;
            }
            
            return cell;
        }
        case 2: // Uphills / Downhills
        {
            static NSString* const reusableIdentifierPointElev = @"OAGPXElevationTableViewCell";

            OAGPXElevationTableViewCell* cell;
            cell = (OAGPXElevationTableViewCell *)[tableView dequeueReusableCellWithIdentifier:reusableIdentifierPointElev];
            if (cell == nil)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAGPXElevationCell" owner:self options:nil];
                cell = (OAGPXElevationTableViewCell *)[nib objectAtIndex:0];
            }
            
            switch (indexPath.row) {
                case 0: // Avg Elevation
                {
                    [cell.textView setText:OALocalizedString(@"gpx_avg_elev")];
                    [cell.elev1View setText:[_app getFormattedAlt:self.gpx.avgElevation]];
                    cell.showArrows = NO;
                    cell.showUpDown = NO;
                    break;
                }
                case 1: // Elevation Range
                {
                    [cell.textView setText:OALocalizedString(@"gpx_elev_range")];
                    [cell.elev1View setText:[_app getFormattedAlt:self.gpx.minElevation]];
                    [cell.elev2View setText:[_app getFormattedAlt:self.gpx.maxElevation]];
                    cell.showArrows = NO;
                    cell.showUpDown = YES;
                    break;
                }
                case 2: // Up/Down
                {
                    [cell.textView setText:OALocalizedString(@"gpx_updown")];
                    [cell.elev1View setText:[_app getFormattedAlt:self.gpx.diffElevationDown]];
                    [cell.elev2View setText:[_app getFormattedAlt:self.gpx.diffElevationUp]];
                    cell.showArrows = YES;
                    cell.showUpDown = YES;
                    break;
                }
                case 3: // Uphills Total
                {
                    [cell.textView setText:OALocalizedString(@"gpx_uphills_total")];
                    [cell.elev1View setText:[_app getFormattedAlt:self.gpx.maxElevation - self.gpx.minElevation]];
                    cell.showArrows = NO;
                    cell.showUpDown = NO;
                    break;
                }
                    
                default:
                    break;
            }
            
            return cell;
        }
            
        default:
            break;
    }
    
    return nil;
}


-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0 && indexPath.row == 1 && self.gpx.wptPoints > 0)
        return indexPath;
    else
        return nil;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 32.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.01;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Show Location Points
    if (indexPath.section == 0 && indexPath.row == 1 && self.gpx.wptPoints > 0) {
        [self showPointsClicked:nil];
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
    }
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != alertView.cancelButtonIndex) {
        
        OAAppSettings *settings = [OAAppSettings sharedManager];
        if ([settings.mapSettingVisibleGpx containsObject:self.gpx.gpxFileName]) {
            [settings hideGpx:self.gpx.gpxFileName];
            [_mapViewController hideTempGpxTrack];
            [[[OsmAndApp instance] mapSettingsChangeObservable] notifyEvent];
        }

        [[OAGPXDatabase sharedDb] removeGpxItem:self.gpx.gpxFileName];
        [[OAGPXDatabase sharedDb] save];
        
        // todo
        //[self.navigationController popViewControllerAnimated:YES];
    }
}

@end
