//
//  OAGPXMutableDocument.m
//  OsmAnd
//
//  Created by Alexey Kulish on 30/04/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAGPXMutableDocument.h"
#import "OAUtilities.h"


@implementation OAGPXMutableDocument
{
    std::shared_ptr<OsmAnd::GpxDocument> document;
}

@dynamic points, tracks, routes;

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.metadata = [[OAMetadata alloc] init];
        self.points = [NSMutableArray array];
        self.tracks = [NSMutableArray array];
        self.routes = [NSMutableArray array];
        
        document.reset(new OsmAnd::GpxDocument());
        
        [self initBounds];
    }
    return self;
}

- (instancetype)initWithGpxDocument:(std::shared_ptr<OsmAnd::GpxDocument>)gpxDocument
{
    self = [super initWithGpxDocument:gpxDocument];
    if (self)
    {
        document = gpxDocument;
    }
    return self;
}

- (BOOL)loadFrom:(NSString *)filename
{
    if (filename && filename.length > 0)
    {
        document = OsmAnd::GpxDocument::loadFrom(QString::fromNSString(filename));
        return [self fetch:document];
    }
    else
    {
        return false;
    }
}

- (void)fetchTrkSeg
{
    if (document == nullptr)
        return;

    if (!document->tracks.isEmpty())
    {
        for (const auto &t: document->tracks)
        {
            OAGpxTrk *track = self.tracks[document->tracks.indexOf(t)];
            OsmAnd::Ref<OsmAnd::GpxDocument::GpxTrk> *_t = (OsmAnd::Ref<OsmAnd::GpxDocument::GpxTrk> *) &t;
            track.trk = _t->shared_ptr();

            for (const auto &s: t->segments)
            {
                OsmAnd::Ref<OsmAnd::GpxDocument::GpxTrkSeg> *_s = (OsmAnd::Ref<OsmAnd::GpxDocument::GpxTrkSeg> *) &s;
                track.segments[t->segments.indexOf(s)].trkseg = _s->shared_ptr();
            }
        }
    }
}

- (const std::shared_ptr<OsmAnd::GpxDocument>&) getDocument
{
    return document;
}

- (void) updateDocAndMetadata
{
    std::shared_ptr<OsmAnd::GpxDocument::GpxMetadata> metadata;
    std::shared_ptr<OsmAnd::GpxDocument::GpxLink> link;

    document->version = QString::fromNSString(self.version);
    document->creator = QString::fromNSString(self.creator);
    
    [self fillExtensions:document];

    metadata.reset(new OsmAnd::GpxDocument::GpxMetadata());
    if (self.metadata)
    {
        metadata->name = QString::fromNSString(self.metadata.name);
        metadata->description = QString::fromNSString(self.metadata.desc);
        
        [self.class fillLinks:metadata->links linkArray:self.metadata.links];
        
        [self.metadata fillExtensions:metadata];
    }
    document->metadata = metadata;
    metadata = nullptr;
}

- (void) addWpts:(NSArray<OAWptPt *> *)wpts
{
    [wpts enumerateObjectsUsingBlock:^(OAWptPt * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [self addWpt:obj];
    }];
}

- (void) addWpt:(OAWptPt *)w
{
    std::shared_ptr<OsmAnd::GpxDocument::GpxWptPt> wpt;
    std::shared_ptr<OsmAnd::GpxDocument::GpxLink> link;

    wpt.reset(new OsmAnd::GpxDocument::GpxWptPt());
    wpt->position.latitude = w.position.latitude;
    wpt->position.longitude = w.position.longitude;
    wpt->name = QString::fromNSString(w.name);
    wpt->description = QString::fromNSString(w.desc);
    wpt->elevation = w.elevation;
    wpt->timestamp = w.time != 0 ? QDateTime::fromTime_t(w.time).toUTC() : QDateTime();
    wpt->comment = QString::fromNSString(w.comment);
    wpt->type = QString::fromNSString(w.type);
    wpt->horizontalDilutionOfPrecision = w.horizontalDilutionOfPrecision;
    wpt->verticalDilutionOfPrecision = w.verticalDilutionOfPrecision;
    
    [self.class fillLinks:wpt->links linkArray:w.links];
    
    NSMutableArray *extArray = [NSMutableArray array];
    for (OAGpxExtension *e in w.extensions)
    {
        if (![e.name isEqualToString:@"speed"] && ![e.name isEqualToString:@"color"])
            [extArray addObject:e];
    }
    
    if (w.speed >= 0)
    {
        OAGpxExtension *e = [[OAGpxExtension alloc] init];
        e.name = @"speed";
        e.value = [NSString stringWithFormat:@"%.3f", w.speed];
        [extArray addObject:e];
    }
    int color = [w getColor:0];
    if (color != 0)
    {
        OAGpxExtension *e = [[OAGpxExtension alloc] init];
        e.name = @"color";
        e.value = UIColorFromRGBA(color).toHexString;
        [extArray addObject:e];
    }
    
    w.extensions = extArray;

    [w fillExtensions:wpt];

    w.wpt = wpt;
    document->points.append(wpt);
    wpt = nullptr;

    [self processBounds:w.position];
    
    [self.points addObject:w];
}

- (void)deleteWpt:(OAWptPt *)w
{
    for (OAWptPt *wpt in self.points)
    {
        if (wpt == w || wpt.time == w.time)
        {
            [self.points removeObject:wpt];
            document->points.removeOne(wpt.wpt);
            w.wpt = nullptr;
            break;
        }
    }
}

- (void)deleteAllWpts
{
    [self.points removeAllObjects];
    document->points.clear();
}

- (void) addRoutePoints:(NSArray<OAWptPt *> *)points addRoute:(BOOL)addRoute
{
    if (self.routes.count == 0 || addRoute)
    {
        OAGpxRte *route = [[OAGpxRte alloc] init];
        [self addRoute:route];
    }
    for (OAWptPt *pt in points)
        [self addRoutePoint:pt route:self.routes.lastObject];
    
//    self.modifiedTime = System.currentTimeMillis();
}

- (void) addRoutes:(NSArray<OAGpxRte *> *)routes
{
    [routes enumerateObjectsUsingBlock:^(OAGpxRte * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self addRoute:obj];
    }];
}

- (void) addRoute:(OAGpxRte *)r
{
    std::shared_ptr<OsmAnd::GpxDocument::GpxRte> rte;
    std::shared_ptr<OsmAnd::GpxDocument::GpxWptPt> rtept;
    std::shared_ptr<OsmAnd::GpxDocument::GpxLink> link;

    if (!r.points)
        r.points = [NSMutableArray new];
    
    rte.reset(new OsmAnd::GpxDocument::GpxRte());
    rte->name = QString::fromNSString(r.name);
    rte->description = QString::fromNSString(r.desc);

    for (OAWptPt *p in r.points)
    {
        rtept.reset(new OsmAnd::GpxDocument::GpxWptPt());
        rtept->position.latitude = p.position.latitude;
        rtept->position.longitude = p.position.longitude;
        rtept->name = QString::fromNSString(p.name);
        rtept->description = QString::fromNSString(p.desc);
        rtept->elevation = p.elevation;
        rtept->timestamp = p.time != 0 ? QDateTime::fromTime_t(p.time) : QDateTime();
        rtept->comment = QString::fromNSString(p.comment);
        rtept->type = QString::fromNSString(p.type);
        rtept->horizontalDilutionOfPrecision = p.horizontalDilutionOfPrecision;
        rtept->verticalDilutionOfPrecision = p.verticalDilutionOfPrecision;
        
        [self.class fillLinks:rtept->links linkArray:p.links];
        
        if (!isnan(p.speed))
        {
            OAGpxExtension *e = [[OAGpxExtension alloc] init];
            e.name = @"speed";
            e.value = [NSString stringWithFormat:@"%.3f", p.speed];
            p.extensions = @[e];
        }

        [p fillExtensions:rtept];
        
        p.wpt = rtept;
        rte->points.append(rtept);
        rtept = nullptr;
        
        [self processBounds:p.position];
    }
    
    [r fillExtensions:rte];

    r.rte = rte;
    document->routes.append(rte);
    rte = nullptr;
    
    [self.routes addObject:r];
}

- (void) addRoutePoint:(OAWptPt *)p route:(OAGpxRte *)route
{
    std::shared_ptr<OsmAnd::GpxDocument::GpxWptPt> rtept;
    std::shared_ptr<OsmAnd::GpxDocument::GpxLink> link;

    rtept.reset(new OsmAnd::GpxDocument::GpxWptPt());
    rtept->position.latitude = p.position.latitude;
    rtept->position.longitude = p.position.longitude;
    rtept->name = QString::fromNSString(p.name);
    rtept->description = QString::fromNSString(p.desc);
    rtept->elevation = p.elevation;
    rtept->timestamp = p.time != 0 ? QDateTime::fromTime_t(p.time).toUTC() : QDateTime();
    rtept->comment = QString::fromNSString(p.comment);
    rtept->type = QString::fromNSString(p.type);
    rtept->horizontalDilutionOfPrecision = p.horizontalDilutionOfPrecision;
    rtept->verticalDilutionOfPrecision = p.verticalDilutionOfPrecision;
    
    [self.class fillLinks:rtept->links linkArray:p.links];
    
    if (!isnan(p.speed))
    {
        OAGpxExtension *e = [[OAGpxExtension alloc] init];
        e.name = @"speed";
        e.value = [NSString stringWithFormat:@"%.3f", p.speed];
        p.extensions = @[e];
    }
    
    [p fillExtensions:rtept];

    p.wpt = rtept;
    route.rte->points.append(rtept);
    rtept = nullptr;
    
    [self processBounds:p.position];

    [((NSMutableArray *)route.points) addObject:p];
}

- (void) addTracks:(NSArray<OAGpxTrk *> *)tracks
{
    [tracks enumerateObjectsUsingBlock:^(OAGpxTrk * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self addTrack:obj];
    }];
}

- (void) addTrack:(OAGpxTrk *)t
{
    std::shared_ptr<OsmAnd::GpxDocument::GpxTrk> trk;
    std::shared_ptr<OsmAnd::GpxDocument::GpxWptPt> trkpt;
    std::shared_ptr<OsmAnd::GpxDocument::GpxTrkSeg> trkseg;
    std::shared_ptr<OsmAnd::GpxDocument::GpxLink> link;

    if (!t.segments)
        t.segments = [NSMutableArray array];
    
    trk.reset(new OsmAnd::GpxDocument::GpxTrk());
    trk->name = QString::fromNSString(t.name);
    trk->description = QString::fromNSString(t.desc);

    for (OAGpxTrkSeg *s in t.segments)
    {
        trkseg.reset(new OsmAnd::GpxDocument::GpxTrkSeg());
        
        for (OAWptPt *p in s.points)
        {
            trkpt.reset(new OsmAnd::GpxDocument::GpxWptPt());
            trkpt->position.latitude = p.position.latitude;
            trkpt->position.longitude = p.position.longitude;
            trkpt->name = QString::fromNSString(p.name);
            trkpt->description = QString::fromNSString(p.desc);
            trkpt->elevation = p.elevation;
            trkpt->timestamp = p.time != 0 ? QDateTime::fromTime_t(p.time) : QDateTime();
            trkpt->comment = QString::fromNSString(p.comment);
            trkpt->type = QString::fromNSString(p.type);
            trkpt->horizontalDilutionOfPrecision = p.horizontalDilutionOfPrecision;
            trkpt->verticalDilutionOfPrecision = p.verticalDilutionOfPrecision;
            
            [self.class fillLinks:trkpt->links linkArray:p.links];
            
            if (!isnan(p.speed))
            {
                OAGpxExtension *e = [[OAGpxExtension alloc] init];
                e.name = @"speed";
                e.value = [NSString stringWithFormat:@"%.3f", p.speed];
                p.extensions = @[e];
            }

            [p fillExtensions:trkpt];

            p.wpt = trkpt;
            trkseg->points.append(trkpt);
            trkpt = nullptr;
            
            [self processBounds:p.position];
        }
        
        [s fillExtensions:trkseg];

        s.trkseg = trkseg;
        trk->segments.append(trkseg);
        trkseg = nullptr;
    }

    [t fillExtensions:trk];

    t.trk = trk;
    document->tracks.append(trk);
    trk = nullptr;
    
    [self.tracks addObject:t];
}

- (void) addTrackSegment:(OAGpxTrkSeg *)s track:(OAGpxTrk *)track
{
    std::shared_ptr<OsmAnd::GpxDocument::GpxWptPt> trkpt;
    std::shared_ptr<OsmAnd::GpxDocument::GpxTrkSeg> trkseg;
    std::shared_ptr<OsmAnd::GpxDocument::GpxLink> link;

    if (!s.points)
        s.points = [NSMutableArray array];
    
    trkseg.reset(new OsmAnd::GpxDocument::GpxTrkSeg());
    
    for (OAWptPt *p in s.points)
    {
        trkpt.reset(new OsmAnd::GpxDocument::GpxWptPt());
        trkpt->position.latitude = p.position.latitude;
        trkpt->position.longitude = p.position.longitude;
        trkpt->name = QString::fromNSString(p.name);
        trkpt->description = QString::fromNSString(p.desc);
        trkpt->elevation = p.elevation;
        trkpt->timestamp = p.time != 0 ? QDateTime::fromTime_t(p.time) : QDateTime();
        trkpt->comment = QString::fromNSString(p.comment);
        trkpt->type = QString::fromNSString(p.type);
        trkpt->horizontalDilutionOfPrecision = p.horizontalDilutionOfPrecision;
        trkpt->verticalDilutionOfPrecision = p.verticalDilutionOfPrecision;
        
        [self.class fillLinks:trkpt->links linkArray:p.links];
        
        if (!isnan(p.speed))
        {
            OAGpxExtension *e = [[OAGpxExtension alloc] init];
            e.name = @"speed";
            e.value = [NSString stringWithFormat:@"%.3f", p.speed];
            p.extensions = @[e];
        }

        [p fillExtensions:trkpt];

        p.wpt = trkpt;
        trkseg->points.append(trkpt);
        trkpt = nullptr;

        [self processBounds:p.position];
    }
    
    [s fillExtensions:trkseg];

    s.trkseg = trkseg;
    track.trk->segments.append(trkseg);
    trkseg = nullptr;
    
    [((NSMutableArray *)track.segments) addObject:s];
}

- (BOOL)removeTrackSegment:(OAGpxTrkSeg *)segment
{
    [self removeGeneralTrackIfExists];

    for (OAGpxTrk *track in self.tracks)
    {
        for (OAGpxTrkSeg *trackSeg in track.segments)
        {
            if (trackSeg == segment || trackSeg.trkseg == segment.trkseg)
            {
                if (track.trk->segments.removeOne(std::dynamic_pointer_cast<OsmAnd::GeoInfoDocument::TrackSegment>(trackSeg.trkseg)))
                {
                    [self addGeneralTrack];
                    _modifiedTime = (long) [[NSDate date] timeIntervalSince1970];
                }
                return YES;
            }
        }
    }
    return NO;
}

- (void)removeGeneralTrackIfExists
{
    if (self.generalTrack)
    {
        NSMutableArray *tracks = [self.tracks mutableCopy];
        [tracks removeObject:self.generalTrack];
        self.tracks = tracks;
        self.generalTrack = nil;
        self.generalSegment = nil;
    }
}

- (void) addTrackPoint:(OAWptPt *)p segment:(OAGpxTrkSeg *)segment
{
    std::shared_ptr<OsmAnd::GpxDocument::GpxWptPt> trkpt;
    std::shared_ptr<OsmAnd::GpxDocument::GpxLink> link;

    trkpt.reset(new OsmAnd::GpxDocument::GpxWptPt());
    trkpt->position.latitude = p.position.latitude;
    trkpt->position.longitude = p.position.longitude;
    trkpt->name = QString::fromNSString(p.name);
    trkpt->description = QString::fromNSString(p.desc);
    trkpt->elevation = p.elevation;
    trkpt->timestamp = p.time != 0 ? QDateTime::fromTime_t(p.time).toUTC() : QDateTime();
    trkpt->comment = QString::fromNSString(p.comment);
    trkpt->type = QString::fromNSString(p.type);
    trkpt->horizontalDilutionOfPrecision = p.horizontalDilutionOfPrecision;
    trkpt->verticalDilutionOfPrecision = p.verticalDilutionOfPrecision;
    
    [self.class fillLinks:trkpt->links linkArray:p.links];
    
    if (!isnan(p.speed))
    {
        OAGpxExtension *e = [[OAGpxExtension alloc] init];
        e.name = @"speed";
        e.value = [NSString stringWithFormat:@"%.3f", p.speed];
        p.extensions = @[e];
    }
    
    [p fillExtensions:trkpt];

    p.wpt = trkpt;
    segment.trkseg->points.append(trkpt);
    trkpt = nullptr;
    
    [self processBounds:p.position];

    [((NSMutableArray *)segment.points) addObject:p];
}

- (BOOL) saveTo:(NSString *)filename
{
    [self updateDocAndMetadata];
    [self applyBounds];
    return document->saveTo(QString::fromNSString(filename));
}

@end
