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
#import "OAMapSettingsSubviewController.h"
#import "OAMapSourcesViewController.h"

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


#define kElevationMinAngle 30.0f
#define kMapModePositionTrackingDefaultZoom 15.0f
#define kMapModePositionTrackingDefaultElevationAngle 90.0f
#define kMapModeFollowDefaultZoom 18.0f
#define kMapModeFollowDefaultElevationAngle kElevationMinAngle
#define kOneSecondAnimatonTime 1.0f
#define kLocationServicesAnimationKey reinterpret_cast<OsmAnd::MapAnimator::Key>(2)

typedef enum
{
    EMapSettingsActionNone = 0,
    EMapSettingsActionGpx,
    EMapSettingsActionMapType,
    EMapSettingsActionDetails,
    EMapSettingsActionRoutes,
    EMapSettingsActionHide,
    
} EMapSettingsAction;

@interface OAMapStyle : NSObject
@property std::shared_ptr<const OsmAnd::UnresolvedMapStyle> mapStyle;
@end
@implementation OAMapStyle
@end

@interface OAMapStylePreset : NSObject
@property OAMapSource* mapSource;
@property std::shared_ptr<const OsmAnd::MapStylePreset> mapStylePreset;
@property std::shared_ptr<const OsmAnd::UnresolvedMapStyle> mapStyle;
@end
@implementation OAMapStylePreset
@end


@interface OAMapSettingsViewController () {
    
    EMapSettingsAction _action;
    
}

@property NSArray* tableData;
@property OsmAndAppInstance app;

@end

@implementation OAMapSettingsViewController


-(id)init {
    self = [super init];
    if (self) {
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
            self.mapTypeScrollView.frame = CGRectMake(0.0, mapBottom, small, self.mapTypeScrollView.bounds.size.height);
            self.tableView.frame = CGRectMake(0.0, scrollBottom, small, big - scrollBottom);
            
        }
        
    } else {
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            
            
        } else {
            
            CGFloat topY = 0.0;
            CGFloat mapHeight = small - topY;
            CGFloat mapWidth = 190.0;
            CGFloat scrollBottom = 64.0 + self.mapTypeScrollView.bounds.size.height;
            
            self.mapView.frame = CGRectMake(0.0, topY, mapWidth, mapHeight);
            self.mapTypeScrollView.frame = CGRectMake(mapWidth, 64.0, big - mapWidth, self.mapTypeScrollView.bounds.size.height);
            self.tableView.frame = CGRectMake(mapWidth, scrollBottom, big - mapWidth, small - scrollBottom);
            
        }
        
    }
    
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self setupView];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (_action != EMapSettingsActionNone)
        return;
    
    OAGpxBounds bounds;
    bounds.topLeft = CLLocationCoordinate2DMake(DBL_MAX, DBL_MAX);
    
    [[OARootViewController instance].mapPanel prepareMapForReuse:self.mapView mapBounds:bounds newAzimuth:0.0 newElevationAngle:90.0 animated:NO];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (_action != EMapSettingsActionNone) {
        _action = EMapSettingsActionNone;
        return;
    }
    
    [[OARootViewController instance].mapPanel doMapReuse:self destinationView:self.mapView];
    
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if (_action != EMapSettingsActionNone)
        return;
    
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];

    if (_action != EMapSettingsActionNone)
        return;

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)commonInit {
    
    self.app = [OsmAndApp instance];
}


-(void)setupView {
    
    //[self.mapTypeScrollView setContentSize:CGSizeMake(404, 70)];
    
    [self setupMapTypeButtons:self.app.data.lastMapSource.type];
    
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
    self.tableData = @[@{@"groupName": @"Show on Map",
                         @"cells": @[
                                 @{@"name": @"Favorite",
                                   @"value": @"",
                                   @"type": @"OASwitchCell"},
                                 @{@"name": @"GPX",
                                   @"value": @"",
                                   @"type": @"OASettingsCell"}
                                 ]
                         },
                       @{@"groupName": @"Map Type",
                         @"cells": @[
                                 @{@"name": @"Map Type",
                                   @"value": _app.data.lastMapSourceName,
                                   @"type": @"OASettingsCell"}
                                 ],
                         },
                       @{@"groupName": @"Map Style",
                         @"cells": @[
                                 @{@"name": @"Details",
                                   @"value": @"",
                                   @"type": @"OASettingsCell"},
                                 @{@"name": @"Routes",
                                   @"value": @"",
                                   @"type": @"OASettingsCell"},
                                 @{@"name": @"Hide",
                                   @"value": @"",
                                   @"type": @"OASettingsCell"}

                                 ],
                         }
                       ];
}

- (IBAction)changeMapTypeButtonClicked:(id)sender {
    
    int type = ((UIButton*)sender).tag;
    [self setupMapTypeButtons:type];
    
    
    OAMapSource* mapSource = _app.data.lastMapSource;
    const auto resource = self.app.resourcesManager->getResource(QString::fromNSString(mapSource.resourceId));
    NSString* resourceId = resource->id.toNSString();
    
    // Get the style
    const auto& mapStyle = std::static_pointer_cast<const OsmAnd::ResourcesManager::MapStyleMetadata>(resource->metadata)->mapStyle;
    OAMapStyle* mapStyleItem = [[OAMapStyle alloc] init];
    mapStyleItem.mapStyle = mapStyle;
    const auto& presets = self.app.resourcesManager->mapStylesPresetsCollection->getCollectionFor(mapStyle->name);
    
    OsmAnd::MapStylePreset::Type selectedType = [OAMapSettingsViewController typeToMapStyle:type];

    for(const auto& preset : presets)
    {
        if (preset->type != selectedType)
            continue;
        OAMapStylePreset* item = [[OAMapStylePreset alloc] init];
        item.mapSource = [[OAMapSource alloc] initWithResource:resourceId
                                                    andVariant:preset->name.toNSString()];
        item.mapStylePreset = preset;
        item.mapStyle = mapStyle;
        
        _app.data.lastMapSource = item.mapSource;
    }
    
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
    if ([[data objectForKey:@"type"] isEqualToString:@"OASettingsCell"]) {
        
        static NSString* const identifierCell = @"OASettingsTableViewCell";
        OASettingsTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OASettingsCell" owner:self options:nil];
            cell = (OASettingsTableViewCell *)[nib objectAtIndex:0];
        }

        if (cell) {
            [cell.textView setText: [data objectForKey:@"name"]];
            [cell.descriptionView setText: [data objectForKey:@"value"]];
        }
        outCell = cell;
        
    } else if ([[data objectForKey:@"type"] isEqualToString:@"OASwitchCell"]) {
        
        static NSString* const identifierCell = @"OASwitchTableViewCell";
        OASwitchTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OASwitchCell" owner:self options:nil];
            cell = (OASwitchTableViewCell *)[nib objectAtIndex:0];
        }

        if (cell) {
            [cell.textView setText: [data objectForKey:@"name"]];
            
            if (indexPath.section == 0 && indexPath.row == 0) {
                OAAppSettings* settings = [OAAppSettings sharedManager];
                [cell.switchView setOn:settings.mapSettingShowFavorites];
                [cell.switchView addTarget:self action:@selector(showFavoriteChanged) forControlEvents:UIControlEventValueChanged];
            }

        }
        outCell = cell;
    }
    
    return outCell;
}

- (void)showFavoriteChanged
{
    OASwitchTableViewCell *cell = (OASwitchTableViewCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    if (cell) {
        OAAppSettings* settings = [OAAppSettings sharedManager];
        [settings setMapSettingShowFavorites:cell.switchView.isOn];
    }
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    switch (indexPath.section) {
            
        case 1: // Map Type
        {
            _action = EMapSettingsActionMapType;

            OAMapSourcesViewController* resourcesViewController = [[OAMapSourcesViewController alloc] initWithNibName:@"OAMapSourcesViewController" bundle:nil];
            [self.navigationController pushViewController:resourcesViewController animated:YES];

            break;
        }
            
        case 2: // Map Style
        {
            OAMapSettingsSubviewController* settingsSubviewController;
            
            switch (indexPath.row) {
                case 0:
                    settingsSubviewController = [[OAMapSettingsSubviewController alloc] initWithSettingsType:kMapSettingsScreenDetails];
                    _action = EMapSettingsActionDetails;
                    break;
                case 1:
                    settingsSubviewController = [[OAMapSettingsSubviewController alloc] initWithSettingsType:kMapSettingsScreenRoutes];
                    _action = EMapSettingsActionRoutes;
                    break;
                case 2:
                    settingsSubviewController = [[OAMapSettingsSubviewController alloc] initWithSettingsType:kMapSettingsScreenHide];
                    _action = EMapSettingsActionHide;
                    break;
                default:
                    break;
            }
            
            if (settingsSubviewController) {
                [self.navigationController pushViewController:settingsSubviewController animated:YES];
            }
            
            break;
        }
            
        default:
            break;
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
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

+(OsmAnd::MapStylePreset::Type)typeToMapStyle:(int)type {
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
    if ([variant isEqualToString:@""]) {
        mapStyle = OsmAnd::MapStylePreset::Type::Car;
    } else if ([variant isEqualToString:@""]) {
        mapStyle = OsmAnd::MapStylePreset::Type::Pedestrian;
    } else if ([variant isEqualToString:@""]) {
        mapStyle = OsmAnd::MapStylePreset::Type::Bicycle;
    }
    return mapStyle;
}

+(int)mapStyleToType:(OsmAnd::MapStylePreset::Type)mapStyle {
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
