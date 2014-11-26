//
//  OAFavoriteItemViewController.h
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 07.11.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OASuperViewController.h"
#import "OAFavoriteItem.h"
#import <CoreLocation/CoreLocation.h>

#import "OAMapRendererViewProtocol.h"
#import "OAObservable.h"
#import "OAAppSettings.h"

@interface OAFavoriteItemViewController : OASuperViewController<UITextFieldDelegate>

@property (strong, nonatomic) OAFavoriteItem* favorite;
@property (assign, nonatomic) CLLocationCoordinate2D location;
@property (assign, nonatomic) BOOL newFavorite;

@property (weak, nonatomic) IBOutlet UIButton *saveRemoveButton;
@property (weak, nonatomic) IBOutlet UILabel *favoriteDistance;
@property (weak, nonatomic) IBOutlet UIImageView *favoriteDirection;

@property (weak, nonatomic) IBOutlet UIButton *favoriteNameButton;
@property (weak, nonatomic) IBOutlet UIButton *favoriteColorButton;
@property (weak, nonatomic) IBOutlet UIButton *favoriteGroupButton;

@property (weak, nonatomic) IBOutlet UIButton *favoritesButtonView;
@property (weak, nonatomic) IBOutlet UIButton *gpxButtonView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;

@property (weak, nonatomic) IBOutlet UIView *favoriteColorView;
@property (weak, nonatomic) IBOutlet UILabel *favoriteColorLabel;
@property (weak, nonatomic) IBOutlet UILabel *favoriteGroupView;
@property (weak, nonatomic) IBOutlet UIView *mapView;
@property (weak, nonatomic) IBOutlet UIView *distanceDirectionHolderView;

- (id)initWithFavoriteItem:(OAFavoriteItem*)favorite;
- (id)initWithLocation:(CLLocationCoordinate2D)location andTitle:(NSString*)formattedLocation;
- (IBAction)menuFavoriteClicked:(id)sender;
- (IBAction)menuGPXClicked:(id)sender;




@property(readonly) CGFloat displayDensityFactor;

@property(readonly) OAObservable* framePreparedObservable;

#if defined(OSMAND_IOS_DEV)
@property(nonatomic) BOOL hideStaticSymbols;

@property(nonatomic) BOOL forceDisplayDensityFactor;
@property(nonatomic) CGFloat forcedDisplayDensityFactor;
#endif // defined(OSMAND_IOS_DEV)


@end
