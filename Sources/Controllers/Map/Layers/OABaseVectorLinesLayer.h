//
//  OABaseVectorLinesLayer.h
//  OsmAnd
//
//  Created by Paul on 17/01/2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OASymbolMapLayer.h"

#include <OsmAndCore/Map/VectorLinesCollection.h>

@interface OABaseVectorLinesLayer : OASymbolMapLayer

- (void) setVectorLineProvider:(std::shared_ptr<OsmAnd::VectorLinesCollection> &)collection;

@end
