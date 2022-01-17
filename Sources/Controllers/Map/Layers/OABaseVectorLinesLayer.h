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

@class OAGPXDocument;

@interface OABaseVectorLinesLayer : OASymbolMapLayer

- (void) setVectorLineProvider:(std::shared_ptr<OsmAnd::VectorLinesCollection> &)collection;

- (sk_sp<SkImage>) bitmapForColor:(UIColor *)color fileName:(NSString *)fileName;
- (sk_sp<SkImage>) specialBitmapWithColor:(OsmAnd::ColorARGB)color;

- (void) calculateSegmentsColor:(QList<OsmAnd::FColorARGB> &)colors attrName:(NSString *)attrName gpx:(OAGPXDocument *)gpx;

@end
