//
//  OALanesDrawable.h
//  OsmAnd
//
//  Created by Alexey Kulish on 07/11/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//
//  OsmAnd/src/net/osmand/plus/views/mapwidgets/RouteInfoWidgetsFactory.java
//  git revision 20fbb153804c15d7a2cb09a9315ed1a15f301f3b

#import <UIKit/UIKit.h>
#include <vector>

@interface OALanesDrawable : UIView

@property (nonatomic) float scaleCoefficient;
@property (nonatomic) float miniCoeff;
@property (nonatomic) BOOL leftSide;
@property (nonatomic) BOOL imminent;

@property (nonatomic, readonly) CGFloat height;
@property (nonatomic, readonly) CGFloat width;
@property (nonatomic, readonly) CGFloat delta;

- (instancetype) initWithScaleCoefficient:(float)scaleCoefficient;

- (std::vector<int>&) getLanes;
- (void) setLanes:(std::vector<int>)lanes;
- (void) updateBounds;

@end
