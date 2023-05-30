//
//  OAGPXPrimitivesNativeWrapper.mm
//  OsmAnd Maps
//
//  Created by Skalii on 26.05.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OAGPXPrimitivesNativeWrapper.h"
#import "OAGPXDocumentPrimitives.h"

#include <routeDataBundle.h>
#include <OsmAndCore/QKeyValueIterator.h>

@implementation OAGpxExtensionsNativeWrapper

- (NSArray<OAGpxExtension *> *)fetchExtension:(QList<OsmAnd::Ref<OsmAnd::GpxExtensions::GpxExtension>>)extensions
                            withExtensionsObj:(OAGpxExtensions *)obj
{
    if (!extensions.isEmpty())
    {
        NSMutableArray<OAGpxExtension *> *extensionsArray = [NSMutableArray array];
        for (const auto &ext: extensions)
        {
            OAGpxExtension *e = [[OAGpxExtension alloc] init];
            e.name = ext->name.toNSString().lowerCase;
            e.value = ext->value.toNSString();
            if (!ext->attributes.isEmpty())
            {
                NSMutableDictionary *dict = [NSMutableDictionary dictionary];
                for (const auto &entry: OsmAnd::rangeOf(OsmAnd::constOf(ext->attributes)))
                {
                    dict[entry.key().toNSString()] = entry.value().toNSString();
                }
                e.attributes = dict;
            }
            e.subextensions = [obj.wrapper fetchExtension:ext->subextensions withExtensionsObj:obj];
            [extensionsArray addObject:e];
        }
        return extensionsArray;
    }
    return @[];
}

- (void)fetchExtensions:(std::shared_ptr<OsmAnd::GpxExtensions>)extensions
      withExtensionsObj:(OAGpxExtensions *)obj
{
    obj.value = extensions->value.toNSString();
    if (!extensions->attributes.isEmpty()) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        for (const auto &entry: OsmAnd::rangeOf(OsmAnd::constOf(extensions->attributes))) {
            [dict setObject:entry.value().toNSString() forKey:entry.key().toNSString()];
        }
        obj.attributes = dict;
    }

    obj.extensions = [obj.wrapper fetchExtension:extensions->extensions withExtensionsObj:obj];
}

- (void)fillExtension:(const std::shared_ptr<OsmAnd::GpxExtensions::GpxExtension>&)extension ext:(OAGpxExtension *)e
    withExtensionsObj:(OAGpxExtensions *)obj
{
    extension->name = QString::fromNSString(e.name);
    extension->value = QString::fromNSString(e.value);
    for (NSString *key in e.attributes.allKeys)
    {
        extension->attributes[QString::fromNSString(key)] = QString::fromNSString(e.attributes[key]);
    }
    for (OAGpxExtension *es in e.subextensions)
    {
        std::shared_ptr<OsmAnd::GpxExtensions::GpxExtension> subextension(new OsmAnd::GpxExtensions::GpxExtension());
        [obj.wrapper fillExtension:subextension ext:es withExtensionsObj:obj];
        extension->subextensions.push_back(subextension);
        subextension.reset();
    }
}

- (void)fillExtensions:(const std::shared_ptr<OsmAnd::GpxExtensions>&)extensions
     withExtensionsObj:(OAGpxExtensions *)obj
{
    extensions->extensions.clear();
    for (OAGpxExtension *e in obj.extensions)
    {
        std::shared_ptr<OsmAnd::GpxExtensions::GpxExtension> extension(new OsmAnd::GpxExtensions::GpxExtension());
        [obj.wrapper fillExtension:extension ext:e withExtensionsObj:obj];
        extensions->extensions.push_back(extension);
        extension.reset();
    }
}

@end

@implementation OAWptPtNativeWrapper
@end

@implementation OARouteSegmentNativeWrapper

- (instancetype)initWithDictionary:(NSDictionary<NSString *,NSString *> *)dict
{
    self = [super init];
    if (self)
    {
        _identifier = dict[@"id"];
        _length = dict[@"length"];
        _startTrackPointIndex = dict[@"startTrkptIdx"];
        _segmentTime = dict[@"segmentTime"];
        _speed = dict[@"speed"];
        _turnType = dict[@"turnType"];
        _turnAngle = dict[@"turnAngle"];
        _types = dict[@"types"];
        _pointTypes = dict[@"pointTypes"];
        _names = dict[@"names"];
    }
    return self;
}

- (instancetype)initWithRteSegment:(OsmAnd::Ref<OsmAnd::GpxDocument::RouteSegment> &)seg
{
    self = [super init];
    if (self)
    {
        _identifier = seg->id.toNSString();
        _length = seg->length.toNSString();
        _startTrackPointIndex = seg->startTrackPointIndex.toNSString();
        _segmentTime = seg->segmentTime.toNSString();
        _speed = seg->speed.toNSString();
        _turnType = seg->turnType.toNSString();
        _turnAngle = seg->turnAngle.toNSString();
        _types = seg->types.toNSString();
        _pointTypes = seg->pointTypes.toNSString();
        _names = seg->names.toNSString();
    }
    return self;
}

- (instancetype)initWithStringBundle:(const std::shared_ptr<RouteDataBundle> &)bundle
{
    self = [super init];
    if (self)
    {
        _identifier = [NSString stringWithUTF8String:bundle->getString("id", "").c_str()];
        _length = [NSString stringWithUTF8String:bundle->getString("length", "").c_str()];
        _startTrackPointIndex = [NSString stringWithUTF8String:bundle->getString("startTrkptIdx", "").c_str()];
        _segmentTime = [NSString stringWithUTF8String:bundle->getString("segmentTime", "").c_str()];
        _speed = [NSString stringWithUTF8String:bundle->getString("speed", "").c_str()];
        _turnType = [NSString stringWithUTF8String:bundle->getString("turnType", "").c_str()];
        _turnAngle = [NSString stringWithUTF8String:bundle->getString("turnAngle", "").c_str()];
        _types = [NSString stringWithUTF8String:bundle->getString("types", "").c_str()];
        _pointTypes = [NSString stringWithUTF8String:bundle->getString("pointTypes", "").c_str()];
        _names = [NSString stringWithUTF8String:bundle->getString("names", "").c_str()];
    }
    return self;
}

- (void)addIfValueNotEmpty:(NSMutableDictionary<NSString *, NSString *> *)dict key:(NSString *)key value:(NSString *)value
{
    if (value.length > 0)
        dict[key] = value;
}

- (NSDictionary<NSString *,NSString *> *)toDictionary
{
    NSMutableDictionary<NSString *, NSString *> *res = [NSMutableDictionary new];
    [self addIfValueNotEmpty:res key:@"id" value:_identifier];
    [self addIfValueNotEmpty:res key:@"length" value:_length];
    [self addIfValueNotEmpty:res key:@"startTrkptIdx" value:_startTrackPointIndex];
    [self addIfValueNotEmpty:res key:@"segmentTime" value:_segmentTime];
    [self addIfValueNotEmpty:res key:@"speed" value:_speed];
    [self addIfValueNotEmpty:res key:@"turnType" value:_turnType];
    [self addIfValueNotEmpty:res key:@"turnAngle" value:_turnAngle];
    [self addIfValueNotEmpty:res key:@"types" value:_types];
    [self addIfValueNotEmpty:res key:@"pointTypes" value:_pointTypes];
    [self addIfValueNotEmpty:res key:@"names" value:_names];
    return res;
}

- (void)addToBundleIfNotNull:(const string&)key value:(NSString *)value bundle:(std::shared_ptr<RouteDataBundle> &)bundle
{
    if (value)
        bundle->put(key, value.UTF8String);
}

- (std::shared_ptr<RouteDataBundle>)toStringBundle
{
    auto bundle = std::make_shared<RouteDataBundle>();
    [self addToBundleIfNotNull:"id" value:_identifier bundle:bundle];
    [self addToBundleIfNotNull:"length" value:_length bundle:bundle];
    [self addToBundleIfNotNull:"startTrkptIdx" value:_startTrackPointIndex bundle:bundle];
    [self addToBundleIfNotNull:"segmentTime" value:_segmentTime bundle:bundle];
    [self addToBundleIfNotNull:"speed" value:_speed bundle:bundle];
    [self addToBundleIfNotNull:"turnType" value:_turnType bundle:bundle];
    [self addToBundleIfNotNull:"turnAngle" value:_turnAngle bundle:bundle];
    [self addToBundleIfNotNull:"types" value:_types bundle:bundle];
    [self addToBundleIfNotNull:"pointTypes" value:_pointTypes bundle:bundle];
    [self addToBundleIfNotNull:"names" value:_names bundle:bundle];
    return bundle;
}

@end

@implementation OARouteTypeNativeWrapper

- (instancetype)initWithDictionary:(NSDictionary<NSString *, NSString *> *)dict
{
    self = [super init];
    if (self)
    {
        _tag = dict[@"t"];
        _value = dict[@"v"];
    }
    return self;
}

- (instancetype)initWithRteType:(OsmAnd::Ref<OsmAnd::GpxDocument::RouteType> &)type
{
    self = [super init];
    if (self)
    {
        _tag = type->tag.toNSString();
        _value = type->value.toNSString();
    }
    return self;
}

- (instancetype)initWithStringBundle:(const std::shared_ptr<RouteDataBundle> &)bundle
{
    self = [super init];
    if (self)
    {
        _tag = [NSString stringWithUTF8String:bundle->getString("t", "").c_str()];
        _value = [NSString stringWithUTF8String:bundle->getString("v", "").c_str()];
    }
    return self;
}

- (NSDictionary<NSString *, NSString *> *)toDictionary
{
    return @{ @"t" : _tag, @"v" : _value };
}

- (std::shared_ptr<RouteDataBundle>)toStringBundle
{
    auto bundle = std::make_shared<RouteDataBundle>();
    if (_tag)
        bundle->put("t", _tag.UTF8String);
    if (_value)
        bundle->put("v", _value.UTF8String);
    return bundle;
}

@end

@implementation OATrkSegmentNativeWrapper
@end

@implementation OATrackNativeWrapper
@end

@implementation OARouteNativeWrapper
@end

@implementation OAGPXDocumentNativeWrapper
{
    std::shared_ptr<OsmAnd::GpxDocument> _gpxDocument;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _gpxDocument.reset(new OsmAnd::GpxDocument());
    }
    return self;
}

- (instancetype)initWithGpxDocument:(std::shared_ptr<OsmAnd::GpxDocument>)gpxDocument
{
    self = [super init];
    if (self)
    {
        _gpxDocument = gpxDocument;
    }
    return self;
}

- (const std::shared_ptr<OsmAnd::GpxDocument> &)getGpxDocument
{
    return _gpxDocument;
}

- (const std::shared_ptr<OsmAnd::GpxDocument> &)loadGpxDocument:(NSString *)fileName
{
    _gpxDocument = OsmAnd::GpxDocument::loadFrom(QString::fromNSString(fileName));
    return _gpxDocument;
}

+ (OAWptPt *)fetchWpt:(std::shared_ptr<OsmAnd::GpxDocument::WptPt>)mark
{
    OAWptPt *wptPt = [[OAWptPt alloc] init];
    wptPt.position = CLLocationCoordinate2DMake(mark->position.latitude, mark->position.longitude);
    wptPt.name = mark->name.toNSString();
    wptPt.desc = mark->description.toNSString();
    wptPt.elevation = mark->elevation;
    wptPt.time = mark->timestamp.toSecsSinceEpoch();
    wptPt.comment = mark->comment.toNSString();
    wptPt.type = mark->type.toNSString();
    wptPt.horizontalDilutionOfPrecision = mark->horizontalDilutionOfPrecision;
    wptPt.verticalDilutionOfPrecision = mark->verticalDilutionOfPrecision;
    wptPt.links = [self.class fetchLinks:mark->links];
    wptPt.speed = mark->speed;
    wptPt.heading = mark->heading;

    [wptPt.wrapper fetchExtensions:mark withExtensionsObj:wptPt];
    for (OAGpxExtension *e in wptPt.extensions)
    {
        if ([e.name isEqualToString:@"color"])
            [wptPt setColor:[OAUtilities colorToNumberFromString:e.value]];
    }

    return wptPt;
}

+ (void)fillWpt:(std::shared_ptr<OsmAnd::GpxDocument::WptPt>)wpt usingWpt:(OAWptPt *)w
{
    wpt->position.latitude = w.position.latitude;
    wpt->position.longitude = w.position.longitude;

    if (!isnan(w.elevation))
        wpt->elevation = w.elevation;

    wpt->timestamp = w.time > 0 ? QDateTime::fromTime_t(w.time).toUTC() : QDateTime().toUTC();

    if (w.name)
        wpt->name = QString::fromNSString(w.name);
    if (w.desc)
        wpt->description = QString::fromNSString(w.desc);

    [self fillLinks:wpt->links linkArray:w.links];

    if (w.type)
        wpt->type = QString::fromNSString(w.type);
    if (w.comment)
        wpt->comment = QString::fromNSString(w.comment);
    if (!isnan(w.horizontalDilutionOfPrecision))
        wpt->horizontalDilutionOfPrecision = w.horizontalDilutionOfPrecision;
    if (!isnan(w.verticalDilutionOfPrecision))
        wpt->verticalDilutionOfPrecision = w.verticalDilutionOfPrecision;
    if (!isnan(w.heading))
        wpt->heading = w.heading;
    if (w.speed > 0)
        wpt->speed = w.speed;

    OAGpxExtensions *extensions = [[OAGpxExtensions alloc] init];
    NSMutableArray<OAGpxExtension *> *extArray = [w.extensions mutableCopy];
    NSString *profile = [w getProfileType];
    if ([GAP_PROFILE_TYPE isEqualToString:profile])
    {
        OAGpxExtension *profileExtension = [w getExtensionByKey:PROFILE_TYPE_EXTENSION];
        [extArray removeObject:profileExtension];
    }

    extensions.extensions = extArray;
    [extensions.wrapper fillExtensions:wpt withExtensionsObj:extensions];
}

+ (void)fillMetadata:(std::shared_ptr<OsmAnd::GpxDocument::Metadata>)meta usingMetadata:(OAMetadata *)m
{
    meta->name = QString::fromNSString(m.name);
    meta->description = QString::fromNSString(m.desc);
    meta->timestamp = m.time > 0 ? QDateTime::fromTime_t(m.time).toUTC() : QDateTime().toUTC();
    
    [self fillLinks:meta->links linkArray:m.links];
    
    [m.wrapper fillExtensions:meta withExtensionsObj:m];
}

+ (void)fillTrack:(std::shared_ptr<OsmAnd::GpxDocument::Track>)trk usingTrack:(OATrack *)t
{
    std::shared_ptr<OsmAnd::GpxDocument::WptPt> trkpt;
    std::shared_ptr<OsmAnd::GpxDocument::TrkSegment> trkseg;

    if (t.name)
        trk->name = QString::fromNSString(t.name);
    if (t.desc)
        trk->description = QString::fromNSString(t.desc);

    for (OATrkSegment *s in t.segments)
    {
        trkseg.reset(new OsmAnd::GpxDocument::TrkSegment());

        if (s.name)
            trkseg->name = QString::fromNSString(s.name);

        for (OAWptPt *p in s.points)
        {
            trkpt.reset(new OsmAnd::GpxDocument::WptPt());
            [self fillWpt:trkpt usingWpt:p];
            trkseg->points.append(trkpt);
            trkpt = nullptr;
        }

//        assignRouteExtensionWriter(segment);
        [s.wrapper fillExtensions:trkseg withExtensionsObj:s];

        trk->segments.append(trkseg);
        trkseg = nullptr;
    }

    [t.wrapper fillExtensions:trk withExtensionsObj:t];
}

+ (void)fillRoute:(std::shared_ptr<OsmAnd::GpxDocument::Route>)rte usingRoute:(OARoute *)r
{
    std::shared_ptr<OsmAnd::GpxDocument::WptPt> rtept;

    if (r.name)
        rte->name = QString::fromNSString(r.name);
    if (r.desc)
        rte->description = QString::fromNSString(r.desc);

    for (OAWptPt *p in r.points)
    {
        rtept.reset(new OsmAnd::GpxDocument::WptPt());
        [self fillWpt:rtept usingWpt:p];
        rte->points.append(rtept);
        rtept = nullptr;
    }
    
    [r.wrapper fillExtensions:rte withExtensionsObj:r];
}

+ (NSArray *)fetchLinks:(QList<OsmAnd::Ref<OsmAnd::GpxDocument::Link>>)links
{
    if (!links.isEmpty()) {
        NSMutableArray<OALink *> *gpxLinks = [NSMutableArray array];
        for (const auto& l : links)
        {
            OsmAnd::Ref<OsmAnd::GpxDocument::Link> *_l = (OsmAnd::Ref<OsmAnd::GpxDocument::Link>*)&l;
            const std::shared_ptr<const OsmAnd::GpxDocument::Link> link = _l->shared_ptr();

            OALink *gpxLink = [[OALink alloc] init];
            gpxLink.text = link->text.toNSString();
            gpxLink.url = link->url.toNSURL();
            [gpxLinks addObject:gpxLink];
        }
        return gpxLinks;
    }
    return nil;
}

+ (void) fillLinks:(QList<OsmAnd::Ref<OsmAnd::GpxDocument::Link>>&)links linkArray:(NSArray *)linkArray
{
    std::shared_ptr<OsmAnd::GpxDocument::Link> link;
    for (OALink *l in linkArray)
    {
        if (l.url)
        {
            link.reset(new OsmAnd::GpxDocument::Link());
            link->url = QUrl::fromNSURL(l.url);
            if (l.text)
                link->text = QString::fromNSString(l.text);
            links.append(link);
            link = nullptr;
        }
    }
}

@end
