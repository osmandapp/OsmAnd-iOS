//
//  OAGPXPrimitivesNativeWrapper.h
//  OsmAnd
//
//  Created by Skalii on 26.05.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OAGPXDocumentPrimitives.h"

#include <routeDataBundle.h>
#include <OsmAndCore/GpxDocument.h>

@class OAGpxExtension, OAGpxExtensions;

@interface OAGpxExtensionsNativeWrapper : NSObject

- (NSArray<OAGpxExtension *> *)fetchExtension:(QList<OsmAnd::Ref<OsmAnd::GpxExtensions::GpxExtension>>)extensions
                            withExtensionsObj:(OAGpxExtensions *)obj;

- (void)fetchExtensions:(std::shared_ptr<OsmAnd::GpxExtensions>)extensions
      withExtensionsObj:(OAGpxExtensions *)obj;

- (void)fillExtension:(const std::shared_ptr<OsmAnd::GpxExtensions::GpxExtension>&)extension ext:(OAGpxExtension *)e
    withExtensionsObj:(OAGpxExtensions *)obj;

- (void)fillExtensions:(const std::shared_ptr<OsmAnd::GpxExtensions>&)extensions
     withExtensionsObj:(OAGpxExtensions *)obj;

@end

@interface OAWptPtNativeWrapper : OAGpxExtensionsNativeWrapper
@property (nonatomic, assign) std::shared_ptr<OsmAnd::GpxDocument::WptPt> wpt;
@end

@interface OARouteSegmentNativeWrapper : NSObject

@property (nonatomic) NSString *identifier;
@property (nonatomic) NSString *length;
@property (nonatomic) NSString *startTrackPointIndex;
@property (nonatomic) NSString *segmentTime;
@property (nonatomic) NSString *speed;
@property (nonatomic) NSString *turnType;
@property (nonatomic) NSString *turnAngle;
@property (nonatomic) NSString *types;
@property (nonatomic) NSString *pointTypes;
@property (nonatomic) NSString *names;

- (instancetype)initWithDictionary:(NSDictionary<NSString *,NSString *> *)dict;
- (instancetype)initWithRteSegment:(OsmAnd::Ref<OsmAnd::GpxDocument::RouteSegment> &)seg;
- (instancetype)initWithStringBundle:(const std::shared_ptr<RouteDataBundle> &)bundle;

- (NSDictionary<NSString *,NSString *> *)toDictionary;
- (std::shared_ptr<RouteDataBundle>)toStringBundle;

@end

@interface OARouteTypeNativeWrapper : NSObject

@property (nonatomic) NSString *tag;
@property (nonatomic) NSString *value;

- (instancetype)initWithDictionary:(NSDictionary<NSString *, NSString *> *)dict;
- (instancetype)initWithRteType:(OsmAnd::Ref<OsmAnd::GpxDocument::RouteType> &)type;
- (instancetype)initWithStringBundle:(const std::shared_ptr<RouteDataBundle> &)bundle;

- (NSDictionary<NSString *, NSString *> *)toDictionary;
- (std::shared_ptr<RouteDataBundle>)toStringBundle;

@end

@interface OATrkSegmentNativeWrapper : OAGpxExtensionsNativeWrapper
@property (nonatomic, assign) std::shared_ptr<OsmAnd::GpxDocument::TrkSegment> trkseg;
@end

@interface OATrackNativeWrapper : OAGpxExtensionsNativeWrapper
@property (nonatomic, assign) std::shared_ptr<OsmAnd::GpxDocument::Track> trk;
@end

@interface OARouteNativeWrapper : OAGpxExtensionsNativeWrapper
@property (nonatomic, assign) std::shared_ptr<OsmAnd::GpxDocument::Route> rte;
@end

@interface OAGPXDocumentNativeWrapper : OAGpxExtensionsNativeWrapper

- (instancetype)initWithGpxDocument:(std::shared_ptr<OsmAnd::GpxDocument>)gpxDocument;

- (const std::shared_ptr<OsmAnd::GpxDocument> &)getGpxDocument;
- (const std::shared_ptr<OsmAnd::GpxDocument> &)loadGpxDocument:(NSString *)fileName;

+ (OAWptPt *)fetchWpt:(std::shared_ptr<OsmAnd::GpxDocument::WptPt>)mark;
+ (void)fillWpt:(std::shared_ptr<OsmAnd::GpxDocument::WptPt>)wpt usingWpt:(OAWptPt *)w;
+ (void)fillMetadata:(std::shared_ptr<OsmAnd::GpxDocument::Metadata>)meta usingMetadata:(OAMetadata *)m;
+ (void)fillTrack:(std::shared_ptr<OsmAnd::GpxDocument::Track>)trk usingTrack:(OATrack *)t;
+ (void)fillRoute:(std::shared_ptr<OsmAnd::GpxDocument::Route>)rte usingRoute:(OARoute *)r;
+ (NSArray *)fetchLinks:(QList<OsmAnd::Ref<OsmAnd::GpxDocument::Link>>)links;
+ (void)fillLinks:(QList<OsmAnd::Ref<OsmAnd::GpxDocument::Link>>&)links linkArray:(NSArray *)linkArray;

@end
