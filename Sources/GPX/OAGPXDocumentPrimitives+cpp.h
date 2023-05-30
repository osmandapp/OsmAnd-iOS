//
//  OAGPXDocumentPrimitives+cpp.h
//  OsmAnd
//
//  Created by Skalii on 30.05.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OAGPXDocumentPrimitives.h"

#include <routeDataBundle.h>
#include <OsmAndCore/GpxDocument.h>

@interface OAGpxExtensions(cpp)

- (NSArray<OAGpxExtension *> *)fetchExtension:(QList<OsmAnd::Ref<OsmAnd::GpxExtensions::GpxExtension>>)extensions;
- (void)fetchExtensions:(std::shared_ptr<OsmAnd::GpxExtensions>)extensions;
- (void)fillExtension:(const std::shared_ptr<OsmAnd::GpxExtensions::GpxExtension>&)extension ext:(OAGpxExtension *)e;
- (void)fillExtensions:(const std::shared_ptr<OsmAnd::GpxExtensions>&)extensions;

@end

@interface OAWptPt(cpp)
@property (nonatomic, assign) std::shared_ptr<OsmAnd::GpxDocument::WptPt> wpt;
@end

@interface OARouteSegment(cpp)

+ (OARouteSegment *)fromStringBundle:(const std::shared_ptr<RouteDataBundle> &)bundle;
- (std::shared_ptr<RouteDataBundle>)toStringBundle;

- (instancetype)initWithDictionary:(NSDictionary<NSString *, NSString *> *)dict;
- (instancetype)initWithRteSegment:(OsmAnd::Ref<OsmAnd::GpxDocument::RouteSegment> &)seg;

- (NSDictionary<NSString *, NSString *> *)toDictionary;

@end

@interface OARouteType(cpp)

+ (OARouteType *)fromStringBundle:(const std::shared_ptr<RouteDataBundle> &)bundle;
- (std::shared_ptr<RouteDataBundle>)toStringBundle;

- (instancetype)initWithDictionary:(NSDictionary<NSString *, NSString *> *)dict;
- (instancetype)initWithRteType:(OsmAnd::Ref<OsmAnd::GpxDocument::RouteType> &)type;

- (NSDictionary<NSString *, NSString *> *) toDictionary;

@end

@interface OATrkSegment(cpp)
@property (nonatomic, assign) std::shared_ptr<OsmAnd::GpxDocument::TrkSegment> trkseg;
@end

@interface OATrack(cpp)
@property (nonatomic, assign) std::shared_ptr<OsmAnd::GpxDocument::Track> trk;
@end

@interface OARoute(cpp)
@property (nonatomic, assign) std::shared_ptr<OsmAnd::GpxDocument::Route> rte;
@end
