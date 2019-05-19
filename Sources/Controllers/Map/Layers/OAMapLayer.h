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

@class OAMapViewController, OAMapRendererView;

@interface OAMapLayer : NSObject

@property (nonatomic, readonly) NSString *layerId;

@property (nonatomic, readonly) OsmAndAppInstance app;
@property (nonatomic, readonly) OAMapViewController *mapViewController;
@property (nonatomic, readonly) OAMapRendererView *mapView;

- (instancetype) initWithMapViewController:(OAMapViewController *)mapViewController;

- (void) initLayer;
- (void) deinitLayer;

- (void) resetLayer;
- (BOOL) updateLayer;

- (void) show;
- (void) hide;

- (void) onMapFrameRendered;
- (void) didReceiveMemoryWarning;

- (void) showProgressHUD;
- (void) hideProgressHUD;

- (CLLocationCoordinate2D) getTouchPointCoord:(CGPoint)touchPoint;

@end
