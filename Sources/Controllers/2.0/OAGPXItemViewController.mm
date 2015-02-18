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

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>


typedef enum
{
    kGpxItemActionNone = 0,
    kGpxItemActionShowPoints = 1,
    
} EGpxItemAction;


@interface OAGPXItemViewController () {

    OsmAndAppInstance _app;
    NSDateFormatter *dateTimeFormatter;
    
    OAMapViewController *_mapViewController;
    
    EGpxItemAction _action;
    BOOL _showTrackOnExit;
}

@property (nonatomic) OAGPXDocument *doc;

@end

@implementation OAGPXItemViewController

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

- (void)viewWillLayoutSubviews
{
    [self updateLayout:self.interfaceOrientation];
}

- (void)updateLayout:(UIInterfaceOrientation)interfaceOrientation
{
    
    CGFloat big;
    CGFloat small;
    
    CGRect rect = [[UIScreen mainScreen] bounds];
    if (rect.size.width > rect.size.height) {
        big = rect.size.width;
        small = rect.size.height;
    } else {
        big = rect.size.height;
        small = rect.size.width;
    }
    
    if (UIInterfaceOrientationIsPortrait(interfaceOrientation)) {
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            
            
        } else {
            
            CGFloat topY = 64.0;
            CGFloat mapWidth = small;
            CGFloat mapHeight = 150.0;
            CGFloat mapBottom = topY + mapHeight;
            
            self.mapView.frame = CGRectMake(0.0, topY, mapWidth, mapHeight);
            self.tableView.frame = CGRectMake(0.0, mapBottom, small, big - self.toolbarView.frame.size.height - mapBottom);
            
        }
        
    } else {
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            
            
        } else {
            
            CGFloat topY = 64.0;
            CGFloat mapHeight = small - topY - self.toolbarView.frame.size.height;
            CGFloat mapWidth = 220.0;
            
            self.mapView.frame = CGRectMake(0.0, topY, mapWidth, mapHeight);
            self.tableView.frame = CGRectMake(mapWidth, topY, big - mapWidth, small - self.toolbarView.frame.size.height - topY);
            
        }
        
    }
    
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    dateTimeFormatter = [[NSDateFormatter alloc] init];
    dateTimeFormatter.dateStyle = NSDateFormatterShortStyle;
    dateTimeFormatter.timeStyle = NSDateFormatterMediumStyle;
    
    self.titleView.text = self.gpx.gpxTitle;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (_action != kGpxItemActionNone) {
        return;
    }
    
    _mapViewController = [OARootViewController instance].mapPanel.mapViewController;

    double left = DBL_MAX;
    double top;
    double right;
    double bottom;

    for (OAGpxWpt *p in self.doc.locationMarks) {
        if (left == DBL_MAX) {
            left = p.position.longitude;
            right = p.position.longitude;
            top = p.position.latitude;
            bottom = p.position.latitude;
            
        } else {
            
            left = MIN(left, p.position.longitude);
            right = MAX(right, p.position.longitude);
            top = MAX(top, p.position.latitude);
            bottom = MIN(bottom, p.position.latitude);
        }
    }
    
    double clat = bottom / 2.0 + top / 2.0;
    double clon = left / 2.0 + right / 2.0;
    
    const OsmAnd::LatLon latLon(clat, clon);
    OsmAnd::PointI p = OsmAnd::Utilities::convertLatLonTo31(latLon);
    /*
    double zoom = 7.0;
    double tileY = OsmAnd::Utilities::getTileNumberY(zoom, clat);
    NSLog(@"metersPerTile 7 = %f", OsmAnd::Utilities::getMetersPerTileUnit(zoom, tileY, 1));
    zoom = 8.0;
    tileY = OsmAnd::Utilities::getTileNumberY(zoom, clat);
    NSLog(@"metersPerTile 8 = %f", OsmAnd::Utilities::getMetersPerTileUnit(zoom, tileY, 1));
    zoom = 9.0;
    tileY = OsmAnd::Utilities::getTileNumberY(zoom, clat);
    NSLog(@"metersPerTile 9 = %f", OsmAnd::Utilities::getMetersPerTileUnit(zoom, tileY, 1));
    zoom = 10.0;
    tileY = OsmAnd::Utilities::getTileNumberY(zoom, clat);
    NSLog(@"metersPerTile 10 = %f", OsmAnd::Utilities::getMetersPerTileUnit(zoom, tileY, 1));
    */
    
    [[OARootViewController instance].mapPanel prepareMapForReuse:[OANativeUtilities convertFromPointI:p] zoom:9.0 newAzimuth:0.0 newElevationAngle:90.0 animated:NO];
    
    NSString *path = [_app.gpxPath stringByAppendingPathComponent:self.gpx.gpxFileName];
    [_mapViewController showGpxTrack:path];

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
    
    if (_action != kGpxItemActionShowPoints)
        return;
    
    if (_showTrackOnExit) {
        
        const OsmAnd::LatLon latLon(self.gpx.locationStart.position.latitude, self.gpx.locationStart.position.longitude);
        OsmAnd::PointI p = OsmAnd::Utilities::convertLatLonTo31(latLon);
        
        [[OARootViewController instance].mapPanel modifyMapAfterReuse:[OANativeUtilities convertFromPointI:p] zoom:15.0 azimuth:0.0 elevationAngle:90.0 animated:YES];
        
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)menuFavoriteClicked:(id)sender {
    OAFavoriteListViewController* favController = [[OAFavoriteListViewController alloc] init];
    [self.navigationController pushViewController:favController animated:NO];
}

- (IBAction)menuGPXClicked:(id)sender {
}


- (IBAction)showPointsClicked:(id)sender
{
    OAGPXPointListViewController* controller = [[OAGPXPointListViewController alloc] initWithLocationMarks:self.doc.locationMarks];
    [self.navigationController pushViewController:controller animated:YES];
}

- (IBAction)deleteClicked:(id)sender
{
    UIAlertView* removeAlert = [[UIAlertView alloc] initWithTitle:@"" message:@"Remove GPX?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
    [removeAlert show];
}


#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return @"Statistics";
        case 1:
            return @"Route Time";
        case 2:
            return @"Uphills/Downhills";
            
        default:
            return @"";
    }
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    switch (section) {
        case 0:
            return 3;
        case 1:
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
                    [cell.textView setText:@"Distance"];
                    [cell.descView setText:[_app.locationFormatter stringFromDistance:self.gpx.totalDistance]];
                    cell.iconView.hidden = YES;
                    break;
                }
                case 1: // Waypoints
                {
                    [cell.textView setText:@"Waypoints"];
                    [cell.descView setText:[NSString stringWithFormat:@"%d", self.gpx.wptPoints]];
                    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
                    cell.iconView.hidden = NO;
                    break;
                }
                case 2: // Avg Speed
                {
                    [cell.textView setText:@"Average Speed"];
                    [cell.descView setText:[_app.locationFormatter stringFromSpeed:self.gpx.avgSpeed]];
                    cell.iconView.hidden = YES;
                    break;
                }
                    
                default:
                    break;
            }
            
            return cell;
        }
        case 1: // Route Time
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
                    [cell.textView setText:@"Start"];
                    [cell.descView setText:[dateTimeFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:self.gpx.startTime]]];
                    cell.iconView.hidden = YES;
                    break;
                }
                case 1: // Avg Speed
                {
                    [cell.textView setText:@"Finish"];
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
                    [cell.textView setText:@"Average Elevation"];
                    [cell.elev1View setText:[_app.locationFormatter stringFromDistance:self.gpx.avgElevation]];
                    cell.showArrows = NO;
                    cell.showUpDown = NO;
                    break;
                }
                case 1: // Elevation Range
                {
                    [cell.textView setText:@"Elevation Range"];
                    [cell.elev1View setText:[_app.locationFormatter stringFromDistance:self.gpx.minElevation]];
                    [cell.elev2View setText:[_app.locationFormatter stringFromDistance:self.gpx.maxElevation]];
                    cell.showArrows = NO;
                    cell.showUpDown = YES;
                    break;
                }
                case 2: // Up/Down
                {
                    [cell.textView setText:@"Up/Down"];
                    [cell.elev1View setText:[_app.locationFormatter stringFromDistance:self.gpx.diffElevationDown]];
                    [cell.elev2View setText:[_app.locationFormatter stringFromDistance:self.gpx.diffElevationUp]];
                    cell.showArrows = YES;
                    cell.showUpDown = YES;
                    break;
                }
                case 3: // Uphills Total
                {
                    [cell.textView setText:@"Uphills Total"];
                    [cell.elev1View setText:[_app.locationFormatter stringFromDistance:self.gpx.totalDistanceMoving]];
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
    if (indexPath.section == 0 && indexPath.row == 1)
        return indexPath;
    else
        return nil;
}

#pragma mark - UITableViewDelegate


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // Show Location Points
    if (indexPath.section == 0 && indexPath.row == 1) {
        [self showPointsClicked:nil];
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
    }
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (buttonIndex != alertView.cancelButtonIndex) {
        [[OAGPXDatabase sharedDb] removeGpxItem:self.gpx.gpxFileName];
        [[OAGPXDatabase sharedDb] save];
        [self.navigationController popViewControllerAnimated:YES];
    }
}

@end
