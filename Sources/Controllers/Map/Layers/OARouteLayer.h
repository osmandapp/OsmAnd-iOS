//
//  OARouteLayer.h
//  OsmAnd
//
//  Created by Alexey Kulish on 11/06/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OASymbolMapLayer.h"

#include <OsmAndCore/Map/GeoInfoPresenter.h>
#include <OsmAndCore/Map/MapPrimitiviser.h>

@interface OARouteLayer : OASymbolMapLayer

@property (nonatomic, readonly) int baseOrder;

- (void) refreshRoute:(std::shared_ptr<const OsmAnd::GeoInfoDocument>)routeDoc;

@end
