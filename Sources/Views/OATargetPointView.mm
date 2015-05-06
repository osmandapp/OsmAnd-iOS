//
//  OATargetPointView.m
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 03.11.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OATargetPointView.h"
#import "OsmAndApp.h"
#import "OAFavoriteItemViewController.h"
#import "OAMapRendererView.h"
#import "OATargetPoint.h"
#import "OADefaultFavorite.h"
#import "Localization.h"
#import "OAIAPHelper.h"
#import "PXAlertView.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/IFavoriteLocation.h>
#include <OsmAndCore/IFavoriteLocationsCollection.h>

@interface OATargetPointView()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *addressLabel;
@property (weak, nonatomic) IBOutlet UILabel *coordinateLabel;

@property (weak, nonatomic) IBOutlet UIButton *buttonFavorite;
@property (weak, nonatomic) IBOutlet UIButton *buttonShare;
@property (weak, nonatomic) IBOutlet UIButton *buttonDirection;
@property (weak, nonatomic) IBOutlet UIButton *buttonMore;

@property (weak, nonatomic) IBOutlet UIButton *buttonShadow;
@property (weak, nonatomic) IBOutlet UIButton *buttonClose;

@property (weak, nonatomic) IBOutlet UIView *buttonsView;
@property (weak, nonatomic) IBOutlet UIView *backView1;
@property (weak, nonatomic) IBOutlet UIView *backView2;
@property (weak, nonatomic) IBOutlet UIView *backView3;
@property (weak, nonatomic) IBOutlet UIView *backView4;

@property NSString* formattedLocation;
@property OAMapRendererView* mapView;
@property UINavigationController* navController;

@end

@implementation OATargetPointView
{
    NSInteger _buttonsCount;
    CGFloat _buttonsWidthLandscape;
}

- (instancetype)init
{
    NSArray *bundle = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:nil options:nil];
    if ([bundle count])
    {
        self = [bundle firstObject];
        if (self) {
        }
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    NSArray *bundle = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:nil options:nil];
    if ([bundle count])
    {
        self = [bundle firstObject];
        if (self) {
            self.frame = frame;
        }
    }
    return self;
}


-(void)awakeFromNib
{
    [self doUpdateUI];

    [_buttonShare setTitle:OALocalizedString(@"ctx_mnu_share") forState:UIControlStateNormal];
    [_buttonDirection setTitle:OALocalizedString(@"ctx_mnu_direction") forState:UIControlStateNormal];

    _backView4.hidden = YES;
    _buttonMore.hidden = YES;

    // drop shadow
    [self.layer setShadowColor:[UIColor blackColor].CGColor];
    [self.layer setShadowOpacity:0.8];
    [self.layer setShadowRadius:3.0];
    [self.layer setShadowOffset:CGSizeMake(2.0, 2.0)];
    
    [OsmAndApp instance].favoritesCollection->collectionChangeObservable.attach((__bridge const void*)self,
                                                                [self]
                                                                (const OsmAnd::IFavoriteLocationsCollection* const collection)
                                                                {
                                                                    [self onFavoritesCollectionChanged];
                                                                });

    [OsmAndApp instance].favoritesCollection->favoriteLocationChangeObservable.attach((__bridge const void*)self,
                                                                      [self]
                                                                      (const OsmAnd::IFavoriteLocationsCollection* const collection,
                                                                       const std::shared_ptr<const OsmAnd::IFavoriteLocation> favoriteLocation)
                                                                      {
                                                                          [self onFavoriteLocationChanged:favoriteLocation];
                                                                      });
    
}

- (void)doUpdateUI
{
    _buttonsCount = 3 + ([OAIAPHelper sharedInstance].functionalAddons.count > 0 ? 1 : 0);
    
    _buttonsWidthLandscape = 210.0;
    if (((DeviceScreenWidth > DeviceScreenHeight && DeviceScreenWidth > 480) ||
         (DeviceScreenHeight > DeviceScreenWidth && DeviceScreenHeight > 480)) && _buttonsCount > 3)
        _buttonsWidthLandscape = 260.0;
    
    if (_buttonsCount > 3)
    {
        NSArray *addons = [OAIAPHelper sharedInstance].functionalAddons;
        if (addons.count > 1)
        {
            [self.buttonMore setImage:[UIImage imageNamed:@"three_dots.png"] forState:UIControlStateNormal];
            [self.buttonMore setTitle:OALocalizedString(@"more") forState:UIControlStateNormal];
            self.buttonMore.tintColor = [UIColor grayColor];
        }
        else if (addons.count == 1)
        {
            NSString *title = ((OAFunctionalAddon *)addons[0]).titleShort;
            NSString *imageName = ((OAFunctionalAddon *)addons[0]).imageName;
            [self.buttonMore setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
            [self.buttonMore setTitle:title forState:UIControlStateNormal];
            self.buttonMore.tintColor = [UIColor colorWithRed:1.000f green:0.561f blue:0.000f alpha:1.00f];
        }
    }
    else
    {
        _backView4.hidden = YES;
        _buttonMore.hidden = YES;
    }
}

- (void)layoutSubviews
{
    [self doLayoutSubviews];
}

- (void)doLayoutSubviews
{
    CGFloat h = kOATargetPointViewHeightPortrait;
    BOOL landscape = NO;
    if (DeviceScreenWidth > 470.0) {
        h = kOATargetPointViewHeightLandscape;
        landscape = YES;
    }
    
    CGRect frame = self.frame;
    frame.origin.y = DeviceScreenHeight - h;
    frame.size.width = DeviceScreenWidth;
    frame.size.height = h;
    self.frame = frame;
    
    
    if (_imageView.image)
    {
        if (_imageView.bounds.size.width < _imageView.image.size.width ||
            _imageView.bounds.size.height < _imageView.image.size.height)
            _imageView.contentMode = UIViewContentModeScaleAspectFit;
        else
            _imageView.contentMode = UIViewContentModeTop;
    }
    
    CGFloat textX = (_imageView.image ? 40.0 : 16.0) + (_targetPoint.type == OATargetDestination || _targetPoint.type == OATargetParking ? 10.0 : 0.0);
    
    if (landscape) {
        
        _addressLabel.frame = CGRectMake(textX, 3.0, DeviceScreenWidth - textX - 40.0 - _buttonsWidthLandscape, 36.0);
        _coordinateLabel.frame = CGRectMake(textX, 39.0, DeviceScreenWidth - textX - 40.0 - _buttonsWidthLandscape, 21.0);
        
        _buttonShadow.frame = CGRectMake(0.0, 0.0, DeviceScreenWidth - _buttonsWidthLandscape - 50.0, h);
        _buttonClose.frame = CGRectMake(DeviceScreenWidth - _buttonsWidthLandscape - 36.0, 0.0, 36.0, 36.0);

        _buttonsView.frame = CGRectMake(DeviceScreenWidth - _buttonsWidthLandscape, 0.0, _buttonsWidthLandscape, h);
        CGFloat backViewWidth = floor(_buttonsView.frame.size.width / _buttonsCount);
        CGFloat x = 1.0;
        _backView1.frame = CGRectMake(x, 0.0, backViewWidth, _buttonsView.frame.size.height);
        x += backViewWidth + 1.0;
        _backView2.frame = CGRectMake(x, 0.0, backViewWidth, _buttonsView.frame.size.height);
        x += backViewWidth + 1.0;
        _backView3.frame = CGRectMake(x, 0.0, (_buttonsCount > 3 ? backViewWidth : _buttonsView.frame.size.width - x), _buttonsView.frame.size.height);

        if (_buttonsCount > 3)
        {
            x += backViewWidth + 1.0;
            _backView4.frame = CGRectMake(x, 0.0, _buttonsView.frame.size.width - x, _buttonsView.frame.size.height);
            if (_backView4.hidden)
                _backView4.hidden = NO;
            
            _buttonMore.frame = _backView4.bounds;
            if (_buttonMore.hidden)
                _buttonMore.hidden = NO;
            [self layoutComplexButton:self.buttonMore isPortrait:NO];
        }
        
        _buttonFavorite.frame = _backView1.bounds;
        _buttonShare.frame = _backView2.bounds;
        _buttonDirection.frame = _backView3.bounds;
        
        [self layoutComplexButton:self.buttonFavorite isPortrait:NO];
        [self layoutComplexButton:self.buttonShare isPortrait:NO];
        [self layoutComplexButton:self.buttonDirection isPortrait:NO];

        
    } else {
        
        _addressLabel.frame = CGRectMake(textX, 3.0, DeviceScreenWidth - textX - 40.0, 36.0);
        _coordinateLabel.frame = CGRectMake(textX, 39.0, DeviceScreenWidth - textX - 40.0, 21.0);
        
        _buttonShadow.frame = CGRectMake(0.0, 0.0, DeviceScreenWidth - 50.0, 73.0);
        _buttonClose.frame = CGRectMake(DeviceScreenWidth - 36.0, 0.0, 36.0, 36.0);
        
        _buttonsView.frame = CGRectMake(0.0, 73.0, DeviceScreenWidth, 53.0);
        CGFloat backViewWidth = floor(_buttonsView.frame.size.width / _buttonsCount);
        CGFloat x = 0.0;
        _backView1.frame = CGRectMake(x, 1.0, backViewWidth, _buttonsView.frame.size.height - 1.0);
        x += backViewWidth + 1.0;
        _backView2.frame = CGRectMake(x, 1.0, backViewWidth, _buttonsView.frame.size.height - 1.0);
        x += backViewWidth + 1.0;
        _backView3.frame = CGRectMake(x, 1.0, (_buttonsCount > 3 ? backViewWidth : _buttonsView.frame.size.width - x), _buttonsView.frame.size.height - 1.0);
        
        if (_buttonsCount > 3)
        {
            x += backViewWidth + 1.0;
            _backView4.frame = CGRectMake(x, 1.0, _buttonsView.frame.size.width - x, _buttonsView.frame.size.height - 1.0);
            if (_backView4.hidden)
                _backView4.hidden = NO;

            _buttonMore.frame = _backView4.bounds;
            if (_buttonMore.hidden)
                _buttonMore.hidden = NO;
            [self layoutComplexButton:self.buttonMore isPortrait:YES];
        }
        
        _buttonFavorite.frame = _backView1.bounds;
        _buttonShare.frame = _backView2.bounds;
        _buttonDirection.frame = _backView3.bounds;

        [self layoutComplexButton:self.buttonFavorite isPortrait:YES];
        [self layoutComplexButton:self.buttonShare isPortrait:YES];
        [self layoutComplexButton:self.buttonDirection isPortrait:YES];
    }
    
}

- (void)layoutComplexButton:(UIButton*)button isPortrait:(BOOL)isPortrait
{

    CGFloat spacingExt = 18.0;
    if (!isPortrait)
        spacingExt = 30.0;
    

    // the space between the image and text
    CGFloat spacing = 6.0;
    
    // lower the text and push it left so it appears centered
    //  below the image
    CGSize imageSize = button.imageView.image.size;
    button.titleEdgeInsets = UIEdgeInsetsMake(
                                              0.0, - imageSize.width, - (spacingExt + spacing), 0.0);
    
    // raise the image and push it right so it appears centered
    //  above the text
    CGSize titleSize = [button.titleLabel.text sizeWithAttributes:@{NSFontAttributeName: button.titleLabel.font}];
    button.imageEdgeInsets = UIEdgeInsetsMake(
                                              - (titleSize.height + spacing), 0.0, -0.0, - titleSize.width);
    
    button.titleLabel.numberOfLines = 2;
    button.titleLabel.textAlignment = NSTextAlignmentCenter;
}

-(void)setTargetPoint:(OATargetPoint *)targetPoint
{
    _targetPoint = targetPoint;

    _imageView.image = _targetPoint.icon;
    [_addressLabel setText:_targetPoint.title];
    self.formattedLocation = [[[OsmAndApp instance] locationFormatterDigits] stringFromCoordinate:self.targetPoint.location];
    [_coordinateLabel setText:self.formattedLocation];
    
    _buttonDirection.enabled = _targetPoint.type != OATargetDestination;
    if (_targetPoint.type == OATargetParking)
    {
        BOOL parkingAddonSingle = [OAIAPHelper sharedInstance].functionalAddons.count == 1 && [((OAFunctionalAddon *)[OAIAPHelper sharedInstance].functionalAddons[0]).addonId isEqualToString:kId_Addon_Parking_Set];
        if (parkingAddonSingle)
            _buttonMore.enabled = NO;
    }
    else
    {
        _buttonMore.enabled = YES;
    }

    if (_targetPoint.type == OATargetFavorite)
        [_buttonFavorite setTitle:OALocalizedString(@"ctx_mnu_edit_fav") forState:UIControlStateNormal];
    else
        [_buttonFavorite setTitle:OALocalizedString(@"ctx_mnu_add_fav") forState:UIControlStateNormal];
}

-(void)setMapViewInstance:(UIView*)mapView {
    self.mapView = (OAMapRendererView *)mapView;
}

-(void)setNavigationController:(UINavigationController*)controller {
    self.navController = controller;
}

- (void)onFavoritesCollectionChanged
{
    if (_targetPoint.type == OATargetFavorite)
    {
        BOOL favoriteOnTarget = NO;
        for (const auto& favLoc : [OsmAndApp instance].favoritesCollection->getFavoriteLocations()) {
            
            int favLon = (int)(OsmAnd::Utilities::get31LongitudeX(favLoc->getPosition31().x) * 10000.0);
            int favLat = (int)(OsmAnd::Utilities::get31LatitudeY(favLoc->getPosition31().y) * 10000.0);
            
            if ((int)(_targetPoint.location.latitude * 10000.0) == favLat && (int)(_targetPoint.location.longitude * 10000.0) == favLon)
            {
                favoriteOnTarget = YES;
                break;
            }
        }
        
        if (!favoriteOnTarget)
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate targetHide];
            });
    }
}

- (void)onFavoriteLocationChanged:(const std::shared_ptr<const OsmAnd::IFavoriteLocation>)favoriteLocation
{
    if (_targetPoint.type == OATargetFavorite)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            UIColor* color = [UIColor colorWithRed:favoriteLocation->getColor().r/255.0 green:favoriteLocation->getColor().g/255.0 blue:favoriteLocation->getColor().b/255.0 alpha:1.0];
            OAFavoriteColor *favCol = [OADefaultFavorite nearestFavColor:color];
            
            _targetPoint.title = favoriteLocation->getTitle().toNSString();
            [_addressLabel setText:_targetPoint.title];
            _targetPoint.icon = [UIImage imageNamed:favCol.iconName];
            _imageView.image = _targetPoint.icon;
        });
    }
}

#pragma mark - Actions
- (IBAction)buttonFavoriteClicked:(id)sender {
    
    NSString *locText;
    if (self.isAddressFound)
        locText = self.targetPoint.title;
    else
        locText = self.formattedLocation;
    
    OAFavoriteItemViewController* favoriteViewController;
    if (_targetPoint.type == OATargetFavorite)
    {
        for (const auto& favLoc : [OsmAndApp instance].favoritesCollection->getFavoriteLocations())
        {
            int favLon = (int)(OsmAnd::Utilities::get31LongitudeX(favLoc->getPosition31().x) * 10000.0);
            int favLat = (int)(OsmAnd::Utilities::get31LatitudeY(favLoc->getPosition31().y) * 10000.0);
            
            if ((int)(_targetPoint.location.latitude * 10000.0) == favLat && (int)(_targetPoint.location.longitude * 10000.0) == favLon)
            {
                OAFavoriteItem* item = [[OAFavoriteItem alloc] init];
                item.favorite = favLoc;
                favoriteViewController = [[OAFavoriteItemViewController alloc] initWithFavoriteItem:item];
                break;
            }
        }
    }
    else
    {
        favoriteViewController = [[OAFavoriteItemViewController alloc] initWithLocation:self.targetPoint.location
                                                                               andTitle:locText];
    }
    
    if (favoriteViewController)
    {
        [self.navController pushViewController:favoriteViewController animated:YES];

        /*
        if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)
        {
            // For iPhone and iPod, push menu to navigation controller
            [self.navController pushViewController:favoriteViewController animated:YES];
        }
        else //if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
        {
            // For iPad, open menu in a popover with it's own navigation controller
            UINavigationController* navigationController = [[OANavigationController alloc] initWithRootViewController:favoriteViewController];
            UIPopoverController* popoverController = [[UIPopoverController alloc] initWithContentViewController:navigationController];
            
            [popoverController presentPopoverFromRect:CGRectMake(_targetPoint.touchPoint.x, _targetPoint.touchPoint.y, 0.0f, 0.0f)
                                               inView:self.mapView
                             permittedArrowDirections:UIPopoverArrowDirectionAny
                                             animated:YES];
        }
         */
    }
    
    [self.delegate targetPointAddFavorite];
}

- (IBAction)buttonShareClicked:(id)sender {

    // http://osmand.net/go.html?lat=12.6313&lon=-7.9955&z=8&title=New+York The location was shared with you by OsmAnd
    
    UIImage *image = [self.mapView getGLScreenshot];
    
    //NSString *title = [_targetPoint.title stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet alphanumericCharacterSet]];
    
    NSString *string = [NSString stringWithFormat:kShareLinkTemplate, _targetPoint.location.latitude, _targetPoint.location.longitude, _targetPoint.zoom];
    
    UIActivityViewController *activityViewController =
    [[UIActivityViewController alloc] initWithActivityItems:@[image, string]
                                      applicationActivities:nil];
    
    [self.navController presentViewController:activityViewController
                                     animated:YES
                                   completion:^{ }];

    [self.delegate targetPointShare];
}

- (IBAction)buttonDirectionClicked:(id)sender
{
    [self.delegate targetPointDirection];
}

- (IBAction)buttonMoreClicked:(id)sender
{
    NSArray *functionalAddons = [OAIAPHelper sharedInstance].functionalAddons;
    if (functionalAddons.count > 1)
    {
        NSMutableArray *titles = [NSMutableArray array];
        NSMutableArray *images = [NSMutableArray array];
        
        for (OAFunctionalAddon *addon in functionalAddons)
        {
            [titles addObject:addon.titleWide];
            [images addObject:addon.imageName];
        }
        
        [PXAlertView showAlertWithTitle:OALocalizedString(@"other_options")
                                message:nil
                            cancelTitle:OALocalizedString(@"shared_string_cancel")
                            otherTitles:titles
                            otherImages:images
                             completion:^(BOOL cancelled, NSInteger buttonIndex) {
                                 if (!cancelled)
                                     for (OAFunctionalAddon *addon in functionalAddons)
                                         if (addon.sortIndex == buttonIndex)
                                         {
                                             if ([addon.addonId isEqualToString:kId_Addon_TrackRecording_Add_Waypoint])
                                                 [self.delegate targetPointAddWaypoint];
                                             else if ([addon.addonId isEqualToString:kId_Addon_Parking_Set])
                                                 [self.delegate targetPointParking];
                                             break;
                                         }
                             }];
    }
    else if ([((OAFunctionalAddon *)functionalAddons[0]).addonId isEqualToString:kId_Addon_TrackRecording_Add_Waypoint])
    {
        [self.delegate targetPointAddWaypoint];
    }
    else if ([((OAFunctionalAddon *)functionalAddons[0]).addonId isEqualToString:kId_Addon_Parking_Set])
    {
        [self.delegate targetPointParking];
    }
}

- (IBAction)buttonShadowClicked:(id)sender
{
    [self.delegate targetGoToPoint];
}

- (IBAction)buttonCloseClicked:(id)sender
{
    [self.delegate targetHide];
}

@end
