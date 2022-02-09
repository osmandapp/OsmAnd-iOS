//
//  OAGpxAppearanceInfo.h
//  OsmAnd
//
//  Created by Anna Bibyk on 29.01.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OAGPXDatabase.h"

@interface OAGpxAppearanceInfo : NSObject

@property (nonatomic) NSString *width;
//public GradientScaleType scaleType;
@property (nonatomic) NSInteger color;
@property (nonatomic) NSString *coloringType;
@property (nonatomic) NSInteger gradientSpeedColor;
@property (nonatomic) NSInteger gradientSlopeColor;
@property (nonatomic) EOAGpxSplitType splitType;
@property (nonatomic) CGFloat splitInterval;
@property (nonatomic) BOOL showArrows;
@property (nonatomic) BOOL showStartFinish;

@property (nonatomic) NSInteger timeSpan;
@property (nonatomic) NSInteger wptPoints;
@property (nonatomic) CGFloat totalDistance;

- (instancetype) initWithItem:(OAGPX *)dataItem;
- (void) toJson:(id)json;

+ (OAGpxAppearanceInfo *) fromJson:(id)json;

@end
