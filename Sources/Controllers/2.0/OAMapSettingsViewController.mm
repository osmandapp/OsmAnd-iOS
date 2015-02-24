//
//  OAMapSettingsViewController.m
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 12.11.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAMapSettingsViewController.h"
#import "OAAppSettings.h"

#import "OASettingsTableViewCell.h"
#import "OASwitchTableViewCell.h"

#import "OAAutoObserverProxy.h"
#import "OANativeUtilities.h"
#import "OAMapRendererView.h"
#import "OAMapViewController.h"
#import "OARootViewController.h"

#import "OAMapSettingsMainScreen.h"
#import "OAMapSettingsMapTypeScreen.h"
#import "OAMapSettingsCategoryScreen.h"
#import "OAMapSettingsParameterScreen.h"
#import "OAMapSettingsSettingScreen.h"
#import "OAMapSettingsGpxScreen.h"

#import <CoreLocation/CoreLocation.h>
#import "OsmAndApp.h"

#include <QtMath>
#include <QStandardPaths>
#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Map/IMapStylesCollection.h>
#include <OsmAndCore/Map/IMapStylesPresetsCollection.h>
#include <OsmAndCore/Map/MapStylePreset.h>
#include <OsmAndCore/Map/OnlineTileSources.h>
#include <OsmAndCore/Map/OnlineRasterMapLayerProvider.h>
#include <OsmAndCore/Map/ObfMapObjectsProvider.h>
#include <OsmAndCore/Map/MapPrimitivesProvider.h>
#include <OsmAndCore/Map/MapRasterLayerProvider_Software.h>
#include <OsmAndCore/Map/MapObjectsSymbolsProvider.h>
#include <OsmAndCore/Map/MapPresentationEnvironment.h>
#include <OsmAndCore/Map/MapPrimitiviser.h>
#include <OsmAndCore/Map/MapMarker.h>
#include <OsmAndCore/Map/MapMarkerBuilder.h>
#include <OsmAndCore/Map/MapMarkersCollection.h>
#include <OsmAndCore/Map/FavoriteLocationsPresenter.h>
#if defined(OSMAND_IOS_DEV)
#   include <OsmAndCore/Map/ObfMapObjectsMetricsLayerProvider.h>
#   include <OsmAndCore/Map/MapPrimitivesMetricsLayerProvider.h>
#   include <OsmAndCore/Map/MapRasterMetricsLayerProvider.h>
#endif // defined(OSMAND_IOS_DEV)

// https://github.com/osmandapp/OsmAnd-resources/blob/master/rendering_styles/default.render.xml




@interface OAMapSettingsViewController () {

    BOOL isAppearFirstTime;
    BOOL isOnlineMapSource;
    OAAutoObserverProxy* _lastMapSourceChangeObserver;
}

@property (nonatomic) NSArray* tableData;
@property (nonatomic) OsmAndAppInstance app;
@property (nonatomic) EMapSettingsScreen settingsScreen;
@property (nonatomic) id<OAMapSettingsScreen> screenObj;

@property (nonatomic) id customParam;
@property (nonatomic) UIButton *mapButton;

@end

@implementation OAMapSettingsViewController

@synthesize screenObj, customParam;

- (instancetype)init
{
    self = [super init];
    if (self) {
        _settingsScreen = EMapSettingsScreenMain;
        [self commonInit];
    }
    return self;
}

-(id)initWithSettingsScreen:(EMapSettingsScreen)settingsScreen
{
    self = [super init];
    if (self) {
        _settingsScreen = settingsScreen;
        [self commonInit];
    }
    return self;
}

-(id)initWithSettingsScreen:(EMapSettingsScreen)settingsScreen param:(id)param
{
    self = [super init];
    if (self) {
        _settingsScreen = settingsScreen;
        customParam = param;
        [self commonInit];
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
            
            CGFloat topY = 0.0;
            CGFloat mapWidth = small;
            CGFloat mapHeight = 200.0;
            CGFloat mapBottom = topY + mapHeight;
            CGFloat scrollBottom = mapBottom + self.mapTypeScrollView.bounds.size.height;
            
            self.mapView.frame = CGRectMake(0.0, topY, mapWidth, mapHeight);
            self.mapButton.frame = CGRectMake(0.0, topY + 64.0, mapWidth, mapHeight - 64.0);
            if (isOnlineMapSource) {
                self.tableView.frame = CGRectMake(0.0, mapBottom, small, big - mapBottom);
                self.mapTypeScrollView.hidden = YES;
            } else {
                self.mapTypeScrollView.frame = CGRectMake(0.0, mapBottom, small, self.mapTypeScrollView.bounds.size.height);
                self.tableView.frame = CGRectMake(0.0, scrollBottom, small, big - scrollBottom);
                self.mapTypeScrollView.hidden = NO;
            }
            
        }
        
    } else {
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            
            
        } else {
            
            CGFloat topY = 0.0;
            CGFloat mapHeight = small - topY;
            CGFloat mapWidth = 190.0;
            CGFloat scrollBottom = 64.0 + self.mapTypeScrollView.bounds.size.height;
            
            self.mapView.frame = CGRectMake(0.0, topY, mapWidth, mapHeight);
            self.mapButton.frame = CGRectMake(0.0, topY + 64.0, mapWidth, mapHeight - 64.0);
            if (isOnlineMapSource) {
                self.tableView.frame = CGRectMake(mapWidth, 64.0, big - mapWidth, small - 64.0);
                self.mapTypeScrollView.hidden = YES;
            } else {
                self.mapTypeScrollView.frame = CGRectMake(mapWidth, 64.0, big - mapWidth, self.mapTypeScrollView.bounds.size.height);
                self.tableView.frame = CGRectMake(mapWidth, scrollBottom, big - mapWidth, small - scrollBottom);
                self.mapTypeScrollView.hidden = NO;
            }
            
        }
        
    }
    
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self setupView];
    
    CGRect f = self.mapView.frame;
    self.mapButton = [[UIButton alloc] initWithFrame:CGRectMake(f.origin.x, f.origin.y + 64.0, f.size.width, f.size.height)];
    [self.mapButton setTitle:@"" forState:UIControlStateNormal];
    [self.mapButton addTarget:self action:@selector(goToMap) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.mapButton];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (isAppearFirstTime)
        isAppearFirstTime = NO;
    else
        [screenObj setupView];
    
    OAGpxBounds bounds;
    bounds.topLeft = CLLocationCoordinate2DMake(DBL_MAX, DBL_MAX);
    [[OARootViewController instance].mapPanel prepareMapForReuse:self.mapView mapBounds:bounds newAzimuth:0.0 newElevationAngle:90.0 animated:NO];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [[OARootViewController instance].mapPanel doMapReuse:self destinationView:self.mapView];
    
}


-(IBAction)backButtonClicked:(id)sender
{
    if (_lastMapSourceChangeObserver) {
        [_lastMapSourceChangeObserver detach];
        _lastMapSourceChangeObserver = nil;
    }
    
    [super backButtonClicked:sender];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)commonInit {
    
    isAppearFirstTime = YES;
    self.app = [OsmAndApp instance];
    
    _lastMapSourceChangeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                             withHandler:@selector(onLastMapSourceChanged)
                                                              andObserve:_app.data.lastMapSourceChangeObservable];

    
}

- (void)goToMap
{
    OARootViewController* rootViewController = [OARootViewController instance];
    [rootViewController closeMenuAndPanelsAnimated:YES];
    [self.navigationController popToRootViewControllerAnimated:YES];
}

-(void)setupView {
    
    switch (_settingsScreen) {
        case EMapSettingsScreenMain:
            if (!screenObj)
                screenObj = [[OAMapSettingsMainScreen alloc] initWithTable:self.tableView viewController:self];
            break;
        case EMapSettingsScreenGpx:
            if (!screenObj)
                screenObj = [[OAMapSettingsGpxScreen alloc] initWithTable:self.tableView viewController:self];
            break;
        case EMapSettingsScreenMapType:
            if (!screenObj)
                screenObj = [[OAMapSettingsMapTypeScreen alloc] initWithTable:self.tableView viewController:self];
            break;
        case EMapSettingsScreenCategory:
            if (!screenObj)
                screenObj = [[OAMapSettingsCategoryScreen alloc] initWithTable:self.tableView viewController:self param:customParam];
            break;
        case EMapSettingsScreenParameter:
            if (!screenObj)
                screenObj = [[OAMapSettingsParameterScreen alloc] initWithTable:self.tableView viewController:self param:customParam];
            break;
        case EMapSettingsScreenSetting:
            if (!screenObj)
                screenObj = [[OAMapSettingsSettingScreen alloc] initWithTable:self.tableView viewController:self param:customParam];
            break;
            
        default:
            break;
    }

    OAMapSource* mapSource = _app.data.lastMapSource;
    const auto resource = _app.resourcesManager->getResource(QString::fromNSString(mapSource.resourceId));
    
    BOOL _isOnlineMapSourcePrev = isOnlineMapSource;
    if (resource->type == OsmAnd::ResourcesManager::ResourceType::OnlineTileSources) {
        
        isOnlineMapSource = YES;
        
    } else {
        
        isOnlineMapSource = NO;
        OsmAnd::MapStylePreset::Type mapStyle = [OAMapSettingsViewController variantToMapStyle:_app.data.lastMapSource.variant];
        [self setupMapTypeButtons:[OAMapSettingsViewController mapStyleToTag:mapStyle]];
        
    }
    
    screenObj.isOnlineMapSource = isOnlineMapSource;
    
    
    if (!self.tableView.dataSource)
        self.tableView.dataSource = screenObj;
    if (!self.tableView.delegate)
        self.tableView.delegate = screenObj;
    if (!self.tableView.tableFooterView)
        self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    [screenObj setupView];

    self.titleView.text = screenObj.title;
    
    if (_isOnlineMapSourcePrev != isOnlineMapSource)
        [self.view setNeedsLayout];
    
}


-(void)setupMapTypeButtons:(int)tag {
    
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
    
    switch (tag) {
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

- (IBAction)changeMapTypeButtonClicked:(id)sender {
    
    int tag = ((UIButton*)sender).tag;
    
    OAMapSource* mapSource = _app.data.lastMapSource;
    NSString *name = mapSource.name;
    const auto resource = _app.resourcesManager->getResource(QString::fromNSString(mapSource.resourceId));
    NSString* resourceId = resource->id.toNSString();
    
    // Get the style
    const auto& mapStyle = std::static_pointer_cast<const OsmAnd::ResourcesManager::MapStyleMetadata>(resource->metadata)->mapStyle;
    const auto& presets = self.app.resourcesManager->mapStylesPresetsCollection->getCollectionFor(mapStyle->name);
    
    OsmAnd::MapStylePreset::Type selectedType = [OAMapSettingsViewController tagToMapStyle:tag];

    BOOL foundPreset = NO;
    for(const auto& preset : presets)
    {
        if (preset->type == selectedType) {
            
            OAMapSource* mapSource = [[OAMapSource alloc] initWithResource:resourceId andVariant:preset->name.toNSString() name:name];
            _app.data.lastMapSource = mapSource;
            
            foundPreset = YES;
            break;
        }
    }
    
    if (!foundPreset) {
        [self setupMapTypeButtons:0];
    }
    
}

- (void)onLastMapSourceChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setupView];
    });
}

#pragma mark - Orientation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (NSUInteger) supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAllButUpsideDown;
}
    
- (UIInterfaceOrientation) preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}

+(OsmAnd::MapStylePreset::Type)tagToMapStyle:(int)type {
    OsmAnd::MapStylePreset::Type mapStyle = OsmAnd::MapStylePreset::Type::General;
    if (type == 1) {
        mapStyle = OsmAnd::MapStylePreset::Type::Car;
    } else if (type == 2) {
        mapStyle = OsmAnd::MapStylePreset::Type::Pedestrian;
    } else if (type == 3) {
        mapStyle = OsmAnd::MapStylePreset::Type::Bicycle;
    }
    return mapStyle;
}

+(OsmAnd::MapStylePreset::Type)variantToMapStyle:(NSString*)variant {
    OsmAnd::MapStylePreset::Type mapStyle = OsmAnd::MapStylePreset::Type::General;
    if ([variant isEqualToString:@"type_car"]) {
        mapStyle = OsmAnd::MapStylePreset::Type::Car;
    } else if ([variant isEqualToString:@"type_pedestrian"]) {
        mapStyle = OsmAnd::MapStylePreset::Type::Pedestrian;
    } else if ([variant isEqualToString:@"type_bicycle"]) {
        mapStyle = OsmAnd::MapStylePreset::Type::Bicycle;
    }
    return mapStyle;
}

+(int)mapStyleToTag:(OsmAnd::MapStylePreset::Type)mapStyle {
    int type = 0;
    if (mapStyle == OsmAnd::MapStylePreset::Type::Car) {
        type = 1;
    } else if (mapStyle == OsmAnd::MapStylePreset::Type::Pedestrian) {
        type = 2;
    } else if (mapStyle == OsmAnd::MapStylePreset::Type::Bicycle) {
        type = 3;
    }
    return type;
}


        
@end
