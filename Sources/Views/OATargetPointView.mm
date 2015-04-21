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

@property (weak, nonatomic) IBOutlet UIButton *buttonShadow;
@property (weak, nonatomic) IBOutlet UIButton *buttonClose;

@property (weak, nonatomic) IBOutlet UIView *buttonsView;
@property (weak, nonatomic) IBOutlet UIView *backView1;
@property (weak, nonatomic) IBOutlet UIView *backView2;
@property (weak, nonatomic) IBOutlet UIView *backView3;

@property NSString* formattedLocation;
@property OAMapRendererView* mapView;
@property UINavigationController* navController;

@end

@implementation OATargetPointView

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


-(void)awakeFromNib {
    
    [_buttonShare setTitle:OALocalizedString(@"ctx_mnu_share") forState:UIControlStateNormal];
    [_buttonDirection setTitle:OALocalizedString(@"ctx_mnu_direction") forState:UIControlStateNormal];
    
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
    
    
    CGFloat textX = (_imageView.image ? 40.0 : 16.0) + (_targetPoint.type == OATargetDestination ? 10.0 : 0.0);
    
    if (landscape) {
        
        _addressLabel.frame = CGRectMake(textX, 12.0, DeviceScreenWidth - textX - 40.0 - 210.0, 21.0);
        _coordinateLabel.frame = CGRectMake(textX, 39.0, DeviceScreenWidth - textX - 40.0 - 210.0, 21.0);
        
        _buttonShadow.frame = CGRectMake(0.0, 0.0, DeviceScreenWidth - 210.0 - 50.0, h);
        _buttonClose.frame = CGRectMake(DeviceScreenWidth - 210.0 - 36.0, 0.0, 36.0, 36.0);

        _buttonsView.frame = CGRectMake(DeviceScreenWidth - 210.0, 0.0, 210.0, h);
        CGFloat backViewWidth = floor(_buttonsView.frame.size.width / 3.0);
        CGFloat x = 1.0;
        _backView1.frame = CGRectMake(x, 0.0, backViewWidth, _buttonsView.frame.size.height);
        x += backViewWidth + 1.0;
        _backView2.frame = CGRectMake(x, 0.0, backViewWidth, _buttonsView.frame.size.height);
        x += backViewWidth + 1.0;
        _backView3.frame = CGRectMake(x, 0.0, _buttonsView.frame.size.width - x, _buttonsView.frame.size.height);
        _buttonFavorite.frame = CGRectMake(_backView1.bounds.size.width / 2.0 - _buttonFavorite.bounds.size.width / 2.0, _backView1.bounds.size.height / 2.0 - _buttonFavorite.bounds.size.height / 2.0, _buttonFavorite.bounds.size.width, _buttonFavorite.bounds.size.height);
        _buttonShare.frame = CGRectMake(_backView2.bounds.size.width / 2.0 - _buttonShare.bounds.size.width / 2.0, _backView2.bounds.size.height / 2.0 - _buttonShare.bounds.size.height / 2.0, _buttonShare.bounds.size.width, _buttonFavorite.bounds.size.height);
        _buttonDirection.frame = CGRectMake(_backView3.bounds.size.width / 2.0 - _buttonFavorite.bounds.size.width / 2.0, _backView3.bounds.size.height / 2.0 - _buttonDirection.bounds.size.height / 2.0, _buttonDirection.bounds.size.width, _buttonDirection.bounds.size.height);
        
    } else {
        
        _addressLabel.frame = CGRectMake(textX, 12.0, DeviceScreenWidth - textX - 40.0, 21.0);
        _coordinateLabel.frame = CGRectMake(textX, 39.0, DeviceScreenWidth - textX - 40.0, 21.0);
        
        _buttonShadow.frame = CGRectMake(0.0, 0.0, DeviceScreenWidth - 50.0, 73.0);
        _buttonClose.frame = CGRectMake(DeviceScreenWidth - 36.0, 0.0, 36.0, 36.0);
        
        _buttonsView.frame = CGRectMake(0.0, 73.0, DeviceScreenWidth, 53.0);
        CGFloat backViewWidth = floor(_buttonsView.frame.size.width / 3.0);
        CGFloat x = 0.0;
        _backView1.frame = CGRectMake(x, 1.0, backViewWidth, _buttonsView.frame.size.height - 1.0);
        x += backViewWidth + 1.0;
        _backView2.frame = CGRectMake(x, 1.0, backViewWidth, _buttonsView.frame.size.height - 1.0);
        x += backViewWidth + 1.0;
        _backView3.frame = CGRectMake(x, 1.0, _buttonsView.frame.size.width - x, _buttonsView.frame.size.height - 1.0);
        _buttonFavorite.frame = CGRectMake(_backView1.bounds.size.width / 2.0 - _buttonFavorite.bounds.size.width / 2.0, _backView1.bounds.size.height / 2.0 - _buttonFavorite.bounds.size.height / 2.0, _buttonFavorite.bounds.size.width, _buttonFavorite.bounds.size.height);
        _buttonShare.frame = CGRectMake(_backView2.bounds.size.width / 2.0 - _buttonShare.bounds.size.width / 2.0, _backView2.bounds.size.height / 2.0 - _buttonShare.bounds.size.height / 2.0, _buttonShare.bounds.size.width, _buttonFavorite.bounds.size.height);
        _buttonDirection.frame = CGRectMake(_backView3.bounds.size.width / 2.0 - _buttonFavorite.bounds.size.width / 2.0, _backView3.bounds.size.height / 2.0 - _buttonDirection.bounds.size.height / 2.0, _buttonDirection.bounds.size.width, _buttonDirection.bounds.size.height);
    }
    
}

-(void)setTargetPoint:(OATargetPoint *)targetPoint
{
    _targetPoint = targetPoint;

    _imageView.image = _targetPoint.icon;
    [_addressLabel setText:_targetPoint.title];
    self.formattedLocation = [[[OsmAndApp instance] locationFormatterDigits] stringFromCoordinate:self.targetPoint.location];
    [_coordinateLabel setText:self.formattedLocation];
    
    _buttonDirection.enabled = _targetPoint.type != OATargetDestination;

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
    }
    
    [self.delegate targetPointAddFavorite];
}

- (IBAction)buttonShareClicked:(id)sender {

    // http://osmand.net/go.html?lat=12.6313&lon=-7.9955&z=8 The location was shared with you by OsmAnd
    
    //UIImage *image = [self.mapView getGLScreenshot];
    
    NSString *string = [NSString stringWithFormat:kShareLinkTemplate, _targetPoint.location.latitude, _targetPoint.location.longitude, _targetPoint.zoom];
    
    UIActivityViewController *activityViewController =
    [[UIActivityViewController alloc] initWithActivityItems:@[/*image,*/ string]
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

- (IBAction)buttonShadowClicked:(id)sender
{
    [self.delegate targetGoToPoint];
}

- (IBAction)buttonCloseClicked:(id)sender
{
    [self.delegate targetHide];
}

@end
