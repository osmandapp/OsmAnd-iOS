//
//  OAMapLayer.h
//  OsmAnd
//
//  Created by Alexey Kulish on 08/06/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OsmAndApp.h"
#import "OAMapLayersConfiguration.h"

static const float ICON_VISIBLE_PART_RATIO = 0.45;
static const float TOUCH_RADIUS_MULTIPLIER = 1.5;

@class OAMapViewController, OAMapRendererView;

@interface OAMapLayer : NSObject

@property (nonatomic, readonly) NSString *layerId;

@property (nonatomic, readonly) OsmAndAppInstance app;
@property (nonatomic, readonly) OAMapViewController *mapViewController;
@property (nonatomic, readonly) OAMapRendererView *mapView;
@property (nonatomic, readonly) BOOL nightMode;
@property (nonatomic, readonly) CGFloat displayDensityFactor;
@property (nonatomic, readonly) int baseOrder;
@property (nonatomic) int pointsOrder;
@property (nonatomic) BOOL invalidated;

- (instancetype) initWithMapViewController:(OAMapViewController *)mapViewController;
- (instancetype) initWithMapViewController:(OAMapViewController *)mapViewController baseOrder:(int)baseOrder;
- (instancetype) initWithMapViewController:(OAMapViewController *)mapViewController baseOrder:(int)baseOrder pointsOrder:(int)pointsOrder;

- (void) initLayer;
- (void) deinitLayer;

- (void) resetLayer;
- (BOOL) updateLayer;

- (void) show;
- (void) hide;

- (void) onMapFrameAnimatorsUpdated;
- (void) onMapFrameRendered;
- (void) didReceiveMemoryWarning;

- (CLLocationCoordinate2D) getTouchPointCoord:(CGPoint)touchPoint;

- (int) getScaledTouchRadius:(int)radiusPoi;
- (int) getDefaultRadiusPoi;

- (BOOL) isVisible;
- (int)pointOrder:(id)object;

@end
