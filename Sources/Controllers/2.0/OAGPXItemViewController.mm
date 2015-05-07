//
//  OAGPXItemViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 16/02/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAGPXItemViewController.h"
#import "OAFavoriteListViewController.h"
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


typedef enum
{
    kGpxItemActionNone = 0,
    kGpxItemActionShowPoints = 1,
    
} EGpxItemAction;


@interface OAGPXItemViewController ()<UIDocumentInteractionControllerDelegate> {

    OsmAndAppInstance _app;
    NSDateFormatter *dateTimeFormatter;
    
    OAMapViewController *_mapViewController;
    
    EGpxItemAction _action;
    BOOL _showTrackOnExit;
    
    BOOL _startEndTimeExists;
    BOOL _hideToolbar;
}

@property (nonatomic) OAGPXDocument *doc;
@property (nonatomic) UIButton *mapButton;
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
        _hideToolbar = YES;
        
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

- (void)viewWillLayoutSubviews
{
    [self updateLayout:self.interfaceOrientation];
}

- (void)updateLayout:(UIInterfaceOrientation)interfaceOrientation
{
    
    CGFloat big;
    CGFloat small;
    
    CGRect rect = self.view.bounds;
    if (rect.size.width > rect.size.height) {
        big = rect.size.width;
        small = rect.size.height;
    } else {
        big = rect.size.height;
        small = rect.size.width;
    }
    
    if (UIInterfaceOrientationIsPortrait(interfaceOrientation)) {
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            
            CGFloat topY = 64.0;
            CGFloat mapHeight = big - topY - self.toolbarView.frame.size.height;
            CGFloat mapWidth = small / 1.7;
            
            self.mapView.frame = CGRectMake(0.0, topY, mapWidth, mapHeight);
            self.mapButton.frame = self.mapView.frame;
            self.tableView.frame = CGRectMake(mapWidth, topY, small - mapWidth, big - self.toolbarView.frame.size.height - topY);
            
        } else {
            
            CGFloat topY = 64.0;
            CGFloat mapWidth = small;
            CGFloat mapHeight = 150.0;
            CGFloat mapBottom = topY + mapHeight;
            
            self.mapView.frame = CGRectMake(0.0, topY, mapWidth, mapHeight);
            self.mapButton.frame = self.mapView.frame;
            self.tableView.frame = CGRectMake(0.0, mapBottom, small, big - self.toolbarView.frame.size.height - mapBottom);
            
        }
        
    } else {
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            
            CGFloat topY = 64.0;
            CGFloat mapHeight = small - topY - self.toolbarView.frame.size.height;
            CGFloat mapWidth = big / 1.5;
            
            self.mapView.frame = CGRectMake(0.0, topY, mapWidth, mapHeight);
            self.mapButton.frame = self.mapView.frame;
            self.tableView.frame = CGRectMake(mapWidth, topY, big - mapWidth, small - self.toolbarView.frame.size.height - topY);
            
        } else {
            
            CGFloat topY = 64.0;
            CGFloat mapHeight = small - topY - self.toolbarView.frame.size.height;
            CGFloat mapWidth = big / 2.0;
            
            self.mapView.frame = CGRectMake(0.0, topY, mapWidth, mapHeight);
            self.mapButton.frame = self.mapView.frame;
            self.tableView.frame = CGRectMake(mapWidth, topY, big - mapWidth, small - self.toolbarView.frame.size.height - topY);
            
        }
        
    }
    
}

- (void)applyLocalization
{
    [_backButton setTitle:OALocalizedString(@"shared_string_back") forState:UIControlStateNormal];

    [_favoritesButtonView setTitle:OALocalizedStringUp(@"favorites") forState:UIControlStateNormal];
    [_gpxButtonView setTitle:OALocalizedStringUp(@"tracks") forState:UIControlStateNormal];
    [OAUtilities layoutComplexButton:self.favoritesButtonView];
    [OAUtilities layoutComplexButton:self.gpxButtonView];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (_hideToolbar)
    {
        self.toolbarView.frame = CGRectZero;
        [self.toolbarView removeFromSuperview];
    }
    
    dateTimeFormatter = [[NSDateFormatter alloc] init];
    dateTimeFormatter.dateStyle = NSDateFormatterShortStyle;
    dateTimeFormatter.timeStyle = NSDateFormatterMediumStyle;
    
    self.mapButton = [[UIButton alloc] initWithFrame:self.mapView.frame];
    [self.mapButton setTitle:@"" forState:UIControlStateNormal];
    [self.mapButton addTarget:self action:@selector(goToGpx) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.mapButton];

    self.titleView.text = self.gpx.gpxTitle;
    _startEndTimeExists = self.gpx.startTime > 0 && self.gpx.endTime > 0;
    
    if (self.showCurrentTrack)
    {
        UIButton *refreshButton = [UIButton buttonWithType:UIButtonTypeSystem];
        refreshButton.frame = _deleteButton.frame;
        refreshButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
        [refreshButton setImage:[UIImage imageNamed:@"ic_update.png"] forState:UIControlStateNormal];
        refreshButton.tintColor = [UIColor whiteColor];
        [refreshButton addTarget:self action:@selector(refreshPressed) forControlEvents:UIControlEventTouchUpInside];
        [self.topView addSubview:refreshButton];

        [self.deleteButton removeFromSuperview];
        [self.exportButton removeFromSuperview];
    }
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    _mapViewController = [OARootViewController instance].mapPanel.mapViewController;
    
    if (_action != kGpxItemActionNone && _mapViewController.parentViewController == self) {
        return;
    }
    
    [[OARootViewController instance].mapPanel prepareMapForReuse:self.mapView mapBounds:self.gpx.bounds newAzimuth:0.0 newElevationAngle:90.0 animated:NO];
    
    if (_action == kGpxItemActionNone)
    {
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
    else
    {
        _action = kGpxItemActionNone;
    }

    _showTrackOnExit = NO;

}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (_action != kGpxItemActionNone) {
        _action = kGpxItemActionNone;
        return;
    }
    
    [[OARootViewController instance].mapPanel doMapReuse:self destinationView:self.mapView];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    if (_action != kGpxItemActionNone)
        return;
    
    if (_showTrackOnExit) {
     
        [_mapViewController keepTempGpxTrackVisible];
        
        [[OARootViewController instance].mapPanel modifyMapAfterReuse:self.gpx.bounds azimuth:0.0 elevationAngle:90.0 animated:YES];

    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)updateMap
{
    [[OARootViewController instance].mapPanel prepareMapForReuse:self.mapView mapBounds:self.gpx.bounds newAzimuth:0.0 newElevationAngle:90.0 animated:NO];
    
    if (self.showCurrentTrack)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_mapViewController showRecGpxTrack];
        });
    }
}

- (IBAction)menuFavoriteClicked:(id)sender {
    OAFavoriteListViewController* favController = [[OAFavoriteListViewController alloc] init];
    [self.navigationController pushViewController:favController animated:NO];
}

- (IBAction)menuGPXClicked:(id)sender {
}


- (IBAction)showPointsClicked:(id)sender
{
    _action = kGpxItemActionShowPoints;
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

- (void)refreshPressed
{
    [self updateCurrentGPXData];
    [self updateMap];
    [_tableView reloadData];
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


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // Show Location Points
    if (indexPath.section == 0 && indexPath.row == 1 && self.gpx.wptPoints > 0) {
        [self showPointsClicked:nil];
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
    }
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (buttonIndex != alertView.cancelButtonIndex) {
        
        OAAppSettings *settings = [OAAppSettings sharedManager];
        if ([settings.mapSettingVisibleGpx containsObject:self.gpx.gpxFileName]) {
            [settings hideGpx:self.gpx.gpxFileName];
            [_mapViewController hideTempGpxTrack];
            [[[OsmAndApp instance] mapSettingsChangeObservable] notifyEvent];
        }

        [[OAGPXDatabase sharedDb] removeGpxItem:self.gpx.gpxFileName];
        [[OAGPXDatabase sharedDb] save];
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)goToGpx
{
    OARootViewController* rootViewController = [OARootViewController instance];
    [rootViewController closeMenuAndPanelsAnimated:YES];
        
    _showTrackOnExit = YES;
    
    [self.navigationController popToRootViewControllerAnimated:YES];
}

@end
