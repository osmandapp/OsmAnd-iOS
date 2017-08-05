//
//  OARouteLayer.h
//  OsmAnd
//
//  Created by Alexey Kulish on 11/06/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OARasterMapLayer.h"

#include <OsmAndCore/Map/GeoInfoPresenter.h>
#include <OsmAndCore/Map/MapPrimitiviser.h>

@interface OARouteLayer : OARasterMapLayer

- (void) refreshRoute:(std::shared_ptr<const OsmAnd::GeoInfoDocument>)routeDoc mapPrimitiviser:(std::shared_ptr<OsmAnd::MapPrimitiviser>)mapPrimitiviser;

@end
