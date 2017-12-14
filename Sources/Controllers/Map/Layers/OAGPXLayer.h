//
//  OAGPXLayer.h
//  OsmAnd
//
//  Created by Alexey Kulish on 11/06/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OASymbolMapLayer.h"

#include <OsmAndCore/GeoInfoDocument.h>

@interface OAGPXLayer : OASymbolMapLayer

- (void) refreshGpxTracks:(QList<std::shared_ptr<const OsmAnd::GeoInfoDocument>>)gpxDocs;

@end
