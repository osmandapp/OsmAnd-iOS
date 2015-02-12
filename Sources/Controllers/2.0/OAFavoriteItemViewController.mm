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
#import "OAGPXListViewController.h"

#include <OsmAndCore.h>
#include <OsmAndCore/IFavoriteLocation.h>
#include <OsmAndCore/Utilities.h>
#include "Localization.h"


typedef enum
{
    kFavoriteActionNone = 0,
    kFavoriteActionChangeColor = 1,
    kFavoriteActionChangeGroup = 2,
} EFavoriteAction;

@interface OAFavoriteItemViewController () {
    
    OAMapViewController *_mapViewController;
    OAMapMode _mainMapMode;
    OsmAnd::PointI _mainMapTarget31;
    float _mainMapZoom;
    float _mainMapAzimuth;
    float _mainMapEvelationAngle;
    
    EFavoriteAction _favAction;
    
    CGFloat contentOriginY;
    CGFloat dy;
    
    BOOL isAdjustingVews;

    BOOL _showFavoriteOnExit;
    BOOL _wasShowingFavorites;
    BOOL _deleteFavorite;
}
@end

@implementation OAFavoriteItemViewController

- (id)initWithFavoriteItem:(OAFavoriteItem*)favorite {
    self = [super init];
    if (self) {
        self.favorite = favorite;
        self.newFavorite = NO;
        _favAction = kFavoriteActionNone;
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

- (void)viewWillLayoutSubviews
{
    if (!isAdjustingVews)
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
            CGFloat mapHeight = 166.0;
            CGFloat mapBottom = topY + mapHeight;
            
            self.mapView.frame = CGRectMake(0.0, topY, mapWidth, mapHeight);
            self.distanceDirectionHolderView.frame = CGRectMake(mapWidth/2.0 - 110.0/2.0, mapBottom - 19.0, 110.0, 40.0);
            self.scrollView.frame = CGRectMake(0.0, mapBottom, small, big - self.toolbarView.frame.size.height - mapBottom);
            self.scrollView.contentSize = CGSizeMake(small, 250.0);

        }
        
    } else {
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            
            
        } else {
            
            CGFloat topY = 64.0;
            CGFloat mapHeight = small - topY - self.toolbarView.frame.size.height - 40.0;
            CGFloat mapWidth = 220.0;
            CGFloat mapBottom = topY + mapHeight;
            
            self.mapView.frame = CGRectMake(0.0, topY, mapWidth, mapHeight);
            self.distanceDirectionHolderView.frame = CGRectMake(mapWidth/2.0 - 110.0/2.0, mapBottom - 19.0, 110.0, 40.0);
            self.scrollView.frame = CGRectMake(mapWidth, topY, big - mapWidth, small - self.toolbarView.frame.size.height - topY);
            self.scrollView.contentSize = CGSizeMake(big - mapWidth, 250.0);

        }
        
    }
    
}


- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    contentOriginY = self.favoriteNameButton.frame.origin.y;
    
    OsmAndAppInstance app = [OsmAndApp instance];
    
    UIButton* mapButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 64, DeviceScreenWidth, 230 - 64)];
    [mapButton setTitle:@"" forState:UIControlStateNormal];
    [mapButton addTarget:self action:@selector(goToFavorite) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:mapButton];
    
    self.locationServicesUpdateObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                                    withHandler:@selector(updateDistanceAndDirection)
                                                                     andObserve:app.locationServices.updateObserver];

}

-(void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    [self setupView];

    if (_favAction != kFavoriteActionNone) {
        _favAction = kFavoriteActionNone;
        return;
    }
    
    OAAppSettings* settings = [OAAppSettings sharedManager];
    _wasShowingFavorites = settings.mapSettingShowFavorites;
    [settings setMapSettingShowFavorites:YES];
    
    OsmAndAppInstance app = [OsmAndApp instance];
    
    _mapViewController = [OARootViewController instance].mapPanel.mapViewController;

    _mainMapMode = app.mapMode;
    
    OAMapRendererView* renderView = (OAMapRendererView*)_mapViewController.view;
    
    _mainMapTarget31 = renderView.target31;
    _mainMapZoom = renderView.zoom;
    _mainMapAzimuth = renderView.azimuth;
    _mainMapEvelationAngle = renderView.elevationAngle;
    
    _showFavoriteOnExit = NO;

    [_mapViewController goToPosition:[OANativeUtilities convertFromPointI:self.favorite.favorite->getPosition31()]
                             andZoom:kDefaultFavoriteZoom
                            animated:NO];

    renderView.azimuth = 0.0;
    renderView.elevationAngle = 90.0;

    [self registerForKeyboardNotifications];

}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (_favAction != kFavoriteActionNone)
        return;

    _mapViewController.view.frame = CGRectMake(0, 0, self.mapView.bounds.size.width, self.mapView.bounds.size.height);
    
    [_mapViewController willMoveToParentViewController:nil];
    
    [self addChildViewController:_mapViewController];
    [self.mapView addSubview:_mapViewController.view];
    [_mapViewController didMoveToParentViewController:self];
    [self.mapView bringSubviewToFront:_mapViewController.view];
    
    UIView * parent = self.mapView;
    UIView * child = _mapViewController.view;
    [child setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    [parent addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[child]|"
                                                                   options:0
                                                                   metrics:nil
                                                                     views:NSDictionaryOfVariableBindings(child)]];
    [parent addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[child]|"
                                                                   options:0
                                                                   metrics:nil
                                                                     views:NSDictionaryOfVariableBindings(child)]];
    [parent layoutIfNeeded];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if (_favAction != kFavoriteActionNone)
        return;
    
    if (_showFavoriteOnExit) {
        
        [_mapViewController goToPosition:[OANativeUtilities convertFromPointI:_mainMapTarget31] andZoom:_mainMapZoom animated:YES];
        
    } else {
        
        [OsmAndApp instance].mapMode = _mainMapMode;

        OAMapRendererView* mapView = (OAMapRendererView*)_mapViewController.view;
        mapView.target31 = _mainMapTarget31;
        mapView.zoom = _mainMapZoom;
        mapView.azimuth = _mainMapAzimuth;
        mapView.elevationAngle = _mainMapEvelationAngle;
    }

    [self unregisterKeyboardNotifications];

}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];

    if (_favAction != kFavoriteActionNone)
        return;
    
    OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
    _mapViewController = mapPanel.mapViewController;
    
    _mapViewController.view.frame = CGRectMake(0, 0, mapPanel.view.bounds.size.width, mapPanel.view.bounds.size.height);
    
    [_mapViewController willMoveToParentViewController:nil];
    
    [mapPanel addChildViewController:_mapViewController];
    [mapPanel.view addSubview:_mapViewController.view];
    [_mapViewController didMoveToParentViewController:self];
    [mapPanel.view sendSubviewToBack:_mapViewController.view];
    
    [_mapViewController.view setTranslatesAutoresizingMaskIntoConstraints:NO];
    [mapPanel.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:@{@"view":_mapViewController.view}]];
    [mapPanel.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:@{@"view":_mapViewController.view}]];
    
    OAAppSettings* settings = [OAAppSettings sharedManager];
    [settings setMapSettingShowFavorites:NO];
    if (_showFavoriteOnExit || _wasShowingFavorites)
        [settings setMapSettingShowFavorites:YES];
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

// keyboard notifications register+process
- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    
}

- (void)unregisterKeyboardNotifications
{
    //unregister the keyboard notifications while not visible
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
    
}
// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardWillShow:(NSNotification*)aNotification
{
    CGRect keyboardFrame = [[[aNotification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    CGRect convertedFrame = [self.view convertRect:keyboardFrame fromView:self.view.window];
    
    CGRect frameMap = self.mapView.frame;
    CGRect frameScrollView = self.scrollView.frame;
    CGRect frameDistView = self.distanceDirectionHolderView.frame;
    CGRect frameNameBtn = self.favoriteNameButton.frame;
    
    CGFloat minBottom = frameScrollView.origin.y + contentOriginY + frameNameBtn.size.height;
    CGFloat keyboardTop = self.view.frame.size.height - convertedFrame.size.height;
    
    BOOL needOffsetViews = minBottom > keyboardTop;
    
    if (needOffsetViews) {
        
        dy = keyboardTop - minBottom;
        isAdjustingVews = YES;
        
        [UIView animateWithDuration:.3 animations:^{
            self.mapView.frame = CGRectOffset(frameMap, 0.0, dy);
            self.scrollView.frame = CGRectOffset(frameScrollView, 0.0, dy);
            self.distanceDirectionHolderView.frame = CGRectOffset(frameDistView, 0.0, dy);
        } completion:^(BOOL finished) {
            isAdjustingVews = NO;
        }];
        
    } else {
        dy = 0.0;
    }
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    if (dy < 0.0) {
        
        CGRect frameMap = self.mapView.frame;
        CGRect frameScrollView = self.scrollView.frame;
        CGRect frameDistView = self.distanceDirectionHolderView.frame;

        isAdjustingVews = YES;
        [UIView animateWithDuration:.3 animations:^{
            self.mapView.frame = CGRectOffset(frameMap, 0.0, -dy);
            self.scrollView.frame = CGRectOffset(frameScrollView, 0.0, -dy);
            self.distanceDirectionHolderView.frame = CGRectOffset(frameDistView, 0.0, -dy);
        } completion:^(BOOL finished) {
            isAdjustingVews = NO;
        }];
    }
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
    } else {
        _showFavoriteOnExit = YES;
        [self.navigationController popViewControllerAnimated:YES];
    }
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
    _favAction = kFavoriteActionChangeColor;
    OAFavoriteColorViewController* controller = [[OAFavoriteColorViewController alloc] initWithFavorite:self.favorite];
    [self.navigationController pushViewController:controller animated:YES];
}

- (IBAction)favoriteChangeGroupClicked:(id)sender {
    _favAction = kFavoriteActionChangeGroup;
    OAFavoriteGroupViewController* controller = [[OAFavoriteGroupViewController alloc] initWithFavorite:self.favorite];
    [self.navigationController pushViewController:controller animated:YES];
}

- (IBAction)menuFavoriteClicked:(id)sender {
}

- (IBAction)menuGPXClicked:(id)sender {
    OAGPXListViewController* favController = [[OAGPXListViewController alloc] init];
    [self.navigationController pushViewController:favController animated:NO];
}

// open map with favorite item
-(void)goToFavorite {
    OsmAndAppInstance app = [OsmAndApp instance];
    
    OARootViewController* rootViewController = [OARootViewController instance];
    OAFavoriteItem* itemData = self.favorite;
    // Close everything
    [rootViewController closeMenuAndPanelsAnimated:YES];
    // Ensure favorites layer is shown
    [app.data.mapLayersConfiguration setLayer:kFavoritesLayerId
                                   Visibility:NO];

    // Go to favorite location
    _mainMapTarget31 = itemData.favorite->getPosition31();
    _mainMapZoom = kDefaultFavoriteZoom;
    
    _showFavoriteOnExit = YES;
    
    [self.navigationController popToRootViewControllerAnimated:YES];
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {

    if (buttonIndex != alertView.cancelButtonIndex) {
        OsmAndAppInstance app = [OsmAndApp instance];
        app.favoritesCollection->removeFavoriteLocation(self.favorite.favorite);
        [app saveFavoritesToPermamentStorage];
        _deleteFavorite = YES;
        [self.navigationController popViewControllerAnimated:YES];
    }
}


@end
