//
//  OAMapSettingsViewController.m
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 12.11.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAMapSettingsViewController.h"
#import "OASettingsTableViewCell.h"
#import "OASwitchTableViewCell.h"

#import "OAMapRendererView.h"

#import "OAAutoObserverProxy.h"
#import "OANativeUtilities.h"



#include <OsmAndCore/Map/FavoriteLocationsPresenter.h>

#if defined(OSMAND_IOS_DEV)
typedef NS_ENUM(NSInteger, OAVisualMetricsMode)
{
    OAVisualMetricsModeOff = 0,
    OAVisualMetricsModeBinaryMapData,
    OAVisualMetricsModeBinaryMapPrimitives,
    OAVisualMetricsModeBinaryMapRasterize
};
#endif // defined(OSMAND_IOS_DEV)

@interface OAMapSettingsViewController ()

@property NSArray* tableData;
@property OsmAndAppInstance app;


@property(readonly) OAObservable* stateObservable;
@property(readonly) OAObservable* settingsObservable;
@property(readonly) OAObservable* azimuthObservable;
@property(readonly) OAObservable* zoomObservable;
@property(readonly) OAObservable* framePreparedObservable;


@property(readonly) CGFloat displayDensityFactor;

#if defined(OSMAND_IOS_DEV)
@property(nonatomic) BOOL hideStaticSymbols;
@property(nonatomic) OAVisualMetricsMode visualMetricsMode;

@property(nonatomic) BOOL forceDisplayDensityFactor;
@property(nonatomic) CGFloat forcedDisplayDensityFactor;
#endif // defined(OSMAND_IOS_DEV)

@end

@implementation OAMapSettingsViewController

    NSObject* _rendererSync;
    BOOL _mapSourceInvalidated;
    OAAutoObserverProxy* _lastMapSourceChangeObserver;
    OAAutoObserverProxy* _appModeObserver;

    OAAutoObserverProxy* _locationServicesStatusObserver;
    OAAutoObserverProxy* _locationServicesUpdateObserver;

    OAAutoObserverProxy* _stateObserver;
    OAAutoObserverProxy* _settingsObserver;
    OAAutoObserverProxy* _framePreparedObserver;

    OAAutoObserverProxy* _layersConfigurationObserver;


    // Favorites presenter
    std::shared_ptr<OsmAnd::FavoriteLocationsPresenter> _favoritesPresenter;


-(id)init {
    self = [super init];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupView];
    
    
    
    // LoadView
    NSLog(@"Creating Map Renderer view...");

    // Inflate map renderer view
    OAMapRendererView* mapView = [[OAMapRendererView alloc] init];
    self.mapView = mapView;
    mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    mapView.contentScaleFactor = [[UIScreen mainScreen] scale];
    [_stateObserver observe:mapView.stateObservable];
    [_settingsObserver observe:mapView.settingsObservable];
    [_framePreparedObserver observe:mapView.framePreparedObservable];
    
    // Update layers
    [self updateLayers];
    //
    
    

    
    
    
    
    
    // Tell view to create context
    mapView.userInteractionEnabled = YES;
    mapView.multipleTouchEnabled = YES;
    [mapView createContext];
    
    // Adjust map-view target, zoom, azimuth and elevation angle to match last viewed
    mapView.target31 = OsmAnd::PointI(_app.data.mapLastViewedState.target31.x,
                                      _app.data.mapLastViewedState.target31.y);
    mapView.zoom = _app.data.mapLastViewedState.zoom;
    mapView.azimuth = _app.data.mapLastViewedState.azimuth;
    mapView.elevationAngle = _app.data.mapLastViewedState.elevationAngle;
    
    // Mark that map source is no longer valid
    _mapSourceInvalidated = YES;
    
    
    
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)commonInit {
    self.app = [OsmAndApp instance];
    _rendererSync = [[NSObject alloc] init];
    
    _lastMapSourceChangeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                             withHandler:@selector(onLastMapSourceChanged)
                                                              andObserve:_app.data.lastMapSourceChangeObservable];

    
    self.app.resourcesManager->localResourcesChangeObservable.attach((__bridge const void*)self,
                                                                     [self]
                                                                     (const OsmAnd::ResourcesManager* const resourcesManager,
                                                                      const QList< QString >& added,
                                                                      const QList< QString >& removed,
                                                                      const QList< QString >& updated)
                                                                     {
                                                                         QList< QString > merged;
                                                                         merged << added << removed << updated;
                                                                         [self onLocalResourcesChanged:merged];
                                                                     });
    
    _appModeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                 withHandler:@selector(onAppModeChanged)
                                                  andObserve:_app.appModeObservable];
    
    _locationServicesStatusObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                                withHandler:@selector(onLocationServicesStatusChanged)
                                                                 andObserve:_app.locationServices.statusObservable];
    _locationServicesUpdateObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                                withHandler:@selector(onLocationServicesUpdate)
                                                                 andObserve:_app.locationServices.updateObserver];
    
    _stateObservable = [[OAObservable alloc] init];
    _settingsObservable = [[OAObservable alloc] init];
    _azimuthObservable = [[OAObservable alloc] init];
    _zoomObservable = [[OAObservable alloc] init];
    _framePreparedObservable = [[OAObservable alloc] init];

    _stateObserver = [[OAAutoObserverProxy alloc] initWith:self
                                               withHandler:@selector(onMapRendererStateChanged:withKey:)];
    _settingsObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                  withHandler:@selector(onMapRendererSettingsChanged:withKey:)];
    _layersConfigurationObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                             withHandler:@selector(onLayersConfigurationChanged)
                                                              andObserve:_app.data.mapLayersConfiguration.changeObservable];
    _framePreparedObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                       withHandler:@selector(onMapRendererFramePrepared)];
    
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidEnterBackground:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillEnterForeground:)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];

    
//    // Create favorites presenter
    _favoritesPresenter.reset(new OsmAnd::FavoriteLocationsPresenter(_app.favoritesCollection,
                                                                     [OANativeUtilities skBitmapFromPngResource:@"favorite_location_pin_marker_icon"]));
    
#if defined(OSMAND_IOS_DEV)
    _hideStaticSymbols = NO;
    _visualMetricsMode = OAVisualMetricsModeOff;
    _forceDisplayDensityFactor = NO;
    _forcedDisplayDensityFactor = self.displayDensityFactor;
#endif // defined(OSMAND_IOS_DEV)
    
}


-(void)onLastMapSourceChanged {
    NSLog(@"onLastMapSourceChanged_Event");
}
- (void)onLocalResourcesChanged:(const QList< QString >&)ids
{
    NSLog(@"onLocalResourcesChanged_Event");
}
-(void)onAppModeChanged {
    NSLog(@"onAppModeChanged_Event");
}
-(void)onLocationServicesStatusChanged {
    NSLog(@"onLocationServicesStatusChanged_Event");
}
-(void)onLocationServicesUpdate {
//    NSLog(@"onLocationServicesUpdate");
}
- (void)onMapRendererStateChanged:(id)observer withKey:(id)key {

    if (![self isViewLoaded])
        return;
    
    OAMapRendererView* mapView = (OAMapRendererView*)self.mapView;
    
    switch ([key unsignedIntegerValue])
    {
        case OAMapRendererViewStateEntryAzimuth:
            [_azimuthObservable notifyEventWithKey:nil andValue:[NSNumber numberWithFloat:mapView.azimuth]];
            _app.data.mapLastViewedState.azimuth = mapView.azimuth;
            break;
        case OAMapRendererViewStateEntryZoom:
            [_zoomObservable notifyEventWithKey:nil andValue:[NSNumber numberWithFloat:mapView.zoom]];
            _app.data.mapLastViewedState.zoom = mapView.zoom;
            break;
        case OAMapRendererViewStateEntryElevationAngle:
            _app.data.mapLastViewedState.elevationAngle = mapView.elevationAngle;
            break;
        case OAMapRendererViewStateEntryTarget:
            OsmAnd::PointI newTarget31 = mapView.target31;
            Point31 newTarget31_converted;
            newTarget31_converted.x = newTarget31.x;
            newTarget31_converted.y = newTarget31.y;
            _app.data.mapLastViewedState.target31 = newTarget31_converted;
            break;
    }
    
    [_stateObservable notifyEventWithKey:key];
    
    
}
- (void)onMapRendererSettingsChanged:(id)observer withKey:(id)key {
    NSLog(@"onMapRendererSettingsChanged_Event");
}
- (void)onLayersConfigurationChanged {
    NSLog(@"onLayersConfigurationChanged_Event");
}
- (void)onMapRendererFramePrepared {
    NSLog(@"onMapRendererFramePrepared_Event");
}
- (void)applicationDidEnterBackground:(UIApplication*)application {
    NSLog(@"applicationDidEnterBackground_Event");
}
- (void)applicationWillEnterForeground:(UIApplication*)application {
    NSLog(@"applicationWillEnterForeground_Event");
}


- (void)updateLayers
{
    if (![self isViewLoaded])
        return;
    
    OAMapRendererView* mapView = (OAMapRendererView*)self.mapView;
    
    @synchronized(_rendererSync)
    {
        if ([_app.data.mapLayersConfiguration isLayerVisible:kFavoritesLayerId])
            [mapView addKeyedSymbolsProvider:_favoritesPresenter];
        else
            [mapView removeKeyedSymbolsProvider:_favoritesPresenter];
    }
}






- (void)viewWillAppear:(BOOL)animated
{
    // Resume rendering
    OAMapRendererView* mapView = (OAMapRendererView*)self.mapView;
//    [mapView resumeRendering];
    
    // Update map source (if needed)
    if (_mapSourceInvalidated)
    {
//        [self updateCurrentMapSource];
        
        _mapSourceInvalidated = NO;
    }

}




















-(void)setupView {
    [self.mapTypeScrollView setContentSize:CGSizeMake(404, 70)];
    [self setupMapTypeButtons:0];
    
    [self.tableView setDelegate:self];
    [self.tableView setDataSource:self];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    [self setupTableData];
}

-(void)setupMapTypeButtons:(int)selectedMapType {

    UIColor* buttonColor = [UIColor colorWithRed:83.0/255.0 green:109.0/255.0 blue:254.0/255.0 alpha:1.0];
    
    self.mapTypeButtonView.layer.cornerRadius = 5;
    self.mapTypeButtonCar.layer.cornerRadius = 5;
    self.mapTypeButtonWalk.layer.cornerRadius = 5;
    self.mapTypeButtonBike.layer.cornerRadius = 5;

    [self.mapTypeButtonView setImage:[UIImage imageNamed:@"btn_map_type_icon_view.png"] forState:UIControlStateNormal];
    [self.mapTypeButtonCar setImage:[UIImage imageNamed:@"btn_map_type_icon_car.png"] forState:UIControlStateNormal];
    [self.mapTypeButtonWalk setImage:[UIImage imageNamed:@"btn_map_type_icon_walk.png"] forState:UIControlStateNormal];
    [self.mapTypeButtonBike setImage:[UIImage imageNamed:@"btn_map_type_icon_bike.png"] forState:UIControlStateNormal];
    
    [self.mapTypeButtonView setTitleColor:buttonColor forState:UIControlStateNormal];
    [self.mapTypeButtonCar setTitleColor:buttonColor forState:UIControlStateNormal];
    [self.mapTypeButtonWalk setTitleColor:buttonColor forState:UIControlStateNormal];
    [self.mapTypeButtonBike setTitleColor:buttonColor forState:UIControlStateNormal];
    
    [self.mapTypeButtonView setBackgroundColor:[UIColor clearColor]];
    [self.mapTypeButtonCar setBackgroundColor:[UIColor clearColor]];
    [self.mapTypeButtonWalk setBackgroundColor:[UIColor clearColor]];
    [self.mapTypeButtonBike setBackgroundColor:[UIColor clearColor]];
    
    self.mapTypeButtonView.layer.borderColor = [buttonColor CGColor];
    self.mapTypeButtonView.layer.borderWidth = 1;
    self.mapTypeButtonCar.layer.borderColor = [buttonColor CGColor];
    self.mapTypeButtonCar.layer.borderWidth = 1;
    self.mapTypeButtonWalk.layer.borderColor = [buttonColor CGColor];
    self.mapTypeButtonWalk.layer.borderWidth = 1;
    self.mapTypeButtonBike.layer.borderColor = [buttonColor CGColor];
    self.mapTypeButtonBike.layer.borderWidth = 1;
    
    switch (selectedMapType) {
        case 0:
            [self.mapTypeButtonView setBackgroundColor:buttonColor];
            [self.mapTypeButtonView setImage:[UIImage imageNamed:@"btn_map_type_icon_view_selected.png"] forState:UIControlStateNormal];
            [self.mapTypeButtonView setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            break;
        case 1:
            [self.mapTypeButtonCar setBackgroundColor:buttonColor];
            [self.mapTypeButtonCar setImage:[UIImage imageNamed:@"btn_map_type_icon_car_selected.png"] forState:UIControlStateNormal];
            [self.mapTypeButtonCar setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            break;
        case 2:
            [self.mapTypeButtonWalk setBackgroundColor:buttonColor];
            [self.mapTypeButtonWalk setImage:[UIImage imageNamed:@"btn_map_type_icon_walk_selected.png"] forState:UIControlStateNormal];
            [self.mapTypeButtonWalk setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            break;
        case 3:
            [self.mapTypeButtonBike setBackgroundColor:buttonColor];
            [self.mapTypeButtonBike setImage:[UIImage imageNamed:@"btn_map_type_icon_bike_selected.png"] forState:UIControlStateNormal];
            [self.mapTypeButtonBike setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            break;
        default:
            break;
    }
}

-(void)setupTableData {
    self.tableData = @[@{@"groupName": @"Show on map",
                         @"cells": @[
                                 @{@"name": @"POI",
                                   @"value": @"",
                                   @"type": @"OASettingsCell"},
                                 @{@"name": @"GPX",
                                   @"value": @"",
                                   @"type": @"OASettingsCell"},
                                 @{@"name": @"Favorite",
                                   @"value": @"",
                                   @"type": @"OASwitchCell"},
                                 @{@"name": @"Transport",
                                   @"value": @"",
                                   @"type": @"OASettingsCell"}
                                 ]
                         },
                       @{@"groupName": @"Map type",
                         @"cells": @[
                                 @{@"name": @"Map type",
                                   @"value": @"UniRS",
                                   @"type": @"OASettingsCell"}
                                 ],
                         },
                       @{@"groupName": @"Map style",
                         @"cells": @[
                                 @{@"name": @"Details",
                                   @"value": @"",
                                   @"type": @"OASettingsCell"},
                                 @{@"name": @"Routes",
                                   @"value": @"",
                                   @"type": @"OASettingsCell"},
                                 @{@"name": @"Other",
                                   @"value": @"",
                                   @"type": @"OASettingsCell"}

                                 ],
                         }
                       ];
}

- (IBAction)changeMapTypeButtonClicked:(id)sender {
    int type = ((UIButton*)sender).tag;
    [self setupMapTypeButtons:type];
}


#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.tableData count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [((NSDictionary*)[self.tableData objectAtIndex:section]) objectForKey:@"groupName"];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return [((NSArray*)[((NSDictionary*)[self.tableData objectAtIndex:section]) objectForKey:@"cells"]) count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary* data = (NSDictionary*)[((NSArray*)[((NSDictionary*)[self.tableData objectAtIndex:indexPath.section]) objectForKey:@"cells"]) objectAtIndex:indexPath.row];

    UITableViewCell* outCell = nil;
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[data objectForKey:@"type"]  owner:self options:nil];
    if ([[data objectForKey:@"type"] isEqualToString:@"OASettingsCell"]) {
        OASettingsTableViewCell* cell = (OASettingsTableViewCell *)[nib objectAtIndex:0];
        if (cell) {
            [cell.textView setText: [data objectForKey:@"name"]];
            [cell.descriptionView setText: [data objectForKey:@"value"]];
        }
        outCell = cell;
    } else if ([[data objectForKey:@"type"] isEqualToString:@"OASwitchCell"]) {
        OASwitchTableViewCell* cell = (OASwitchTableViewCell *)[nib objectAtIndex:0];
        if (cell) {
            [cell.textView setText: [data objectForKey:@"name"]];
        }
        outCell = cell;
    }
    
    return outCell;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    
}





@end
