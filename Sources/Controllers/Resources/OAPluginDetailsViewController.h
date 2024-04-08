//
//  OAPluginDetailsViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 22/07/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OABaseNavbarViewController.h"

@class OAProduct, OAPlugin, OACustomPlugin, OAOnlinePlugin;

@protocol OAPluginDetailsDelegate

- (void)onCustomPluginDeleted;

@end

@interface OAPluginDetailsViewController : OABaseNavbarViewController

@property (weak, nonatomic) IBOutlet UIImageView *screenshot;
@property (weak, nonatomic) IBOutlet UIView *detailsView;
@property (weak, nonatomic) IBOutlet UIButton *priceButton;
@property (weak, nonatomic) IBOutlet UIImageView *icon;
@property (weak, nonatomic) IBOutlet UILabel *descLabel;
@property (weak, nonatomic) IBOutlet UITextView *descTextView;
@property (weak, nonatomic) IBOutlet UIButton *buttonDeleteCustomPlugin;

@property (nonatomic, readonly) OAProduct *product;
@property (nonatomic) id<OAPluginDetailsDelegate> delegate;

- (instancetype) initWithProduct:(OAProduct *)product;
- (instancetype) initWithCustomPlugin:(OACustomPlugin *)plugin;
- (instancetype) initWithOnlinePlugin:(OAOnlinePlugin *)plugin;

@end
