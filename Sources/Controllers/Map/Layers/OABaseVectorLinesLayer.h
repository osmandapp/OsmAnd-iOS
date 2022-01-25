//
//  OABaseVectorLinesLayer.h
//  OsmAnd
//
//  Created by Paul on 17/01/2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OASymbolMapLayer.h"

#include <OsmAndCore/Map/VectorLinesCollection.h>
#include <SkImage.h>
#include <vector>

#define kDefaultWidthMultiplier 7

#define COLORIZATION_NONE 0
#define COLORIZATION_GRADIENT 1
#define COLORIZATION_SOLID 2

#define kOutlineColor OsmAnd::ColorARGB(150, 0, 0, 0)

@class OAGPXDocument, OAGpxTrkSeg;

struct RouteSegmentResult;

@interface OABaseVectorLinesLayer : OASymbolMapLayer

- (void) setVectorLineProvider:(std::shared_ptr<OsmAnd::VectorLinesCollection> &)collection;

- (sk_sp<SkImage>) bitmapForColor:(UIColor *)color fileName:(NSString *)fileName;
- (sk_sp<SkImage>) specialBitmapWithColor:(OsmAnd::ColorARGB)color;

- (void)calculateSegmentsColor:(QList<OsmAnd::FColorARGB> &)colors
                      attrName:(NSString *)attrName
                 segmentResult:(std::vector<std::shared_ptr<RouteSegmentResult>>)segs
                     segments:(NSArray<OAGpxTrkSeg *> *)segments;

@end
