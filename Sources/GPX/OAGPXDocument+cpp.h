//
//  OAGPXDocument+cpp.h
//  OsmAnd
//
//  Created by Skalii on 30.05.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OAGPXDocument.h"

#include <OsmAndCore/GpxDocument.h>

@interface OAGPXDocument(cpp)

- (instancetype)initWithGpxDocument:(std::shared_ptr<OsmAnd::GpxDocument>)gpxDocument;

- (BOOL)fetch:(std::shared_ptr<OsmAnd::GpxDocument>)gpxDocument;

+ (OAWptPt *)fetchWpt:(std::shared_ptr<OsmAnd::GpxDocument::WptPt>)mark;
+ (void)fillWpt:(std::shared_ptr<OsmAnd::GpxDocument::WptPt>)wpt usingWpt:(OAWptPt *)w;
+ (void)fillMetadata:(std::shared_ptr<OsmAnd::GpxDocument::Metadata>)meta usingMetadata:(OAMetadata *)m;
+ (void)fillTrack:(std::shared_ptr<OsmAnd::GpxDocument::Track>)trk usingTrack:(OATrack *)t;
+ (void)fillRoute:(std::shared_ptr<OsmAnd::GpxDocument::Route>)rte usingRoute:(OARoute *)r;

+ (void)fillLinks:(QList<OsmAnd::Ref<OsmAnd::GpxDocument::Link>>&)links linkArray:(NSArray *)linkArray;
+ (void)fillExtension:(const std::shared_ptr<OsmAnd::GpxExtensions::GpxExtension>&)extension ext:(OAGpxExtension *)e;
+ (void)fillExtensions:(const std::shared_ptr<OsmAnd::GpxExtensions>&)extensions ext:(OAGpxExtensions *)ext;

@end
