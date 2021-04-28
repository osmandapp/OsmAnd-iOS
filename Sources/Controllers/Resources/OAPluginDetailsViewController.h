//
//  OAPluginDetailsViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 22/07/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OACompoundViewController.h"

@class OAProduct, OAPlugin;

@interface OAPluginDetailsViewController : OACompoundViewController

@property (weak, nonatomic) IBOutlet UIImageView *screenshot;

@property (weak, nonatomic) IBOutlet UIView *toolbarView;
@property (weak, nonatomic) IBOutlet UIImageView *gradient;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@property (weak, nonatomic) IBOutlet UIView *detailsView;
@property (weak, nonatomic) IBOutlet UIButton *priceButton;
@property (weak, nonatomic) IBOutlet UIImageView *icon;
@property (weak, nonatomic) IBOutlet UILabel *descLabel;
@property (weak, nonatomic) IBOutlet UITextView *descTextView;

@property (weak, nonatomic) IBOutlet UIView *bottomToolbarView;
@property (weak, nonatomic) IBOutlet UIButton *btnToolbarMaps;
@property (weak, nonatomic) IBOutlet UIButton *btnToolbarPlugins;
@property (weak, nonatomic) IBOutlet UIButton *btnToolbarPurchases;

@property (nonatomic, readonly) OAProduct *product;

- (instancetype)initWithProduct:(OAProduct *)product;
- (instancetype)initWithCustomPlugin:(OAPlugin *)plugin;

@property (nonatomic, assign) BOOL openFromSplash;
@property (nonatomic, assign) BOOL openFromCustomPlace;

@end
