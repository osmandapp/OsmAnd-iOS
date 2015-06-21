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
#import "PXAlertView.h"

#import "OAMapRendererView.h"
#import "OARootViewController.h"
#import "OANativeUtilities.h"
#import "Localization.h"
#import "OAUtilities.h"
#import "OASavingTrackHelper.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>

typedef enum
{
    kSegmentStatistics = 0,
    kSegmentWaypoints
    
} OAGpxSegmentType;

@interface OAGPXItemViewController ()<UIDocumentInteractionControllerDelegate> {

    OsmAndAppInstance _app;
    NSDateFormatter *dateTimeFormatter;
    
    OAMapViewController *_mapViewController;
    
    BOOL _startEndTimeExists;
    OAGpxSegmentType _segmentType;
}

@property (nonatomic) OAGPXDocument *doc;
@property (strong, nonatomic) UIDocumentInteractionController* exportController;

@end

@implementation OAGPXItemViewController
{
    OASavingTrackHelper *_savingHelper;
}

@synthesize editing = _editing;
@synthesize wasEdited = _wasEdited;
@synthesize showingKeyboard = _showingKeyboard;

- (id)initWithGPXItem:(OAGPX *)gpxItem
{
    self = [super init];
    if (self) {
        _app = [OsmAndApp instance];
        _segmentType = kSegmentStatistics;
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
        _segmentType = kSegmentStatistics;
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


- (void)cancelPressed
{
    [_mapViewController hideTempGpxTrack];

    if (self.delegate)
        [self.delegate btnCancelPressed];
}

- (void)okPressed
{
    if (self.delegate)
        [self.delegate btnOkPressed];
}

- (BOOL)preHide
{
    [_mapViewController keepTempGpxTrackVisible];
    return YES;
}

-(BOOL)supportEditing
{
    return YES;
}

- (void)activateEditing
{
    _editing = YES;
    [self updateWaypointsButtons];
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

- (id)getTargetObj
{
    return self.gpx;
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
    
    _mapViewController = [OARootViewController instance].mapPanel.mapViewController;

    dateTimeFormatter = [[NSDateFormatter alloc] init];
    dateTimeFormatter.dateStyle = NSDateFormatterShortStyle;
    dateTimeFormatter.timeStyle = NSDateFormatterMediumStyle;
    
    self.titleView.text = [self.gpx getNiceTitle];
    _startEndTimeExists = self.gpx.startTime > 0 && self.gpx.endTime > 0;
    
    self.buttonUpdate.frame = self.buttonMore.frame;
    self.buttonEdit.frame = self.buttonMore.frame;
    
    [self applySegmentType];
    
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)applySegmentType
{
    switch (_segmentType)
    {
        case kSegmentStatistics:
        {
            self.buttonEdit.hidden = YES;
            if (self.showCurrentTrack)
            {
                self.buttonMore.hidden = YES;
                self.buttonUpdate.hidden = NO;
            }
            else
            {
                self.buttonMore.hidden = NO;
                self.buttonUpdate.hidden = YES;
            }
            break;
        }
        case kSegmentWaypoints:
        {
            self.buttonUpdate.hidden = YES;
            [self updateWaypointsButtons];
            break;
        }
            
        default:
            break;
    }
}

- (void)updateWaypointsButtons
{
    self.buttonEdit.hidden = self.editing;
    self.buttonMore.hidden = !self.editing;
}

- (IBAction)threeDotsClicked:(id)sender
{
    [PXAlertView showAlertWithTitle:[self.gpx getNiceTitle]
                            message:nil
                        cancelTitle:OALocalizedString(@"shared_string_cancel")
                        otherTitles:@[OALocalizedString(@"shared_string_remove"), OALocalizedString(@"gpx_export")]
                        otherImages:@[@"track_clear_data.png", @"export_items.png"]
                         completion:^(BOOL cancelled, NSInteger buttonIndex) {
                             if (!cancelled)
                             {
                                 if (buttonIndex == 0)
                                     [self deleteClicked:nil];
                                 else
                                     [self exportClicked:nil];
                             }
                         }];
}

- (void)updateMap
{
    [[OARootViewController instance].mapPanel displayGpxOnMap:self.gpx];
}

- (IBAction)updateClicked:(id)sender
{
    [self updateCurrentGPXData];
    [self updateMap];
    [_tableView reloadData];
    if (self.delegate)
        [self.delegate contentChanged];
}

- (IBAction)editClicked:(id)sender
{
    //
}

- (IBAction)segmentClicked:(id)sender
{
    OAGpxSegmentType newSegmentType = (OAGpxSegmentType)self.segmentView.selectedSegmentIndex;
    if (_segmentType == newSegmentType)
        return;
    
    _editing = NO;
    _segmentType = newSegmentType;
        
    [self applySegmentType];
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
                                           inView:self.navController.view
                                         animated:YES];
}

- (IBAction)deleteClicked:(id)sender
{
    [PXAlertView showAlertWithTitle:OALocalizedString(@"gpx_remove")
                            message:nil
                        cancelTitle:OALocalizedString(@"shared_string_no")
                         otherTitle:OALocalizedString(@"shared_string_yes")
                         otherImage:nil
                         completion:^(BOOL cancelled, NSInteger buttonIndex) {
                             if (!cancelled)
                             {
                                 dispatch_async(dispatch_get_main_queue(), ^{
                                     
                                     OAAppSettings *settings = [OAAppSettings sharedManager];
                                     if ([settings.mapSettingVisibleGpx containsObject:self.gpx.gpxFileName]) {
                                         [settings hideGpx:self.gpx.gpxFileName];
                                         [_mapViewController hideTempGpxTrack];
                                         [[[OsmAndApp instance] mapSettingsChangeObservable] notifyEvent];
                                     }
                                     
                                     [[OAGPXDatabase sharedDb] removeGpxItem:self.gpx.gpxFileName];
                                     [[OAGPXDatabase sharedDb] save];
                                     
                                     [self okPressed];
                                 });
                             }
                         }];
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
        return 2;
    else
        return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0:
            if (_startEndTimeExists)
                return OALocalizedString(@"gpx_route_time");
        case 1:
            return OALocalizedString(@"gpx_uphldownhl");
            
        default:
            return @"";
    }
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    switch (section) {
        case 0:
            if (_startEndTimeExists)
                return 2;
        case 1:
            return 4;
            
        default:
            return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString* const reusableIdentifierPoint = @"OAGPXDetailsTableViewCell";

    switch (indexPath.section)
    {
        case 0: // Route Time
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
        case 1: // Uphills / Downhills
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

@end
