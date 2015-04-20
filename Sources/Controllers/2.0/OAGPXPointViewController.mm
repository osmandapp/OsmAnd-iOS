//
//  OAGPXPointViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 19/02/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAGPXPointViewController.h"
#import <CoreLocation/CoreLocation.h>
#import "OAAutoObserverProxy.h"

#import "OAMapRendererViewProtocol.h"
#import "OAObservable.h"
#import "OsmAndApp.h"

#import "OARootViewController.h"
#import "OANativeUtilities.h"
#import "OAFavoriteListViewController.h"
#import "OAGPXPointTableViewCell.h"
#import "OAMapViewController.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>
#include "Localization.h"

#define kDefaultGpxZoom 15.0f

typedef enum
{
    kGpxPointActionNone = 0,
} EGpxPointAction;

@interface OAGPXPointViewController () {
    
    OsmAnd::PointI _newTarget31;

    OAMapViewController *_mapViewController;

    EGpxPointAction _action;
        
    BOOL _showPointOnExit;
}

@property (strong, nonatomic) OAAutoObserverProxy* locationServicesUpdateObserver;
@property (nonatomic) UIButton *mapButton;

@end

@implementation OAGPXPointViewController

- (id)initWithWptItem:(OAGpxWptItem*)wptItem
{
    self = [super init];
    if (self) {
        self.wptItem = wptItem;
        _action = kGpxPointActionNone;
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
            
            
        } else {
            
            CGFloat topY = 64.0;
            CGFloat mapWidth = small;
            CGFloat mapHeight = 166.0;
            CGFloat mapBottom = topY + mapHeight;
            
            self.mapView.frame = CGRectMake(0.0, topY, mapWidth, mapHeight);
            self.mapButton.frame = self.mapView.frame;
            self.distanceDirectionHolderView.frame = CGRectMake(mapWidth/2.0 - 110.0/2.0, mapBottom - 19.0, 110.0, 40.0);
            self.tableView.frame = CGRectMake(0.0, mapBottom, small, big - self.toolbarView.frame.size.height - mapBottom);
            
        }
        
    } else {
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            
            
        } else {
            
            CGFloat topY = 64.0;
            CGFloat mapHeight = small - topY - self.toolbarView.frame.size.height;
            CGFloat mapWidth = big / 2.0;
            CGFloat mapBottom = topY + mapHeight;
            
            self.mapView.frame = CGRectMake(0.0, topY, mapWidth, mapHeight);
            self.mapButton.frame = self.mapView.frame;
            self.distanceDirectionHolderView.frame = CGRectMake(mapWidth/2.0 - 110.0/2.0, mapBottom - 49.0, 110.0, 40.0);
            self.tableView.frame = CGRectMake(mapWidth, topY, big - mapWidth, small - self.toolbarView.frame.size.height - topY);
            
        }
        
    }
    
}

- (void)applyLocalization
{
    _titleView.text = OALocalizedString(@"gpx_point");
    [_btnBack setTitle:OALocalizedString(@"shared_string_back") forState:UIControlStateNormal];
    [_favoritesButtonView setTitle:OALocalizedStringUp(@"favorites") forState:UIControlStateNormal];
    [_gpxButtonView setTitle:OALocalizedStringUp(@"tracks") forState:UIControlStateNormal];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.distanceDirectionHolderView setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"onmap_placeholder"]]];

    self.mapButton = [[UIButton alloc] initWithFrame:self.mapView.frame];
    [self.mapButton setTitle:@"" forState:UIControlStateNormal];
    [self.mapButton addTarget:self action:@selector(goToPoint) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.mapButton];
}

-(void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    _mapViewController = [OARootViewController instance].mapPanel.mapViewController;

    OsmAndAppInstance app = [OsmAndApp instance];
    self.locationServicesUpdateObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                                    withHandler:@selector(updateDistanceAndDirection)
                                                                     andObserve:app.locationServices.updateObserver];    
    if (_action != kGpxPointActionNone) {
        return;
    }
    
    const OsmAnd::LatLon latLon(self.wptItem.point.position.latitude, self.wptItem.point.position.longitude);
    OsmAnd::PointI target31 = OsmAnd::Utilities::convertLatLonTo31(latLon);

    [[OARootViewController instance].mapPanel prepareMapForReuse:[OANativeUtilities convertFromPointI:target31] zoom:kDefaultGpxZoom newAzimuth:0.0 newElevationAngle:90.0 animated:NO];
    
    _showPointOnExit = NO;
    
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (_action != kGpxPointActionNone) {
        _action = kGpxPointActionNone;
        return;
    }
    
    [[OARootViewController instance].mapPanel doMapReuse:self destinationView:self.mapView];
    
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if (self.locationServicesUpdateObserver) {
        [self.locationServicesUpdateObserver detach];
        self.locationServicesUpdateObserver = nil;
    }
    
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    if (_action != kGpxPointActionNone)
        return;
    
    if (_showPointOnExit) {
        
        [_mapViewController keepTempGpxTrackVisible];
        
        [[OARootViewController instance].mapPanel modifyMapAfterReuse:[OANativeUtilities convertFromPointI:_newTarget31] zoom:kDefaultGpxZoom azimuth:0.0 elevationAngle:90.0 animated:YES];
        
        // Get location of the gesture
        CGPoint touchPoint = CGPointMake(self.view.bounds.size.width / 2.0, self.view.bounds.size.height / 2.0);
        touchPoint.x *= _mapView.contentScaleFactor;
        touchPoint.y *= _mapView.contentScaleFactor;
        
        CLLocationCoordinate2D latLon = self.wptItem.point.position;

        [_mapViewController showContextPinMarker:latLon.latitude longitude:latLon.longitude];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationSetTargetPoint
                                                            object: self
                                                          userInfo:@{@"title" : self.wptItem.point.name,
                                                                     @"lat": [NSNumber numberWithDouble:latLon.latitude],
                                                                     @"lon": [NSNumber numberWithDouble:latLon.longitude],
                                                                     @"touchPoint.x": [NSNumber numberWithFloat:touchPoint.x],
                                                                     @"touchPoint.y": [NSNumber numberWithFloat:touchPoint.y]}];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (IBAction)menuFavoriteClicked:(id)sender {
    OAFavoriteListViewController* favController = [[OAFavoriteListViewController alloc] init];
    [self.navigationController pushViewController:favController animated:NO];
}

- (IBAction)menuGPXClicked:(id)sender {
}

-(IBAction)backButtonClicked:(id)sender {
    [super backButtonClicked:sender];
}

- (void)updateDistanceAndDirection
{
    OsmAndAppInstance app = [OsmAndApp instance];
    // Obtain fresh location and heading
    CLLocation* newLocation = app.locationServices.lastKnownLocation;
    CLLocationDirection newHeading = app.locationServices.lastKnownHeading;
    CLLocationDirection newDirection = (newLocation.speed >= 1 /* 3.7 km/h */ && newLocation.course >= 0.0f) ? newLocation.course : newHeading;
    
    const auto distance = OsmAnd::Utilities::distance(newLocation.coordinate.longitude,
                                                      newLocation.coordinate.latitude,
                                                      self.wptItem.point.position.longitude, self.wptItem.point.position.latitude);
    
    self.wptItem.distance = [app getFormattedDistance:distance];
    self.wptItem.distanceMeters = distance;
    CGFloat itemDirection = [app.locationServices radiusFromBearingToLocation:[[CLLocation alloc] initWithLatitude:self.wptItem.point.position.latitude longitude:self.wptItem.point.position.longitude]];
    self.wptItem.direction = OsmAnd::Utilities::normalizedAngleDegrees(itemDirection - newDirection) * (M_PI / 180);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.itemDistance setText:self.wptItem.distance];
        self.itemDirection.transform = CGAffineTransformMakeRotation(self.wptItem.direction);
    });
}

- (void)goToPoint
{
    OARootViewController* rootViewController = [OARootViewController instance];
    [rootViewController closeMenuAndPanelsAnimated:YES];
    
    // Go to wpt location
    const OsmAnd::LatLon latLon(self.wptItem.point.position.latitude, self.wptItem.point.position.longitude);
    _newTarget31 = OsmAnd::Utilities::convertLatLonTo31(latLon);
    
    _showPointOnExit = YES;
    
    [self.navigationController popToRootViewControllerAnimated:YES];
}


#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"";
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGSize constraint = CGSizeMake(tableView.frame.size.width - 30.0, 20000.0);
    CGSize size = [self.wptItem.point.desc boundingRectWithSize:constraint
                                                 options:NSStringDrawingUsesLineFragmentOrigin
                                              attributes:@{NSFontAttributeName : [UIFont fontWithName:@"Avenir-Medium" size:12.0]}
                                                 context:nil].size;
    
    return MAX(size.height + 56.0, 44.0);
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation))
        return 34.0;
     else
        return 0.1;
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    static NSString* const reusableIdentifierPoint = @"OAGPXPointTableViewCell";
    
    OAGPXPointTableViewCell* cell;
    cell = (OAGPXPointTableViewCell *)[self.tableView dequeueReusableCellWithIdentifier:reusableIdentifierPoint];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAGPXPointCell" owner:self options:nil];
        cell = (OAGPXPointTableViewCell *)[nib objectAtIndex:0];
    }
    
    if (cell) {

        [cell.textView setText:self.wptItem.point.name];
        [cell.descView setText:self.wptItem.point.desc];
    }
    
    return cell;
}


#pragma mark - UITableViewDelegate


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
}

@end
    
