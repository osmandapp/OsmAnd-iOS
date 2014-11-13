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
#include <OsmAndCore/Map/BinaryMapDataProvider.h>
#include <OsmAndCore/Map/BinaryMapPrimitivesProvider.h>
#include <OsmAndCore/Map/BinaryMapRasterLayerProvider_Software.h>
#include <OsmAndCore/Map/BinaryMapStaticSymbolsProvider.h>
#include <OsmAndCore/Map/MapPresentationEnvironment.h>
#include <OsmAndCore/Map/Primitiviser.h>
#include <OsmAndCore/Map/MapMarker.h>
#include <OsmAndCore/Map/MapMarkerBuilder.h>
#include <OsmAndCore/Map/MapMarkersCollection.h>
#include <OsmAndCore/Map/FavoriteLocationsPresenter.h>
#if defined(OSMAND_IOS_DEV)
#   include <OsmAndCore/Map/BinaryMapDataMetricsLayerProvider.h>
#   include <OsmAndCore/Map/BinaryMapPrimitivesMetricsLayerProvider.h>
#   include <OsmAndCore/Map/BinaryMapRasterMetricsLayerProvider.h>
#endif // defined(OSMAND_IOS_DEV)


@interface OAFavoriteItemViewController ()

    @property UITextField* nameTextField;

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
}

-(void)viewWillAppear:(BOOL)animated {
    [self setupView];
}


-(void)setupView {
 
    self.favoriteNameButton.layer.borderColor = [[UIColor colorWithRed:200.0/255.0 green:200.0/255.0 blue:200.0/255.0 alpha:1.0] CGColor];
    self.favoriteNameButton.layer.borderWidth = 1.0;
    
    self.favoriteColorButton.layer.borderColor = [[UIColor colorWithRed:200.0/255.0 green:200.0/255.0 blue:200.0/255.0 alpha:1.0] CGColor];
    self.favoriteColorButton.layer.borderWidth = 1.0;
    
    self.favoriteGroupButton.layer.borderColor = [[UIColor colorWithRed:200.0/255.0 green:200.0/255.0 blue:200.0/255.0 alpha:1.0] CGColor];
    self.favoriteGroupButton.layer.borderWidth = 1.0;
    
    self.favoriteColorView.layer.cornerRadius = 10;
    self.favoriteColorView.layer.masksToBounds = YES;
    [self.favoriteColorView setBackgroundColor:[UIColor colorWithRed:self.favorite.favorite->getColor().r green:self.favorite.favorite->getColor().g blue:self.favorite.favorite->getColor().b alpha:1]];
    
    
    if (self.favorite.favorite->getGroup().isEmpty())
        [self.favoriteGroupView setText: @"No group"];
    else
        [self.favoriteGroupView setText: self.favorite.favorite->getGroup().toNSString()];
    
    [self.favoriteNameButton setTitle:self.favorite.favorite->getTitle().toNSString() forState:UIControlStateNormal];
    [self.favoriteDistanceView setText:self.favorite.distance];
    
    if (self.newFavorite)
        [self.saveButton setHidden:NO];
}
        
        
        
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)sender{
    OsmAndAppInstance app = [OsmAndApp instance];
    	
    [self.favoriteNameButton setTitle:self.nameTextField.text forState:UIControlStateNormal];
    self.favorite.favorite->setTitle(QString::fromNSString(self.nameTextField.text));
    [app saveFavoritesToPermamentStorage];
    [self.nameTextField resignFirstResponder];
    [self.nameTextField removeFromSuperview];
    return YES;
}

-(void)changeName:(id)sender {
    [self.favoriteNameButton setTitle:self.nameTextField.text forState:UIControlStateNormal];
}


#pragma mark - Actions

- (IBAction)favoriteNameClicked:(id)sender {
    self.nameTextField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    [self.nameTextField addTarget:self action:@selector(changeName:) forControlEvents:UIControlEventEditingChanged];
    [self.nameTextField setText:self.favorite.favorite->getTitle().toNSString()];
    [self.nameTextField setDelegate:self];
    [self.favoriteNameButton addSubview:self.nameTextField];
    [self.nameTextField becomeFirstResponder];
    
}

- (IBAction)saveButtonClicked:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

-(IBAction)backButtonClicked:(id)sender {
    OsmAndAppInstance app = [OsmAndApp instance];
    if (self.newFavorite)
        app.favoritesCollection->removeFavoriteLocation(self.favorite.favorite);
    
    [super backButtonClicked:sender];
}

- (IBAction)favoriteChangeColorClicked:(id)sender {
    
}

- (IBAction)favoriteChangeGroupClicked:(id)sender {
    OAFavoriteGroupViewController* controller = [[OAFavoriteGroupViewController alloc] initWithFavorite:self.favorite];
    [self.navigationController pushViewController:controller animated:YES];
}

- (IBAction)menuFavoriteClicked:(id)sender {
}

- (IBAction)menuGPXClicked:(id)sender {
}


@end
