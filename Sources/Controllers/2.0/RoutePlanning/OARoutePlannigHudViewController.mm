//
//  OARoutePlannigHudViewController.m
//  OsmAnd
//
//  Created by Paul on 10/16/20.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OARoutePlannigHudViewController.h"
#import "OAAppSettings.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"
#import "OAScrollableTableToolBarView.h"
#import "OAColors.h"
#import "OANativeUtilities.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"
#import "OAMapLayers.h"
#import "OAMeasurementToolLayer.h"
#import "OAMeasurementEditingContext.h"
#import "Localization.h"
#import "OARoutePlanningScrollableView.h"
#import "OAMeasurementCommandManager.h"
#import "OAAddPointCommand.h"
#import "OAIconTextDescButtonTableViewCell.h"
#import "OAGPXDocumentPrimitives.h"
#import "OALocationServices.h"

#define VIEWPORT_SHIFTED_SCALE 1.5f
#define VIEWPORT_NON_SHIFTED_SCALE 1.0f

@interface OARoutePlannigHudViewController () <OADraggableViewDelegate, OARoutePlanningViewDelegate, UITableViewDelegate, UITableViewDataSource, OAMeasurementLayerDelegate>

@property (strong, nonatomic) IBOutlet OARoutePlanningScrollableView *scrollableView;
@property (weak, nonatomic) IBOutlet UIImageView *centerImageView;
@property (weak, nonatomic) IBOutlet UIView *closeButtonContainerView;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;
@property (weak, nonatomic) IBOutlet UIView *doneButtonContainerView;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;
@property (weak, nonatomic) IBOutlet UILabel *titleView;

@end

@implementation OARoutePlannigHudViewController
{
    OAAppSettings *_settings;
    OsmAndAppInstance _app;
    
    OAMapPanelViewController *_mapPanel;
    OAMeasurementToolLayer *_layer;
    
    OAMeasurementEditingContext *_editingContext;
    
    CGFloat _cachedYViewPort;
}

- (instancetype) init
{
    self = [super initWithNibName:@"OARoutePlannigHudViewController"
                           bundle:nil];
    if (self)
    {
        _app = OsmAndApp.instance;
        _settings = [OAAppSettings sharedManager];
        _mapPanel = OARootViewController.instance.mapPanel;
        _layer = _mapPanel.mapViewController.mapLayers.routePlanningLayer;
        // TODO: port later public void openPlanRoute()
        _editingContext = [[OAMeasurementEditingContext alloc] init];
        
        _layer.editingCtx = _editingContext;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _scrollableView.delegate = self;
    _scrollableView.routePlanningDelegate = self;
    _scrollableView.tableView.delegate = self;
    _scrollableView.tableView.dataSource = self;
    [self updateDistancePointsText];
    [_scrollableView show:YES state:EOADraggableMenuStateInitial onComplete:nil];
//    BOOL isNight = [OAAppSettings sharedManager].nightMode;
    [_mapPanel setTopControlsVisible:NO customStatusBarStyle:UIStatusBarStyleLightContent];
    [_mapPanel targetSetBottomControlsVisible:YES menuHeight:_scrollableView.getViewHeight animated:YES];
    _centerImageView.image = [UIImage imageNamed:@"ic_ruler_center.png"];
    [self changeCenterOffset:[_scrollableView getViewHeight]];
    
    _closeButtonContainerView.layer.cornerRadius = 12.;
    _doneButtonContainerView.layer.cornerRadius = 12.;
    
    [_closeButton setImage:[[UIImage imageNamed:@"ic_navbar_close"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    _closeButton.imageView.tintColor = UIColor.whiteColor;
    
    [_doneButton setTitle:OALocalizedString(@"shared_string_done") forState:UIControlStateNormal];
    _titleView.text = OALocalizedString(@"plan_route");
    
    _layer.delegate = self;
    
    [self adjustMapViewPort];
}

- (void) changeCenterOffset:(CGFloat)contentHeight
{
    _centerImageView.center = CGPointMake(self.view.frame.size.width * 0.5,
                                    self.view.frame.size.height * 0.5 - contentHeight / 2);
}

- (void)adjustMapViewPort
{
    OAMapRendererView *mapView = [OARootViewController instance].mapPanel.mapViewController.mapView;
    if ([OAUtilities isLandscape])
    {
        mapView.viewportXScale = VIEWPORT_SHIFTED_SCALE;
        mapView.viewportYScale = VIEWPORT_NON_SHIFTED_SCALE;
    }
    else
    {
        mapView.viewportXScale = VIEWPORT_NON_SHIFTED_SCALE;
        mapView.viewportYScale = _scrollableView.getViewHeight / DeviceScreenHeight;
    }
}

- (void) restoreMapViewPort
{
    OAMapRendererView *mapView = [OARootViewController instance].mapPanel.mapViewController.mapView;
    if (mapView.viewportXScale != VIEWPORT_NON_SHIFTED_SCALE)
        mapView.viewportXScale = VIEWPORT_NON_SHIFTED_SCALE;
    if (mapView.viewportYScale != _cachedYViewPort)
        mapView.viewportYScale = _cachedYViewPort;
}

- (void) updateDistancePointsText
{
    if (_layer != nil)
    {
        NSString *distanceStr = [_app getFormattedDistance:_editingContext.getRouteDistance];
        _scrollableView.titleLabel.text = [NSString stringWithFormat:@"%@, %@ %ld", distanceStr, OALocalizedString(@"points_count"), _editingContext.getPointsCount];
    }
}


- (IBAction)closePressed:(id)sender
{
    [_scrollableView hide:YES duration:.2 onComplete:^{
        [self restoreMapViewPort];
        [OARootViewController.instance.mapPanel hideScrollableHudViewController];
        _layer.editingCtx = nil;
        [_layer resetLayer];
    }];
}

- (IBAction)donePressed:(id)sender
{
}

#pragma mark - OADraggableViewDelegate

- (void)onViewSwippedDown
{
    [_scrollableView hide:YES duration:.2 onComplete:^{
        [self restoreMapViewPort];
        [OARootViewController.instance.mapPanel hideScrollableHudViewController];
    }];
}

- (void)onViewHeightChanged:(CGFloat)height
{
    [self changeCenterOffset:height];
    [_mapPanel targetSetBottomControlsVisible:YES menuHeight:height animated:YES];
    [self adjustMapViewPort];
}

#pragma mark - OARoutePlanningViewDelegate

- (void) onPointsListChanged
{
    [_scrollableView.tableView reloadData];
    [self updateDistancePointsText];
}

- (BOOL) addCenterPoint
{
    BOOL added = NO;
    if (_layer != nil) {
        added = [_editingContext.commandManager execute:[[OAAddPointCommand alloc] initWithLayer:_layer center:YES]];
        [self onPointsListChanged];
    }
    return added;
}

- (void)onAddPointPressed
{
    [self addCenterPoint];
}

- (void)onOptionsPressed
{

}

- (void)onRedoPressed
{
    [_editingContext.commandManager redo];
    [self onPointsListChanged];
}

- (void)onUndoPressed
{
    [_editingContext.commandManager undo];
    [self onPointsListChanged];
}

#pragma mark - UITableViewDataSource

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.01;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _editingContext.getPointsCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* const identifierCell = @"OAIconTextDescButtonCell";
    OAIconTextDescButtonCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAIconTextDescButtonTableViewCell" owner:self options:nil];
        cell = (OAIconTextDescButtonCell *)[nib objectAtIndex:0];
    }
    cell.titleLabel.text = [NSString stringWithFormat:OALocalizedString(@"point_num"), indexPath.row + 1];
    
    OAGpxTrkPt *point1 = _editingContext.getPoints[indexPath.row];
    CLLocation *location1 = [[CLLocation alloc] initWithLatitude:point1.getLatitude longitude:point1.getLongitude];
    if (indexPath.row == 0)
    {
        CLLocation *currentLocation = _app.locationServices.lastKnownLocation;
        if (currentLocation)
        {
            double azimuth = [location1 bearingTo:currentLocation];
            cell.descLabel.text = [NSString stringWithFormat:@"%@ • %@ • %@", OALocalizedString(@"gpx_start"), [_app getFormattedDistance:[location1 distanceFromLocation:currentLocation]], [OsmAndApp.instance getFormattedAzimuth:azimuth]];
        }
        else
        {
            cell.descLabel.text = OALocalizedString(@"gpx_start");
        }
    }
    else
    {
        OAGpxTrkPt *point2 = indexPath.row == 0 && _editingContext.getPointsCount > 1 ? _editingContext.getPoints[indexPath.row + 1] : _editingContext.getPoints[indexPath.row - 1];
        CLLocation *location2 = [[CLLocation alloc] initWithLatitude:point2.getLatitude longitude:point2.getLongitude];
        double azimuth = [location1 bearingTo:location2];
        cell.descLabel.text = [NSString stringWithFormat:@"%@ • %@", [_app getFormattedDistance:[location1 distanceFromLocation:location2]], [OsmAndApp.instance getFormattedAzimuth:azimuth]];
    }
    return cell;
}

#pragma mark - OAMeasurementLayerDelegate

- (void)onMeasue:(double)distance bearing:(double)bearing
{
    dispatch_async(dispatch_get_main_queue(), ^{
        _scrollableView.descriptionLabel.text = [NSString stringWithFormat:@"%@ • %@", [_app getFormattedDistance:distance], [OsmAndApp.instance getFormattedAzimuth:bearing]];
    });
}

@end
