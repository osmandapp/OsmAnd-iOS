//
//  OABaseVectorLinesLayer.h
//  OsmAnd
//
//  Created by Paul on 17/01/2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OASymbolMapLayer.h"

#include <OsmAndCore/Map/VectorLinesCollection.h>

#include <SkBitmap.h>

@interface OABaseVectorLinesLayer : OASymbolMapLayer

- (void) setVectorLineProvider:(std::shared_ptr<OsmAnd::VectorLinesCollection> &)collection;

- (std::shared_ptr<SkBitmap>) bitmapForColor:(UIColor *)color fileName:(NSString *)fileName;
- (std::shared_ptr<SkBitmap>) specialBitmapWithColor:(OsmAnd::ColorARGB)color;

@end
