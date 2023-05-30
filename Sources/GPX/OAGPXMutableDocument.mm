//
//  OAGPXMutableDocument.m
//  OsmAnd
//
//  Created by Alexey Kulish on 30/04/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAGPXMutableDocument.h"
#import "OAUtilities.h"
#import "OAAppVersionDependentConstants.h"
#import "OAGPXPrimitivesNativeWrapper.h"

@implementation OAGPXMutableDocument
{
    std::shared_ptr<OsmAnd::GpxDocument> document;
    NSTimeInterval _analysisModifiedTime;
    OAGPXTrackAnalysis *_trackAnalysis;
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
        _modifiedTime = 0;

        self.wrapper = [[OAGPXDocumentNativeWrapper alloc] init];
        document = [self.wrapper getGpxDocument];

        [self initBounds];
    }
    return self;
}

- (instancetype)initWithNativeWrapper:(OAGPXDocumentNativeWrapper *)wrapper
{
    self = [super initWithNativeWrapper:wrapper];
    if (self)
    {
        document = [wrapper getGpxDocument];
        _modifiedTime = 0;
    }
    return self;
}

- (BOOL)loadFrom:(NSString *)filename
{
    if (filename && filename.length > 0)
    {
        document = [self.wrapper loadGpxDocument:filename];
        return [self fetch:filename];
    }
    else
    {
        return false;
    }
}

- (void) updateDocAndMetadata
{
    std::shared_ptr<OsmAnd::GpxDocument::Metadata> metadata;
    std::shared_ptr<OsmAnd::GpxDocument::Link> link;

    document->version = QString::fromNSString(self.version);
    document->creator = QString::fromNSString(self.creator);
    
    [self.wrapper fillExtensions:document withExtensionsObj:self];

    metadata.reset(new OsmAnd::GpxDocument::Metadata());
    if (self.metadata)
    {
        metadata->name = QString::fromNSString(self.metadata.name);
        metadata->description = QString::fromNSString(self.metadata.desc);

        OAWptPt *pt = [self findPointToShow];
        metadata->timestamp = pt != nil && pt.time > 0 ? QDateTime::fromTime_t(pt.time).toUTC() : QDateTime::currentDateTime().toUTC();

        [OAGPXDocumentNativeWrapper fillLinks:metadata->links linkArray:self.metadata.links];
        
        [self.metadata.wrapper fillExtensions:metadata withExtensionsObj:self.metadata];
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
    std::shared_ptr<OsmAnd::GpxDocument::WptPt> wpt;
    std::shared_ptr<OsmAnd::GpxDocument::Link> link;

    wpt.reset(new OsmAnd::GpxDocument::WptPt());
    wpt->position.latitude = w.position.latitude;
    wpt->position.longitude = w.position.longitude;
    wpt->name = QString::fromNSString(w.name);
    wpt->description = QString::fromNSString(w.desc);
    wpt->elevation = w.elevation;
    wpt->timestamp = w.time != 0 ? QDateTime::fromTime_t(w.time).toUTC() : QDateTime().toUTC();
    wpt->comment = QString::fromNSString(w.comment);
    wpt->type = QString::fromNSString(w.type);
    wpt->horizontalDilutionOfPrecision = w.horizontalDilutionOfPrecision;
    wpt->verticalDilutionOfPrecision = w.verticalDilutionOfPrecision;
    wpt->heading = w.heading;
    wpt->speed = w.speed;
    
    [OAGPXDocumentNativeWrapper fillLinks:wpt->links linkArray:w.links];
    
    NSMutableArray *extArray = [NSMutableArray array];
    for (OAGpxExtension *e in w.extensions)
    {
        if (![e.name isEqualToString:@"speed"] && ![e.name isEqualToString:@"color"])
            [extArray addObject:e];
    }
    
    int color = [w getColor:0];
    if (color != 0)
    {
        OAGpxExtension *e = [[OAGpxExtension alloc] init];
        e.name = @"color";
        e.value = UIColorFromRGBA(color).toHexARGBString;
        [extArray addObject:e];
    }
    
    w.extensions = extArray;

    [w.wrapper fillExtensions:wpt withExtensionsObj:w];

    w.wrapper.wpt = wpt;
    document->points.append(wpt);
    wpt = nullptr;

    [self processBounds:w.position];
    
    [self.points addObject:w];
    _modifiedTime = [[NSDate date] timeIntervalSince1970];
}

- (void)deleteWpt:(OAWptPt *)w
{
    for (OAWptPt *wpt in self.points)
    {
        if (wpt == w || wpt.time == w.time)
        {
            [self.points removeObject:wpt];
            document->points.removeOne(wpt.wrapper.wpt);
            w.wrapper.wpt = nullptr;
            break;
        }
    }
    _modifiedTime = [[NSDate date] timeIntervalSince1970];
}

- (void)deleteAllWpts
{
    [self.points removeAllObjects];
    document->points.clear();
    _modifiedTime = [[NSDate date] timeIntervalSince1970];
}

- (void) addRoutePoints:(NSArray<OAWptPt *> *)points addRoute:(BOOL)addRoute
{
    if (self.routes.count == 0 || addRoute)
    {
        OARoute *route = [[OARoute alloc] init];
        [self addRoute:route];
    }
    for (OAWptPt *pt in points)
        [self addRoutePoint:pt route:self.routes.lastObject];
    
    _modifiedTime = [[NSDate date] timeIntervalSince1970];
}

- (void) addRoutes:(NSArray<OARoute *> *)routes
{
    [routes enumerateObjectsUsingBlock:^(OARoute * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self addRoute:obj];
    }];
}

- (void) addRoute:(OARoute *)r
{
    std::shared_ptr<OsmAnd::GpxDocument::Route> rte;
    std::shared_ptr<OsmAnd::GpxDocument::WptPt> rtept;
    std::shared_ptr<OsmAnd::GpxDocument::Link> link;

    if (!r.points)
        r.points = [NSMutableArray new];
    
    rte.reset(new OsmAnd::GpxDocument::Route());
    rte->name = QString::fromNSString(r.name);
    rte->description = QString::fromNSString(r.desc);

    for (OAWptPt *p in r.points)
    {
        rtept.reset(new OsmAnd::GpxDocument::WptPt());
        rtept->position.latitude = p.position.latitude;
        rtept->position.longitude = p.position.longitude;
        rtept->name = QString::fromNSString(p.name);
        rtept->description = QString::fromNSString(p.desc);
        rtept->elevation = p.elevation;
        rtept->timestamp = p.time != 0 ? QDateTime::fromTime_t(p.time).toUTC() : QDateTime().toUTC();
        rtept->comment = QString::fromNSString(p.comment);
        rtept->type = QString::fromNSString(p.type);
        rtept->horizontalDilutionOfPrecision = p.horizontalDilutionOfPrecision;
        rtept->verticalDilutionOfPrecision = p.verticalDilutionOfPrecision;
        rtept->heading = p.heading;
        rtept->speed = p.speed;
        
        [OAGPXDocumentNativeWrapper fillLinks:rtept->links linkArray:p.links];

        [p.wrapper fillExtensions:rtept withExtensionsObj:p];
        
        p.wrapper.wpt = rtept;
        rte->points.append(rtept);
        rtept = nullptr;
        
        [self processBounds:p.position];
    }
    
    [r.wrapper fillExtensions:rte withExtensionsObj:r];

    r.wrapper.rte = rte;
    document->routes.append(rte);
    rte = nullptr;
    
    [self.routes addObject:r];
    _modifiedTime = [[NSDate date] timeIntervalSince1970];
}

- (void) addRoutePoint:(OAWptPt *)p route:(OARoute *)route
{
    std::shared_ptr<OsmAnd::GpxDocument::WptPt> rtept;
    std::shared_ptr<OsmAnd::GpxDocument::Link> link;

    rtept.reset(new OsmAnd::GpxDocument::WptPt());
    rtept->position.latitude = p.position.latitude;
    rtept->position.longitude = p.position.longitude;
    rtept->name = QString::fromNSString(p.name);
    rtept->description = QString::fromNSString(p.desc);
    rtept->elevation = p.elevation;
    rtept->timestamp = p.time != 0 ? QDateTime::fromTime_t(p.time).toUTC() : QDateTime().toUTC();
    rtept->comment = QString::fromNSString(p.comment);
    rtept->type = QString::fromNSString(p.type);
    rtept->horizontalDilutionOfPrecision = p.horizontalDilutionOfPrecision;
    rtept->verticalDilutionOfPrecision = p.verticalDilutionOfPrecision;
    rtept->heading = p.heading;
    rtept->speed = p.speed;
    
    [OAGPXDocumentNativeWrapper fillLinks:rtept->links linkArray:p.links];
    
    [p.wrapper fillExtensions:rtept withExtensionsObj:p];

    p.wrapper.wpt = rtept;
    route.wrapper.rte->points.append(rtept);
    rtept = nullptr;
    
    [self processBounds:p.position];

    [((NSMutableArray *)route.points) addObject:p];
    _modifiedTime = [[NSDate date] timeIntervalSince1970];
}

- (void) addTracks:(NSArray<OATrack *> *)tracks
{
    [tracks enumerateObjectsUsingBlock:^(OATrack * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self addTrack:obj];
    }];
}

- (void) addTrack:(OATrack *)t
{
    std::shared_ptr<OsmAnd::GpxDocument::Track> trk;
    std::shared_ptr<OsmAnd::GpxDocument::WptPt> trkpt;
    std::shared_ptr<OsmAnd::GpxDocument::TrkSegment> trkseg;
    std::shared_ptr<OsmAnd::GpxDocument::Link> link;

    if (!t.segments)
        t.segments = [NSMutableArray array];
    
    trk.reset(new OsmAnd::GpxDocument::Track());
    trk->name = QString::fromNSString(t.name);
    trk->description = QString::fromNSString(t.desc);

    for (OATrkSegment *s in t.segments)
    {
        trkseg.reset(new OsmAnd::GpxDocument::TrkSegment());
        
        for (OAWptPt *p in s.points)
        {
            trkpt.reset(new OsmAnd::GpxDocument::WptPt());
            trkpt->position.latitude = p.position.latitude;
            trkpt->position.longitude = p.position.longitude;
            trkpt->name = QString::fromNSString(p.name);
            trkpt->description = QString::fromNSString(p.desc);
            trkpt->elevation = p.elevation;
            trkpt->timestamp = p.time != 0 ? QDateTime::fromTime_t(p.time).toUTC() : QDateTime().toUTC();
            trkpt->comment = QString::fromNSString(p.comment);
            trkpt->type = QString::fromNSString(p.type);
            trkpt->horizontalDilutionOfPrecision = p.horizontalDilutionOfPrecision;
            trkpt->verticalDilutionOfPrecision = p.verticalDilutionOfPrecision;
            trkpt->heading = p.heading;
            trkpt->speed = p.speed;
            
            [OAGPXDocumentNativeWrapper fillLinks:trkpt->links linkArray:p.links];

            [p.wrapper fillExtensions:trkpt withExtensionsObj:p];

            p.wrapper.wpt = trkpt;
            trkseg->points.append(trkpt);
            trkpt = nullptr;
            
            [self processBounds:p.position];
        }
        
        [s.wrapper fillExtensions:trkseg withExtensionsObj:s];

        s.wrapper.trkseg = trkseg;
        trk->segments.append(trkseg);
        trkseg = nullptr;
    }

    [t.wrapper fillExtensions:trk withExtensionsObj:t];

    t.wrapper.trk = trk;
    document->tracks.append(trk);
    trk = nullptr;
    
    [self.tracks addObject:t];
    _modifiedTime = [[NSDate date] timeIntervalSince1970];
}

- (void)addTrackSegment:(OATrkSegment *)s track:(OATrack *)track
{
    std::shared_ptr<OsmAnd::GpxDocument::WptPt> trkpt;
    std::shared_ptr<OsmAnd::GpxDocument::TrkSegment> trkseg;
    std::shared_ptr<OsmAnd::GpxDocument::Link> link;

    if (!s.points)
        s.points = [NSMutableArray array];
    
    trkseg.reset(new OsmAnd::GpxDocument::TrkSegment());
    
    for (OAWptPt *p in s.points)
    {
        trkpt.reset(new OsmAnd::GpxDocument::WptPt());
        trkpt->position.latitude = p.position.latitude;
        trkpt->position.longitude = p.position.longitude;
        trkpt->name = QString::fromNSString(p.name);
        trkpt->description = QString::fromNSString(p.desc);
        trkpt->elevation = p.elevation;
        trkpt->timestamp = p.time != 0 ? QDateTime::fromTime_t(p.time).toUTC() : QDateTime().toUTC();
        trkpt->comment = QString::fromNSString(p.comment);
        trkpt->type = QString::fromNSString(p.type);
        trkpt->horizontalDilutionOfPrecision = p.horizontalDilutionOfPrecision;
        trkpt->verticalDilutionOfPrecision = p.verticalDilutionOfPrecision;
        trkpt->heading = p.heading;
        trkpt->speed = p.speed;
        
        [OAGPXDocumentNativeWrapper fillLinks:trkpt->links linkArray:p.links];

        [p.wrapper fillExtensions:trkpt withExtensionsObj:p];

        p.wrapper.wpt = trkpt;
        trkseg->points.append(trkpt);
        trkpt = nullptr;

        [self processBounds:p.position];
    }
    
    [s.wrapper fillExtensions:trkseg withExtensionsObj:s];

    s.wrapper.trkseg = trkseg;
    track.wrapper.trk->segments.append(trkseg);
    trkseg = nullptr;
    
    [((NSMutableArray *)track.segments) addObject:s];
    _modifiedTime = [[NSDate date] timeIntervalSince1970];
}

- (BOOL)removeTrackSegment:(OATrkSegment *)segment
{
    [self removeGeneralTrackIfExists];

    for (OATrack *track in self.tracks)
    {
        if ([track.segments containsObject:segment] && segment.wrapper.trkseg != nullptr)
        {
            BOOL removed = track.wrapper.trk->segments.removeOne(std::dynamic_pointer_cast<OsmAnd::GpxDocument::TrkSegment>(segment.wrapper.trkseg));
            if (removed)
            {
                if (track.segments.count > 1)
                {
                    NSMutableArray<OATrkSegment *> *segments = [NSMutableArray array];
                    for (OATrkSegment *trackSeg in track.segments)
                    {
                        if (trackSeg != segment)
                            [segments addObject:trackSeg];
                    }
                    track.segments = segments;
                }
                else
                {
                    track.segments = @[];
                }

                [self addGeneralTrack];
                _modifiedTime = [[NSDate date] timeIntervalSince1970];
            }
            return removed;
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
        _modifiedTime = [[NSDate date] timeIntervalSince1970];
    }
}

- (void) addTrackPoint:(OAWptPt *)p segment:(OATrkSegment *)segment
{
    std::shared_ptr<OsmAnd::GpxDocument::WptPt> trkpt;
    std::shared_ptr<OsmAnd::GpxDocument::Link> link;

    trkpt.reset(new OsmAnd::GpxDocument::WptPt());
    trkpt->position.latitude = p.position.latitude;
    trkpt->position.longitude = p.position.longitude;
    trkpt->name = QString::fromNSString(p.name);
    trkpt->description = QString::fromNSString(p.desc);
    trkpt->elevation = p.elevation;
    trkpt->timestamp = p.time != 0 ? QDateTime::fromTime_t(p.time).toUTC() : QDateTime().toUTC();
    trkpt->comment = QString::fromNSString(p.comment);
    trkpt->type = QString::fromNSString(p.type);
    trkpt->horizontalDilutionOfPrecision = p.horizontalDilutionOfPrecision;
    trkpt->verticalDilutionOfPrecision = p.verticalDilutionOfPrecision;
    trkpt->heading = p.heading;
    trkpt->speed = p.speed;
    
    [OAGPXDocumentNativeWrapper fillLinks:trkpt->links linkArray:p.links];
    
    [p.wrapper fillExtensions:trkpt withExtensionsObj:p];

    p.wrapper.wpt = trkpt;
    segment.wrapper.trkseg->points.append(trkpt);
    trkpt = nullptr;
    
    [self processBounds:p.position];

    [((NSMutableArray *)segment.points) addObject:p];
    _modifiedTime = [[NSDate date] timeIntervalSince1970];
}

- (BOOL) saveTo:(NSString *)filename
{
    [self updateDocAndMetadata];
    [self applyBounds];
    return document->saveTo(QString::fromNSString(filename), QString::fromNSString([OAAppVersionDependentConstants getAppVersionWithBundle]));
}

- (OAGPXTrackAnalysis*) getAnalysis:(long)fileTimestamp
{
    if (!_trackAnalysis || _analysisModifiedTime != _modifiedTime)
        [self update];
    return _trackAnalysis;
}

- (void) update
{
    _analysisModifiedTime = _modifiedTime;
    
    NSTimeInterval fileTimestamp = 0;
    if (self.path && self.path.length > 0)
    {
        NSFileManager *manager = NSFileManager.defaultManager;
        NSError *err = nil;
        NSDictionary *attrs = [manager attributesOfItemAtPath:self.path error:&err];
        if (!err)
            fileTimestamp = attrs.fileModificationDate.timeIntervalSince1970;
    }
    else
    {
        fileTimestamp = [[NSDate date] timeIntervalSince1970];
    }
    
    _trackAnalysis = [super getAnalysis:fileTimestamp];
}

@end
