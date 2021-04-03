//
//  OAToolbarViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 06/02/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OAMapModeHeaders.h"

#define DISCOUNT_TOOLBAR_PRIORITY 20
#define TRANSPORT_ROUTE_TOOLBAR_PRIORITY 30
#define SEARCH_TOOLBAR_PRIORITY 50
#define DESTINATIONS_TOOLBAR_PRIORITY 100

typedef NS_ENUM(NSInteger, EOAToolbarAttentionLevel)
{
    EOAToolbarAttentionLevelNormal = 0,
    EOAToolbarAttentionLevelHigh,
};

@class OAToolbarViewController;

@protocol OAToolbarViewControllerProtocol
@required

- (CGFloat) toolbarTopPosition;
- (void) toolbarLayoutDidChange:(OAToolbarViewController *)toolbarController animated:(BOOL)animated;
- (void) toolbarHide:(OAToolbarViewController *)toolbarController;

@end

@interface OAToolbarViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIView *navBarView;
@property (weak, nonatomic) id<OAToolbarViewControllerProtocol> delegate;
@property (nonatomic) BOOL showOnTop;

- (int) getPriority;
- (EOAToolbarAttentionLevel) getAttentionLevel;

- (void) onViewWillAppear:(EOAMapHudType)mapHudType;
- (void) onViewDidAppear:(EOAMapHudType)mapHudType;
- (void) onViewWillDisappear:(EOAMapHudType)mapHudType;

- (void) onMapAzimuthChanged:(id)observable withKey:(id)key andValue:(id)value;
- (void) onMapChanged:(id)observable withKey:(id)key;

- (void) updateFrame:(BOOL)animated;

- (UIStatusBarStyle) getPreferredStatusBarStyle;
- (UIColor *) getStatusBarColor;

@end
