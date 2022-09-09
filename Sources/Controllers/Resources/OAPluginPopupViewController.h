//
//  OAPluginPopupViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 23/07/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OASuperViewController.h"

typedef NS_ENUM(NSInteger, OAPluginPopupType)
{
    OAPluginPopupTypeDefault = -1,
    OAPluginPopupTypeProduct = 0,
    OAPluginPopupTypePlugin,
    OAPluginPopupTypeWorldMap,
    OAPluginPopupTypeNoInternet,
    OAPluginPopupTypeShowRegionOnMap,
};

@class OAWorldRegion, OAProduct;

@interface OAPluginPopupViewController : OASuperViewController

@property (weak, nonatomic) IBOutlet UIButton *closeButton;
@property (weak, nonatomic) IBOutlet UIImageView *icon;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UITextView *descTextView;
@property (weak, nonatomic) IBOutlet UIButton *okButton;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;

@property (nonatomic, readonly) OAPluginPopupType pluginPopupType;

- (instancetype)initWithType:(OAPluginPopupType)popupType;

- (void)show;
- (void)hide;

+ (void)showProductAlert:(OAProduct *)product afterPurchase:(BOOL)afterPurchase;
+ (void)askForPlugin:(NSString *)productIdentifier;

+ (void)showNoInternetConnectionFirst;
+ (void)hideNoInternetConnection;

+ (void)showRegionOnMap:(OAWorldRegion *)region;
+ (void)showOsmEditingDisabled;

@end
