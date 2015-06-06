//
//  OAMapPanelViewController.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 8/20/13.
//  Copyright (c) 2013 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "OAMapViewController.h"
#import "OACommonTypes.h"
#import "OATargetPointView.h"

@class OAFavoriteItem;

@interface OAMapPanelViewController : UIViewController<OATargetPointViewDelegate>

- (instancetype)init;

@property (nonatomic, strong, readonly) OAMapViewController* mapViewController;
@property (nonatomic, strong, readonly) UIViewController* hudViewController;

- (void)prepareMapForReuse:(Point31)destinationPoint zoom:(CGFloat)zoom newAzimuth:(float)newAzimuth newElevationAngle:(float)newElevationAngle animated:(BOOL)animated;

- (void)prepareMapForReuse:(UIView *)destinationView mapBounds:(OAGpxBounds)mapBounds newAzimuth:(float)newAzimuth newElevationAngle:(float)newElevationAngle animated:(BOOL)animated;

- (void)doMapReuse:(UIViewController *)destinationViewController destinationView:(UIView *)destinationView;

- (void)modifyMapAfterReuse:(Point31)destinationPoint zoom:(CGFloat)zoom azimuth:(float)azimuth elevationAngle:(float)elevationAngle animated:(BOOL)animated;

- (void)modifyMapAfterReuse:(OAGpxBounds)mapBounds azimuth:(float)azimuth elevationAngle:(float)elevationAngle animated:(BOOL)animated;

- (void)closeMapSettings;
- (void)mapSettingsButtonClick:(id)sender;
- (void)searchButtonClick:(id)sender;

- (void)setTopControlsVisible:(BOOL)visible;
- (void)updateOverlayUnderlayView:(BOOL)show;

- (void)openTargetViewWithFavorite:(OAFavoriteItem *)item pushed:(BOOL)pushed;

@end
