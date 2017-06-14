//
//  OAGPXLayer.h
//  OsmAnd
//
//  Created by Alexey Kulish on 11/06/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OARasterMapLayer.h"

#include <OsmAndCore/Map/GeoInfoPresenter.h>
#include <OsmAndCore/Map/MapPrimitiviser.h>

@interface OAGPXLayer : OARasterMapLayer

- (void) refreshGpxTracks:(QList<std::shared_ptr<const OsmAnd::GeoInfoDocument>>)gpxDocs mapPrimitiviser:(std::shared_ptr<OsmAnd::MapPrimitiviser>)mapPrimitiviser;

@end
