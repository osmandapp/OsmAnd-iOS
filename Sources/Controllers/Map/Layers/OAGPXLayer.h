//
//  OAGPXLayer.h
//  OsmAnd
//
//  Created by Alexey Kulish on 11/06/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OASymbolMapLayer.h"
#import "OAContextMenuProvider.h"

#include <OsmAndCore/GeoInfoDocument.h>
#include <OsmAndCore/Map/VectorLinesCollection.h>
#include <OsmAndCore/Map/MapMarkersCollection.h>

#define kDefaultTrackColor 0xFFFF0000

@interface OAGPXLayer : OASymbolMapLayer<OAContextMenuProvider>

@property (nonatomic) QList<std::shared_ptr<const OsmAnd::GeoInfoDocument>> gpxDocs;

@property (nonatomic) std::shared_ptr<OsmAnd::VectorLinesCollection> linesCollection;
@property (nonatomic) std::shared_ptr<OsmAnd::MapMarkersCollection> markersCollection;

- (void) refreshGpxTracks:(QList<std::shared_ptr<const OsmAnd::GeoInfoDocument>>)gpxDocs;

@end
