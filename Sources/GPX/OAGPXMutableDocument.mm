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

@dynamic locationMarks, tracks, routes;

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.metadata = [[OAGpxMetadata alloc] init];
        self.locationMarks = [NSMutableArray array];
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
        [self fetchTrkSeg];
    }
    return self;
}

- (BOOL)loadFrom:(NSString *)filename
{
    if (filename && filename.length > 0)
    {
        document = OsmAnd::GpxDocument::loadFrom(QString::fromNSString(filename));
        BOOL fetch = [self fetch:document];
        if (fetch)
            [self fetchTrkSeg];
        return fetch;
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
    std::shared_ptr<OsmAnd::GpxDocument::GpxExtensions> extensions;
    
    document->version = QString::fromNSString(self.version);
    document->creator = QString::fromNSString(self.creator);
    
    extensions.reset(new OsmAnd::GpxDocument::GpxExtensions());
    if (self.extraData)
        [self.class fillExtensions:extensions ext:(OAGpxExtensions *)self.extraData];
    document->extraData = extensions;
    extensions = nullptr;
    
    metadata.reset(new OsmAnd::GpxDocument::GpxMetadata());
    if (self.metadata)
    {
        metadata->name = QString::fromNSString(self.metadata.name);
        metadata->description = QString::fromNSString(self.metadata.desc);
        
        [self.class fillLinks:metadata->links linkArray:self.metadata.links];
        
        extensions.reset(new OsmAnd::GpxDocument::GpxExtensions());
        if (self.metadata.extraData)
            [self.class fillExtensions:extensions ext:(OAGpxExtensions *)self.metadata.extraData];
        metadata->extraData = extensions;
        extensions = nullptr;
    }
    document->metadata = metadata;
    metadata = nullptr;
    
}

- (void) addWpts:(NSArray<OAGpxWpt *> *)wpts
{
    [wpts enumerateObjectsUsingBlock:^(OAGpxWpt * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [self addWpt:obj];
    }];
}

- (void) addWpt:(OAGpxWpt *)w
{
    std::shared_ptr<OsmAnd::GpxDocument::GpxWpt> wpt;
    std::shared_ptr<OsmAnd::GpxDocument::GpxLink> link;
    std::shared_ptr<OsmAnd::GpxDocument::GpxExtensions> extensions;

    wpt.reset(new OsmAnd::GpxDocument::GpxWpt());
    wpt->position.latitude = w.position.latitude;
    wpt->position.longitude = w.position.longitude;
    wpt->name = QString::fromNSString(w.name);
    wpt->description = QString::fromNSString(w.desc);
    wpt->elevation = w.elevation;
    wpt->timestamp = w.time != 0 ? QDateTime::fromTime_t(w.time).toUTC() : QDateTime();
    wpt->magneticVariation = w.magneticVariation;
    wpt->geoidHeight = w.geoidHeight;
    wpt->comment = QString::fromNSString(w.comment);
    wpt->source = QString::fromNSString(w.source);
    wpt->symbol = QString::fromNSString(w.symbol);
    wpt->type = QString::fromNSString(w.type);
    wpt->fixType = (OsmAnd::GpxDocument::GpxFixType)w.fixType;
    wpt->satellitesUsedForFixCalculation = w.satellitesUsedForFixCalculation;
    wpt->horizontalDilutionOfPrecision = w.horizontalDilutionOfPrecision;
    wpt->verticalDilutionOfPrecision = w.verticalDilutionOfPrecision;
    wpt->positionDilutionOfPrecision = w.positionDilutionOfPrecision;
    wpt->ageOfGpsData = w.ageOfGpsData;
    wpt->dgpsStationId = w.dgpsStationId;
    
    [self.class fillLinks:wpt->links linkArray:w.links];
    
    NSMutableArray *extArray = [NSMutableArray array];
    if (w.extraData)
    {
        OAGpxExtensions *exts = (OAGpxExtensions *)w.extraData;
        if (exts.extensions)
            for (OAGpxExtension *e in exts.extensions)
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
    if (w.color.length > 0)
    {
        OAGpxExtension *e = [[OAGpxExtension alloc] init];
        e.name = @"color";
        e.value = w.color;
        [extArray addObject:e];
    }
    
    if (extArray.count > 0)
    {
        OAGpxExtensions *ext = [[OAGpxExtensions alloc] init];
        ext.extensions = [NSArray arrayWithArray:extArray];
        w.extraData = ext;
    }

    extensions.reset(new OsmAnd::GpxDocument::GpxExtensions());
    if (w.extraData)
        [self.class fillExtensions:extensions ext:(OAGpxExtensions *)w.extraData];
    wpt->extraData = extensions;
    extensions = nullptr;
    
    w.wpt = wpt;
    document->locationMarks.append(wpt);
    wpt = nullptr;

    [self processBounds:w.position];
    
    [self.locationMarks addObject:w];
}

- (void)deleteWpt:(OAGpxWpt *)w
{
    for (OAGpxWpt *wpt in self.locationMarks)
    {
        if (wpt == w || wpt.time == w.time)
        {
            [self.locationMarks removeObject:wpt];
            document->locationMarks.removeOne(wpt.wpt);
            w.wpt = nullptr;
            break;
        }
    }
}

- (void)deleteAllWpts
{
    [self.locationMarks removeAllObjects];
    document->locationMarks.clear();
}

- (void) addRoutePoints:(NSArray<OAGpxRtePt *> *)points addRoute:(BOOL)addRoute
{
    if (self.routes.count == 0 || addRoute)
    {
        OAGpxRte *route = [[OAGpxRte alloc] init];
        [self addRoute:route];
    }
    for (OAGpxRtePt *pt in points)
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
    std::shared_ptr<OsmAnd::GpxDocument::GpxRtePt> rtept;
    std::shared_ptr<OsmAnd::GpxDocument::GpxLink> link;
    std::shared_ptr<OsmAnd::GpxDocument::GpxExtensions> extensions;
    
    if (!r.points)
        r.points = [NSMutableArray new];
    
    rte.reset(new OsmAnd::GpxDocument::GpxRte());
    rte->name = QString::fromNSString(r.name);
    rte->description = QString::fromNSString(r.desc);
    rte->comment = QString::fromNSString(r.comment);
    rte->source = QString::fromNSString(r.source);
    rte->type = QString::fromNSString(r.type);
    rte->slotNumber = r.slotNumber;
    
    for (OAGpxRtePt *p in r.points)
    {
        rtept.reset(new OsmAnd::GpxDocument::GpxRtePt());
        rtept->position.latitude = p.position.latitude;
        rtept->position.longitude = p.position.longitude;
        rtept->name = QString::fromNSString(p.name);
        rtept->description = QString::fromNSString(p.desc);
        rtept->elevation = p.elevation;
        rtept->timestamp = p.time != 0 ? QDateTime::fromTime_t(p.time) : QDateTime();
        rtept->magneticVariation = p.magneticVariation;
        rtept->geoidHeight = p.geoidHeight;
        rtept->comment = QString::fromNSString(p.comment);
        rtept->source = QString::fromNSString(p.source);
        rtept->symbol = QString::fromNSString(p.symbol);
        rtept->type = QString::fromNSString(p.type);
        rtept->fixType = (OsmAnd::GpxDocument::GpxFixType)p.fixType;
        rtept->satellitesUsedForFixCalculation = p.satellitesUsedForFixCalculation;
        rtept->horizontalDilutionOfPrecision = p.horizontalDilutionOfPrecision;
        rtept->verticalDilutionOfPrecision = p.verticalDilutionOfPrecision;
        rtept->positionDilutionOfPrecision = p.positionDilutionOfPrecision;
        rtept->ageOfGpsData = p.ageOfGpsData;
        rtept->dgpsStationId = p.dgpsStationId;
        
        [self.class fillLinks:rtept->links linkArray:p.links];
        
        if (!isnan(p.speed))
        {
            OAGpxExtensions *ext = [[OAGpxExtensions alloc] init];
            OAGpxExtension *e = [[OAGpxExtension alloc] init];
            e.name = @"speed";
            e.value = [NSString stringWithFormat:@"%.3f", p.speed];
            ext.extensions = @[e];
            p.extraData = ext;
        }

        extensions.reset(new OsmAnd::GpxDocument::GpxExtensions());
        if (p.extraData)
            [self.class fillExtensions:extensions ext:(OAGpxExtensions *)p.extraData];
        rtept->extraData = extensions;
        extensions = nullptr;
        
        p.rtept = rtept;
        rte->points.append(rtept);
        rtept = nullptr;
        
        [self processBounds:p.position];
    }
    
    extensions.reset(new OsmAnd::GpxDocument::GpxExtensions());
    if (r.extraData)
        [self.class fillExtensions:extensions ext:(OAGpxExtensions *)r.extraData];
    rte->extraData = extensions;
    extensions = nullptr;
    
    
    [self.class fillLinks:rte->links linkArray:r.links];
    
    
    r.rte = rte;
    document->routes.append(rte);
    rte = nullptr;
    
    [self.routes addObject:r];
}

- (void) addRoutePoint:(OAGpxRtePt *)p route:(OAGpxRte *)route
{
    std::shared_ptr<OsmAnd::GpxDocument::GpxRtePt> rtept;
    std::shared_ptr<OsmAnd::GpxDocument::GpxLink> link;
    std::shared_ptr<OsmAnd::GpxDocument::GpxExtensions> extensions;
    
    rtept.reset(new OsmAnd::GpxDocument::GpxRtePt());
    rtept->position.latitude = p.position.latitude;
    rtept->position.longitude = p.position.longitude;
    rtept->name = QString::fromNSString(p.name);
    rtept->description = QString::fromNSString(p.desc);
    rtept->elevation = p.elevation;
    rtept->timestamp = p.time != 0 ? QDateTime::fromTime_t(p.time).toUTC() : QDateTime();
    rtept->magneticVariation = p.magneticVariation;
    rtept->geoidHeight = p.geoidHeight;
    rtept->comment = QString::fromNSString(p.comment);
    rtept->source = QString::fromNSString(p.source);
    rtept->symbol = QString::fromNSString(p.symbol);
    rtept->type = QString::fromNSString(p.type);
    rtept->fixType = (OsmAnd::GpxDocument::GpxFixType)p.fixType;
    rtept->satellitesUsedForFixCalculation = p.satellitesUsedForFixCalculation;
    rtept->horizontalDilutionOfPrecision = p.horizontalDilutionOfPrecision;
    rtept->verticalDilutionOfPrecision = p.verticalDilutionOfPrecision;
    rtept->positionDilutionOfPrecision = p.positionDilutionOfPrecision;
    rtept->ageOfGpsData = p.ageOfGpsData;
    rtept->dgpsStationId = p.dgpsStationId;
    
    [self.class fillLinks:rtept->links linkArray:p.links];
    
    if (!isnan(p.speed))
    {
        OAGpxExtensions *ext = [[OAGpxExtensions alloc] init];
        OAGpxExtension *e = [[OAGpxExtension alloc] init];
        e.name = @"speed";
        e.value = [NSString stringWithFormat:@"%.3f", p.speed];
        ext.extensions = @[e];
        p.extraData = ext;
    }
    
    extensions.reset(new OsmAnd::GpxDocument::GpxExtensions());
    if (p.extraData)
        [self.class fillExtensions:extensions ext:(OAGpxExtensions *)p.extraData];
    rtept->extraData = extensions;
    extensions = nullptr;
    
    p.rtept = rtept;
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
    std::shared_ptr<OsmAnd::GpxDocument::GpxTrkPt> trkpt;
    std::shared_ptr<OsmAnd::GpxDocument::GpxTrkSeg> trkseg;
    std::shared_ptr<OsmAnd::GpxDocument::GpxLink> link;
    std::shared_ptr<OsmAnd::GpxDocument::GpxExtensions> extensions;

    if (!t.segments)
        t.segments = [NSMutableArray array];
    
    trk.reset(new OsmAnd::GpxDocument::GpxTrk());
    trk->name = QString::fromNSString(t.name);
    trk->description = QString::fromNSString(t.desc);
    trk->comment = QString::fromNSString(t.comment);
    trk->source = QString::fromNSString(t.source);
    trk->type = QString::fromNSString(t.type);
    trk->slotNumber = t.slotNumber;
    
    for (OAGpxTrkSeg *s in t.segments)
    {
        trkseg.reset(new OsmAnd::GpxDocument::GpxTrkSeg());
        
        for (OAGpxTrkPt *p in s.points)
        {
            trkpt.reset(new OsmAnd::GpxDocument::GpxTrkPt());
            trkpt->position.latitude = p.position.latitude;
            trkpt->position.longitude = p.position.longitude;
            trkpt->name = QString::fromNSString(p.name);
            trkpt->description = QString::fromNSString(p.desc);
            trkpt->elevation = p.elevation;
            trkpt->timestamp = p.time != 0 ? QDateTime::fromTime_t(p.time) : QDateTime();
            trkpt->magneticVariation = p.magneticVariation;
            trkpt->geoidHeight = p.geoidHeight;
            trkpt->comment = QString::fromNSString(p.comment);
            trkpt->source = QString::fromNSString(p.source);
            trkpt->symbol = QString::fromNSString(p.symbol);
            trkpt->type = QString::fromNSString(p.type);
            trkpt->fixType = (OsmAnd::GpxDocument::GpxFixType)p.fixType;
            trkpt->satellitesUsedForFixCalculation = p.satellitesUsedForFixCalculation;
            trkpt->horizontalDilutionOfPrecision = p.horizontalDilutionOfPrecision;
            trkpt->verticalDilutionOfPrecision = p.verticalDilutionOfPrecision;
            trkpt->positionDilutionOfPrecision = p.positionDilutionOfPrecision;
            trkpt->ageOfGpsData = p.ageOfGpsData;
            trkpt->dgpsStationId = p.dgpsStationId;
            
            [self.class fillLinks:trkpt->links linkArray:p.links];
            
            if (!isnan(p.speed))
            {
                OAGpxExtensions *ext = [[OAGpxExtensions alloc] init];
                OAGpxExtension *e = [[OAGpxExtension alloc] init];
                e.name = @"speed";
                e.value = [NSString stringWithFormat:@"%.3f", p.speed];
                ext.extensions = @[e];
                p.extraData = ext;
            }

            extensions.reset(new OsmAnd::GpxDocument::GpxExtensions());
            if (p.extraData)
                [self.class fillExtensions:extensions ext:(OAGpxExtensions *)p.extraData];
            trkpt->extraData = extensions;
            extensions = nullptr;
            
            p.trkpt = trkpt;
            trkseg->points.append(trkpt);
            trkpt = nullptr;
            
            [self processBounds:p.position];
        }
        
        extensions.reset(new OsmAnd::GpxDocument::GpxExtensions());
        if (s.extraData)
            [self.class fillExtensions:extensions ext:(OAGpxExtensions *)s.extraData];
        trkseg->extraData = extensions;
        extensions = nullptr;
        
        s.trkseg = trkseg;
        trk->segments.append(trkseg);
        trkseg = nullptr;
    }
    
    [self.class fillLinks:trk->links linkArray:t.links];
    
    extensions.reset(new OsmAnd::GpxDocument::GpxExtensions());
    if (t.extraData)
        [self.class fillExtensions:extensions ext:(OAGpxExtensions *)t.extraData];
    trk->extraData = extensions;
    extensions = nullptr;
    
    t.trk = trk;
    document->tracks.append(trk);
    trk = nullptr;
    
    [self.tracks addObject:t];
}

- (void) addTrackSegment:(OAGpxTrkSeg *)s track:(OAGpxTrk *)track
{
    std::shared_ptr<OsmAnd::GpxDocument::GpxTrkPt> trkpt;
    std::shared_ptr<OsmAnd::GpxDocument::GpxTrkSeg> trkseg;
    std::shared_ptr<OsmAnd::GpxDocument::GpxLink> link;
    std::shared_ptr<OsmAnd::GpxDocument::GpxExtensions> extensions;
    
    if (!s.points)
        s.points = [NSMutableArray array];
    
    trkseg.reset(new OsmAnd::GpxDocument::GpxTrkSeg());
    
    for (OAGpxTrkPt *p in s.points)
    {
        trkpt.reset(new OsmAnd::GpxDocument::GpxTrkPt());
        trkpt->position.latitude = p.position.latitude;
        trkpt->position.longitude = p.position.longitude;
        trkpt->name = QString::fromNSString(p.name);
        trkpt->description = QString::fromNSString(p.desc);
        trkpt->elevation = p.elevation;
        trkpt->timestamp = p.time != 0 ? QDateTime::fromTime_t(p.time) : QDateTime();
        trkpt->magneticVariation = p.magneticVariation;
        trkpt->geoidHeight = p.geoidHeight;
        trkpt->comment = QString::fromNSString(p.comment);
        trkpt->source = QString::fromNSString(p.source);
        trkpt->symbol = QString::fromNSString(p.symbol);
        trkpt->type = QString::fromNSString(p.type);
        trkpt->fixType = (OsmAnd::GpxDocument::GpxFixType)p.fixType;
        trkpt->satellitesUsedForFixCalculation = p.satellitesUsedForFixCalculation;
        trkpt->horizontalDilutionOfPrecision = p.horizontalDilutionOfPrecision;
        trkpt->verticalDilutionOfPrecision = p.verticalDilutionOfPrecision;
        trkpt->positionDilutionOfPrecision = p.positionDilutionOfPrecision;
        trkpt->ageOfGpsData = p.ageOfGpsData;
        trkpt->dgpsStationId = p.dgpsStationId;
        
        [self.class fillLinks:trkpt->links linkArray:p.links];
        
        if (!isnan(p.speed))
        {
            OAGpxExtensions *ext = [[OAGpxExtensions alloc] init];
            OAGpxExtension *e = [[OAGpxExtension alloc] init];
            e.name = @"speed";
            e.value = [NSString stringWithFormat:@"%.3f", p.speed];
            ext.extensions = @[e];
            p.extraData = ext;
        }

        extensions.reset(new OsmAnd::GpxDocument::GpxExtensions());
        if (p.extraData)
            [self.class fillExtensions:extensions ext:(OAGpxExtensions *)p.extraData];
        trkpt->extraData = extensions;
        extensions = nullptr;
        
        p.trkpt = trkpt;
        trkseg->points.append(trkpt);
        trkpt = nullptr;

        [self processBounds:p.position];
    }
    
    extensions.reset(new OsmAnd::GpxDocument::GpxExtensions());
    if (s.extraData)
        [self.class fillExtensions:extensions ext:(OAGpxExtensions *)s.extraData];
    trkseg->extraData = extensions;
    extensions = nullptr;
    
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

- (void) addTrackPoint:(OAGpxTrkPt *)p segment:(OAGpxTrkSeg *)segment
{
    std::shared_ptr<OsmAnd::GpxDocument::GpxTrkPt> trkpt;
    std::shared_ptr<OsmAnd::GpxDocument::GpxLink> link;
    std::shared_ptr<OsmAnd::GpxDocument::GpxExtensions> extensions;
    
    trkpt.reset(new OsmAnd::GpxDocument::GpxTrkPt());
    trkpt->position.latitude = p.position.latitude;
    trkpt->position.longitude = p.position.longitude;
    trkpt->name = QString::fromNSString(p.name);
    trkpt->description = QString::fromNSString(p.desc);
    trkpt->elevation = p.elevation;
    trkpt->timestamp = p.time != 0 ? QDateTime::fromTime_t(p.time).toUTC() : QDateTime();
    trkpt->magneticVariation = p.magneticVariation;
    trkpt->geoidHeight = p.geoidHeight;
    trkpt->comment = QString::fromNSString(p.comment);
    trkpt->source = QString::fromNSString(p.source);
    trkpt->symbol = QString::fromNSString(p.symbol);
    trkpt->type = QString::fromNSString(p.type);
    trkpt->fixType = (OsmAnd::GpxDocument::GpxFixType)p.fixType;
    trkpt->satellitesUsedForFixCalculation = p.satellitesUsedForFixCalculation;
    trkpt->horizontalDilutionOfPrecision = p.horizontalDilutionOfPrecision;
    trkpt->verticalDilutionOfPrecision = p.verticalDilutionOfPrecision;
    trkpt->positionDilutionOfPrecision = p.positionDilutionOfPrecision;
    trkpt->ageOfGpsData = p.ageOfGpsData;
    trkpt->dgpsStationId = p.dgpsStationId;
    
    [self.class fillLinks:trkpt->links linkArray:p.links];
    
    if (!isnan(p.speed))
    {
        OAGpxExtensions *ext = [[OAGpxExtensions alloc] init];
        OAGpxExtension *e = [[OAGpxExtension alloc] init];
        e.name = @"speed";
        e.value = [NSString stringWithFormat:@"%.3f", p.speed];
        ext.extensions = @[e];
        p.extraData = ext;
    }
    
    extensions.reset(new OsmAnd::GpxDocument::GpxExtensions());
    if (p.extraData)
        [self.class fillExtensions:extensions ext:(OAGpxExtensions *)p.extraData];
    trkpt->extraData = extensions;
    extensions = nullptr;
    
    p.trkpt = trkpt;
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
