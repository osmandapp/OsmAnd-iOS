//
//  OAFavoriteItemViewController.m
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 07.11.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAFavoriteItemViewController.h"

#import "OsmAndApp.h"
#import "OAAppData.h"
#import "OAMapRendererView.h"
#import "OALog.h"
#import "OAFavoriteGroupViewController.h"
#import "OAFavoriteColorViewController.h"
#import "OADefaultFavorite.h"
#import "OARootViewController.h"
#import "OANativeUtilities.h"

#include <OsmAndCore.h>
#include <OsmAndCore/IFavoriteLocation.h>
#include <OsmAndCore/Utilities.h>
#include "Localization.h"


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


@interface OAFavoriteItemViewController ()
@end

@implementation OAFavoriteItemViewController

- (id)initWithFavoriteItem:(OAFavoriteItem*)favorite {
    self = [super init];
    if (self) {
        self.favorite = favorite;
        self.newFavorite = NO;
    }
    return self;
}

- (id)initWithLocation:(CLLocationCoordinate2D)location andTitle:(NSString*)formattedLocation {
    self = [super init];
    if (self) {
        OsmAndAppInstance app = [OsmAndApp instance];
        
        self.favorite = nil;
        self.location = location;
        self.newFavorite = YES;
        [self.favoriteNameButton setTitle:formattedLocation forState:UIControlStateNormal];

        // Create favorite
        OsmAnd::PointI locationPoint;
        locationPoint.x = OsmAnd::Utilities::get31TileNumberX(location.longitude);
        locationPoint.y = OsmAnd::Utilities::get31TileNumberY(location.latitude);
        
        QString title = QString::fromNSString(formattedLocation);
        
        UIColor* color_ = (UIColor*)[UIColor blackColor];
        OsmAnd::FColorARGB color;
        [color_ getRed:&color.r
                 green:&color.g
                  blue:&color.b
                 alpha:&color.a];
        
        OAFavoriteItem* fav = [[OAFavoriteItem alloc] init];
        fav.favorite = app.favoritesCollection->createFavoriteLocation(locationPoint,
                                                                       title,
                                                                       QString::null,
                                                                       OsmAnd::FColorRGB(color));
        self.favorite = fav;
        [app saveFavoritesToPermamentStorage];
    }
    return self;
}



- (void)viewDidLoad {
    [super viewDidLoad];
    OsmAndAppInstance app = [OsmAndApp instance];
    
    UIButton* mapButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 64, DeviceScreenWidth, 200 - 64)];
    [mapButton setTitle:@"" forState:UIControlStateNormal];
    [mapButton addTarget:self action:@selector(goToFavorite) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:mapButton];
    
    self.locationServicesUpdateObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                                    withHandler:@selector(updateDistanceAndDirection)
                                                                     andObserve:app.locationServices.updateObserver];
    
}

-(void)viewWillAppear:(BOOL)animated {
    [self setupView];
}

-(void)setupView {
    
    self.favoriteColorView.layer.cornerRadius = 10;
    self.favoriteColorView.layer.masksToBounds = YES;
    [self.favoriteColorView setBackgroundColor:[UIColor colorWithRed:self.favorite.favorite->getColor().r green:self.favorite.favorite->getColor().g blue:self.favorite.favorite->getColor().b alpha:1]];
    if (self.favorite.favorite->getColor().r > 0.95 && self.favorite.favorite->getColor().g > 0.95 && self.favorite.favorite->getColor().b > 0.95) {
        self.favoriteColorView.layer.borderColor = [[UIColor blackColor] CGColor];
        self.favoriteColorView.layer.borderWidth = 0.8;
    } else
        self.favoriteColorView.layer.borderWidth = 0;
    
    [self.distanceDirectionHolderView setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"onmap_placeholder"]]];
    
    // Color
    NSArray* availableColors = [OADefaultFavorite builtinColors];
    
    NSUInteger selectedColor = 0;
    selectedColor = [availableColors indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        UIColor* uiColor = (UIColor*)[obj objectAtIndex:1];
        OsmAnd::FColorARGB fcolor;
        [uiColor getRed:&fcolor.r
                  green:&fcolor.g
                   blue:&fcolor.b
                  alpha:&fcolor.a];
        OsmAnd::ColorRGB color = OsmAnd::FColorRGB(fcolor);
        
        if (color == self.favorite.favorite->getColor())
            return YES;
        return NO;
    }];
    
    if (!selectedColor || selectedColor > [availableColors count] )
        selectedColor = 0;
    
    NSString* colorName = @"Black";

    colorName = [((NSArray*)[availableColors objectAtIndex:selectedColor]) objectAtIndex:0];
    [self.favoriteColorLabel setText:colorName];
    
    
    [self.favoriteDistance setText:self.favorite.distance];
    self.favoriteDirection.transform = CGAffineTransformMakeRotation(self.favorite.direction);
    
    if (self.favorite.favorite->getGroup().isEmpty())
        [self.favoriteGroupView setText: @"No group"];
    else
        [self.favoriteGroupView setText: self.favorite.favorite->getGroup().toNSString()];
    
    [self.favoriteNameButton setTitle:self.favorite.favorite->getTitle().toNSString() forState:UIControlStateNormal];
    [self.favoriteDistance setText:self.favorite.distance];
    
    if (self.newFavorite) {
        [self.saveRemoveButton setTitle:@"Save" forState:UIControlStateNormal];
        [self.saveRemoveButton setImage:nil forState:UIControlStateNormal];
        
        [self.distanceDirectionHolderView setHidden:YES];
        [self.favoriteDirection setHidden:YES];
        [self.favoriteDistance setHidden:YES];
    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)sender{
    OsmAndAppInstance app = [OsmAndApp instance];
    	
    [self.favoriteNameButton setTitle:self.favoriteNameTextView.text forState:UIControlStateNormal];
    self.favorite.favorite->setTitle(QString::fromNSString(self.favoriteNameTextView.text));
    [app saveFavoritesToPermamentStorage];
    [self.favoriteNameTextView resignFirstResponder];
    [self.favoriteNameTextView setHidden:YES];
    
    [self.favoriteNameButton setTitle:self.favoriteNameTextView.text forState:UIControlStateNormal];
    
    return YES;
}

#pragma mark - Actions

- (IBAction)favoriteNameClicked:(id)sender {
    NSString* name = self.favorite.favorite->getTitle().toNSString();

    [self.favoriteNameButton setTitle:@"" forState:UIControlStateNormal];
    [self.favoriteNameTextView setText:name];
    [self.favoriteNameTextView setDelegate:self];
    [self.favoriteNameTextView becomeFirstResponder];
    [self.favoriteNameTextView setHidden:NO];
    
}

- (IBAction)saveButtonClicked:(id)sender {
    if (!self.newFavorite) {
        UIAlertView* removeAlert = [[UIAlertView alloc] initWithTitle:@"" message:@"Remove favorite item?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
        [removeAlert show];
    } else
        [self.navigationController popViewControllerAnimated:YES];
}

- (void)updateDistanceAndDirection
{
    OsmAndAppInstance app = [OsmAndApp instance];
    // Obtain fresh location and heading
    CLLocation* newLocation = app.locationServices.lastKnownLocation;
    CLLocationDirection newHeading = app.locationServices.lastKnownHeading;
    CLLocationDirection newDirection =
    (newLocation.speed >= 1 /* 3.7 km/h */ && newLocation.course >= 0.0f)
    ? newLocation.course
    : newHeading;
    
    const auto& favoritePosition31 = self.favorite.favorite->getPosition31();
    const auto favoriteLon = OsmAnd::Utilities::get31LongitudeX(favoritePosition31.x);
    const auto favoriteLat = OsmAnd::Utilities::get31LatitudeY(favoritePosition31.y);
        
    const auto distance = OsmAnd::Utilities::distance(newLocation.coordinate.longitude,
                                                        newLocation.coordinate.latitude,
                                                        favoriteLon, favoriteLat);
        
    self.favorite.distance = [app.locationFormatter stringFromDistance:distance];
    self.favorite.distanceMeters = distance;
    CGFloat itemDirection = [app.locationServices radiusFromBearingToLocation:[[CLLocation alloc] initWithLatitude:favoriteLat longitude:favoriteLon]];
    self.favorite.direction = -(itemDirection + newDirection / 180.0f * M_PI);
        
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.favoriteDistance setText:self.favorite.distance];
        self.favoriteDirection.transform = CGAffineTransformMakeRotation(self.favorite.direction);
    });
}

-(IBAction)backButtonClicked:(id)sender {
    OsmAndAppInstance app = [OsmAndApp instance];
    if (self.newFavorite) {
        app.favoritesCollection->removeFavoriteLocation(self.favorite.favorite);
        [app saveFavoritesToPermamentStorage];
    }
    [super backButtonClicked:sender];
}

- (IBAction)favoriteChangeColorClicked:(id)sender {
    OAFavoriteColorViewController* controller = [[OAFavoriteColorViewController alloc] initWithFavorite:self.favorite];
    [self.navigationController pushViewController:controller animated:YES];
}

- (IBAction)favoriteChangeGroupClicked:(id)sender {
    OAFavoriteGroupViewController* controller = [[OAFavoriteGroupViewController alloc] initWithFavorite:self.favorite];
    [self.navigationController pushViewController:controller animated:YES];
}

- (IBAction)menuFavoriteClicked:(id)sender {
}

- (IBAction)menuGPXClicked:(id)sender {
}


-(void)goToFavorite {
    OsmAndAppInstance app = [OsmAndApp instance];
    
    OARootViewController* rootViewController = [OARootViewController instance];
    OAFavoriteItem* itemData = self.favorite;
    // Close everything
    [rootViewController closeMenuAndPanelsAnimated:YES];
    // Ensure favorites layer is shown
    [app.data.mapLayersConfiguration setLayer:kFavoritesLayerId
                                   Visibility:YES];

    // Go to favorite location
    [rootViewController.mapPanel.mapViewController goToPosition:[OANativeUtilities convertFromPointI:itemData.favorite->getPosition31()]
                                                    andZoom:kDefaultFavoriteZoom
                                                   animated:YES];
    [self.navigationController popToRootViewControllerAnimated:YES];
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {

    if (buttonIndex != alertView.cancelButtonIndex) {
        OsmAndAppInstance app = [OsmAndApp instance];
        app.favoritesCollection->removeFavoriteLocation(self.favorite.favorite);
        [app saveFavoritesToPermamentStorage];
        [self.navigationController popViewControllerAnimated:YES];
    }
}


@end
