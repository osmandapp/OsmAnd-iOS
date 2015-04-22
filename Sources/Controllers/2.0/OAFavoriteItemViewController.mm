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
#import "OALog.h"
#import "OAFavoriteGroupViewController.h"
#import "OAFavoriteColorViewController.h"
#import "OADefaultFavorite.h"
#import "OARootViewController.h"
#import "OANativeUtilities.h"
#import "OAGPXListViewController.h"
#import "OAFavoriteListViewController.h"
#import "OAUtilities.h"

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
    
    OsmAnd::PointI _newTarget31;
    
    EFavoriteAction _favAction;
    
    CGFloat contentOriginY;
    CGFloat dy;
    
    BOOL isAdjustingVews;

    BOOL _showFavoriteOnExit;
    BOOL _wasShowingFavorite;
    BOOL _deleteFavorite;
}

@property (weak, nonatomic) IBOutlet UIButton *shareButton;

@property (nonatomic) OAAutoObserverProxy* locationServicesUpdateObserver;
@property (nonatomic) UIButton *mapButton;

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
        
        OAFavoriteColor *favCol = [OADefaultFavorite builtinColors][0];
    
        UIColor* color_ = favCol.color;
        CGFloat r,g,b,a;
        [color_ getRed:&r
                 green:&g
                  blue:&b
                 alpha:&a];

        OAFavoriteItem* fav = [[OAFavoriteItem alloc] init];
        fav.favorite = app.favoritesCollection->createFavoriteLocation(locationPoint,
                                                                       title,
                                                                       QString::null,
                                                                       OsmAnd::FColorRGB(r,g,b));
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
    
    CGRect rect = self.view.bounds;
    if (rect.size.width > rect.size.height) {
        big = rect.size.width;
        small = rect.size.height;
    } else {
        big = rect.size.height;
        small = rect.size.width;
    }
    
    if (_shareButton.hidden)
        _saveRemoveButton.frame = CGRectMake(DeviceScreenWidth - 50.0, 20.0, 50.0, 44.0);
    else
        _saveRemoveButton.frame = CGRectMake(DeviceScreenWidth - 38.0, 20.0, 36.0, 44.0);
    
    if (self.newFavorite)
        _saveRemoveButton.frame = CGRectMake(DeviceScreenWidth - 80.0, 20.0, 80.0, _saveRemoveButton.bounds.size.height);
    
    if (UIInterfaceOrientationIsPortrait(interfaceOrientation)) {
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            
            
        } else {
            
            CGFloat topY = 64.0;
            CGFloat mapWidth = small;
            CGFloat mapHeight = 166.0;
            CGFloat mapBottom = topY + mapHeight;
            CGFloat toolbarHeight = (self.toolbarView.hidden ? 0.0 : self.toolbarView.frame.size.height);
            
            self.mapView.frame = CGRectMake(0.0, topY, mapWidth, mapHeight);
            self.mapButton.frame = self.mapView.frame;
            self.distanceDirectionHolderView.frame = CGRectMake(mapWidth/2.0 - 110.0/2.0, mapBottom - 19.0, 110.0, 40.0);
            self.scrollView.frame = CGRectMake(0.0, mapBottom, small, big - toolbarHeight - mapBottom);
            
            CGFloat y = 35.0 - self.favoriteNameButton.frame.origin.y;
            self.favoriteNameButton.frame = CGRectOffset(self.favoriteNameButton.frame, 0.0, y);
            self.favoriteGroupButton.frame = CGRectOffset(self.favoriteGroupButton.frame, 0.0, y);
            self.arrowColor.frame = CGRectOffset(self.arrowColor.frame, 0.0, y);
            self.arrowGroup.frame = CGRectOffset(self.arrowGroup.frame, 0.0, y);
            self.favoriteColorButton.frame = CGRectOffset(self.favoriteColorButton.frame, 0.0, y);
            self.favoriteColorIcon.frame = CGRectOffset(self.favoriteColorIcon.frame, 0.0, y);
            self.favoriteColorLabel.frame = CGRectOffset(self.favoriteColorLabel.frame, 0.0, y);
            self.favoriteGroupView.frame = CGRectOffset(self.favoriteGroupView.frame, 0.0, y);
            self.favoriteNameTextView.frame = CGRectOffset(self.favoriteNameTextView.frame, 0.0, y);
            
            self.scrollView.contentSize = CGSizeMake(big - mapWidth, self.favoriteGroupButton.frame.origin.y + self.favoriteGroupButton.frame.size.height - self.favoriteNameButton.frame.origin.y + 35.0);
            self.scrollView.contentInset = UIEdgeInsetsZero;

        }
        
    } else {
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            
            
        } else {
            
            CGFloat toolbarHeight = (self.toolbarView.hidden ? 0.0 : self.toolbarView.frame.size.height);
            CGFloat topY = 64.0;
            CGFloat mapHeight = small - topY - toolbarHeight;
            CGFloat mapWidth = big / 2.0;
            CGFloat mapBottom = topY + mapHeight;

            self.mapView.frame = CGRectMake(0.0, topY, mapWidth, mapHeight);
            self.mapButton.frame = self.mapView.frame;
            self.distanceDirectionHolderView.frame = CGRectMake(mapWidth/2.0 - 110.0/2.0, mapBottom - 49.0, 110.0, 40.0);
            self.scrollView.frame = CGRectMake(mapWidth, topY, big - mapWidth, small - toolbarHeight - topY);

            CGFloat y = 0.0 - self.favoriteNameButton.frame.origin.y;
            self.favoriteNameButton.frame = CGRectOffset(self.favoriteNameButton.frame, 0.0, y);
            self.favoriteGroupButton.frame = CGRectOffset(self.favoriteGroupButton.frame, 0.0, y);
            self.arrowColor.frame = CGRectOffset(self.arrowColor.frame, 0.0, y);
            self.arrowGroup.frame = CGRectOffset(self.arrowGroup.frame, 0.0, y);
            self.favoriteColorButton.frame = CGRectOffset(self.favoriteColorButton.frame, 0.0, y);
            self.favoriteColorIcon.frame = CGRectOffset(self.favoriteColorIcon.frame, 0.0, y);
            self.favoriteColorLabel.frame = CGRectOffset(self.favoriteColorLabel.frame, 0.0, y);
            self.favoriteGroupView.frame = CGRectOffset(self.favoriteGroupView.frame, 0.0, y);
            self.favoriteNameTextView.frame = CGRectOffset(self.favoriteNameTextView.frame, 0.0, y);

            self.scrollView.contentSize = CGSizeMake(big - mapWidth, self.favoriteGroupButton.frame.origin.y + self.favoriteGroupButton.frame.size.height - self.favoriteNameButton.frame.origin.y);
            self.scrollView.contentInset = UIEdgeInsetsZero;

        }
        
    }
    
}

- (void)applyLocalization
{
    _titleView.text = OALocalizedString(@"favorite");
    [_backButton setTitle:OALocalizedString(@"shared_string_back") forState:UIControlStateNormal];

    [_favoriteNameButton setTitle:OALocalizedString(@"fav_name") forState:UIControlStateNormal];
    [_favoriteColorButton setTitle:OALocalizedString(@"fav_color") forState:UIControlStateNormal];
    [_favoriteGroupButton setTitle:OALocalizedString(@"fav_group") forState:UIControlStateNormal];
    
    [_favoritesButtonView setTitle:OALocalizedStringUp(@"favorites") forState:UIControlStateNormal];
    [_gpxButtonView setTitle:OALocalizedStringUp(@"tracks") forState:UIControlStateNormal];
    [OAUtilities layoutComplexButton:self.favoritesButtonView];
    [OAUtilities layoutComplexButton:self.gpxButtonView];
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    contentOriginY = self.favoriteNameButton.frame.origin.y;
    
    self.mapButton = [[UIButton alloc] initWithFrame:self.mapView.frame];
    [self.mapButton setTitle:@"" forState:UIControlStateNormal];
    [self.mapButton addTarget:self action:@selector(goToFavorite) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.mapButton];
    
    _shareButton.hidden = _newFavorite;
    _toolbarView.hidden = _newFavorite || ![self.navigationController.viewControllers[self.navigationController.viewControllers.count - 2] isKindOfClass:[OAFavoriteListViewController class]];
    
}

-(void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    OsmAndAppInstance app = [OsmAndApp instance];
    self.locationServicesUpdateObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                                    withHandler:@selector(updateDistanceAndDirection)
                                                                     andObserve:app.locationServices.updateObserver];
    [self setupView];

    if (_favAction != kFavoriteActionNone) {
        return;
    }
    
    [[OARootViewController instance].mapPanel prepareMapForReuse:[OANativeUtilities convertFromPointI:self.favorite.favorite->getPosition31()] zoom:kDefaultFavoriteZoom newAzimuth:0.0 newElevationAngle:90.0 animated:NO];
    
    _showFavoriteOnExit = NO;

    [self registerForKeyboardNotifications];

}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (_favAction != kFavoriteActionNone) {
        _favAction = kFavoriteActionNone;
        return;
    }

    [[OARootViewController instance].mapPanel doMapReuse:self destinationView:self.mapView];

    OAAppSettings* settings = [OAAppSettings sharedManager];
    _wasShowingFavorite = settings.mapSettingShowFavorites;
    [settings setMapSettingShowFavorites:YES];

}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if (self.locationServicesUpdateObserver) {
        [self.locationServicesUpdateObserver detach];
        self.locationServicesUpdateObserver = nil;
    }
    
    if (_favAction != kFavoriteActionNone)
        return;
    
    if (_showFavoriteOnExit) {
        
        [[OARootViewController instance].mapPanel modifyMapAfterReuse:[OANativeUtilities convertFromPointI:_newTarget31] zoom:kDefaultFavoriteZoomOnShow azimuth:0.0 elevationAngle:90.0 animated:NO];
        
    } else {
        OAAppSettings* settings = [OAAppSettings sharedManager];
        if (!_showFavoriteOnExit && !_wasShowingFavorite)
            [settings setMapSettingShowFavorites:NO];
    }

    [self unregisterKeyboardNotifications];

}

-(void)setupView {
    
    [self.distanceDirectionHolderView setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"onmap_placeholder"]]];
    
    // Color
    UIColor* color = [UIColor colorWithRed:self.favorite.favorite->getColor().r/255.0 green:self.favorite.favorite->getColor().g/255.0 blue:self.favorite.favorite->getColor().b/255.0 alpha:1.0];
        
    OAFavoriteColor *favCol = [OADefaultFavorite nearestFavColor:color];
    [_favoriteColorIcon setImage:favCol.icon];
    [_favoriteColorLabel setText:favCol.name];
    
    [_favoriteDistance setText:self.favorite.distance];
    _favoriteDirection.transform = CGAffineTransformMakeRotation(self.favorite.direction);
    
    if (self.favorite.favorite->getGroup().isEmpty())
        [_favoriteGroupView setText: OALocalizedString(@"fav_no_group")];
    else
        [_favoriteGroupView setText: self.favorite.favorite->getGroup().toNSString()];
    
    [_favoriteNameButton setTitle:self.favorite.favorite->getTitle().toNSString() forState:UIControlStateNormal];
    [_favoriteDistance setText:self.favorite.distance];
    
    if (self.newFavorite) {
        [_saveRemoveButton setTitle:OALocalizedString(@"shared_string_save") forState:UIControlStateNormal];
        [_saveRemoveButton setImage:nil forState:UIControlStateNormal];
        
        [_distanceDirectionHolderView setHidden:YES];
        [_favoriteDirection setHidden:YES];
        [_favoriteDistance setHidden:YES];
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

    if (_newFavorite)
        [self.favoriteNameTextView setSelectedTextRange:[self.favoriteNameTextView textRangeFromPosition:self.favoriteNameTextView.beginningOfDocument toPosition:self.favoriteNameTextView.endOfDocument]];

}

- (IBAction)saveButtonClicked:(id)sender {
    if (!self.newFavorite) {
        UIAlertView* removeAlert = [[UIAlertView alloc] initWithTitle:@"" message:OALocalizedString(@"fav_remove_q") delegate:self cancelButtonTitle:OALocalizedString(@"shared_string_no") otherButtonTitles:OALocalizedString(@"shared_string_yes"), nil];
        [removeAlert show];
    } else {
        
        if ([self.favoriteNameTextView isFirstResponder]) {
            OsmAndAppInstance app = [OsmAndApp instance];
            self.favorite.favorite->setTitle(QString::fromNSString(self.favoriteNameTextView.text));
            [app saveFavoritesToPermamentStorage];
        }
        _newTarget31 = self.favorite.favorite->getPosition31();
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
        
    self.favorite.distance = [app getFormattedDistance:distance];
    self.favorite.distanceMeters = distance;
    CGFloat itemDirection = [app.locationServices radiusFromBearingToLocation:[[CLLocation alloc] initWithLatitude:favoriteLat longitude:favoriteLon]];
    self.favorite.direction = OsmAnd::Utilities::normalizedAngleDegrees(itemDirection - newDirection) * (M_PI / 180);
        
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.favoriteDistance setText:self.favorite.distance];
        self.favoriteDirection.transform = CGAffineTransformMakeRotation(self.favorite.direction);
    });
}

-(IBAction)backButtonClicked:(id)sender
{
    OsmAndAppInstance app = [OsmAndApp instance];
    if (self.newFavorite) {
        app.favoritesCollection->removeFavoriteLocation(self.favorite.favorite);
        [app saveFavoritesToPermamentStorage];
    }
    [super backButtonClicked:sender];
}

- (IBAction)favoriteChangeColorClicked:(id)sender
{
    _favAction = kFavoriteActionChangeColor;
    OAFavoriteColorViewController* controller = [[OAFavoriteColorViewController alloc] initWithFavorite:self.favorite];
    [self.navigationController pushViewController:controller animated:YES];
}

- (IBAction)favoriteChangeGroupClicked:(id)sender
{
    _favAction = kFavoriteActionChangeGroup;
    OAFavoriteGroupViewController* controller = [[OAFavoriteGroupViewController alloc] initWithFavorite:self.favorite];
    [self.navigationController pushViewController:controller animated:YES];
}

- (IBAction)menuFavoriteClicked:(id)sender
{
}

- (IBAction)menuGPXClicked:(id)sender
{
    OAGPXListViewController* favController = [[OAGPXListViewController alloc] init];
    [self.navigationController pushViewController:favController animated:NO];
}

- (IBAction)shareButtonClicked:(id)sender
{
    const auto& favoritePosition31 = self.favorite.favorite->getPosition31();
    const auto favoriteLon = OsmAnd::Utilities::get31LongitudeX(favoritePosition31.x);
    const auto favoriteLat = OsmAnd::Utilities::get31LatitudeY(favoritePosition31.y);
    
    NSString *string = [NSString stringWithFormat:kShareLinkTemplate, favoriteLat, favoriteLon, (int)kDefaultFavoriteZoom];
    
    UIActivityViewController *activityViewController =
    [[UIActivityViewController alloc] initWithActivityItems:@[/*image,*/ string]
                                      applicationActivities:nil];
    
    [self.navigationController presentViewController:activityViewController
                                     animated:YES
                                   completion:^{ }];
}

// open map with favorite item
-(void)goToFavorite {
    
    OARootViewController* rootViewController = [OARootViewController instance];
    OAFavoriteItem* itemData = self.favorite;
    // Close everything
    [rootViewController closeMenuAndPanelsAnimated:YES];

    // Go to favorite location
    _newTarget31 = itemData.favorite->getPosition31();
    
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
