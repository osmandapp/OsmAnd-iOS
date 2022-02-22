//
//  OAGPXDocument.m
//  OsmAnd
//
//  Created by Alexey Kulish on 12/02/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAGPXDocument.h"
#import "OAGPXTrackAnalysis.h"
#import "OAUtilities.h"
#import "QuadRect.h"
#import "OAGPXDatabase.h"
#import "OAApplicationMode.h"
#import "Localization.h"
#import "OAMapUtils.h"

#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/QKeyValueIterator.h>

@implementation OAGPXDocument
{
    double left;
    double top;
    double right;
    double bottom;

    NSArray<OATrkSegment *> *_processedPointsToDisplay;
    BOOL _routePoints;
}

- (id)initWithGpxDocument:(std::shared_ptr<OsmAnd::GpxDocument>)gpxDocument
{
    if (self = [super init])
    {
        _path = @"";
        if ([self fetch:gpxDocument])
            return self;
        else
            return nil;
    }
    else
    {
        return nil;
    }
}

- (id)initWithGpxFile:(NSString *)filename
{
    if (self = [super init])
    {
        self.path = filename;
        if ([self loadFrom:filename])
            return self;
        else
            return nil;
    }
    else
    {
        return nil;
    }
}

- (BOOL)hasGeneralTrack
{
    return _generalTrack != nil;
}

+ (NSString *)getSegmentTitle:(OATrkSegment *)segment segmentIdx:(NSInteger)segmentIdx
{
    NSString *segmentName = !segment.name || segment.name.length == 0
            ? [NSString stringWithFormat:@"%li", segmentIdx + 1]
            : segment.name;
    NSString *segmentString = OALocalizedString(@"gpx_selection_segment_title");
    return [NSString stringWithFormat:OALocalizedString(@"ltr_or_rtl_combine_via_colon"), segmentString, segmentName];
}

+ (NSString *)getTrackTitle:(OAGPXDocument *)gpxFile track:(OATrack *)track
{
    NSString *trackName;
    if (!track.name || track.name.length == 0)
    {
        NSInteger trackIdx = [gpxFile.tracks indexOfObject:track];
        NSInteger visibleTrackIdx = [gpxFile hasGeneralTrack] ? trackIdx : trackIdx + 1;
        trackName = [NSString stringWithFormat:@"%li", visibleTrackIdx];
    }
    else
    {
        trackName = track.name;
    }
    NSString *trackString = OALocalizedString(@"shared_string_gpx_track");
    return [NSString stringWithFormat:OALocalizedString(@"ltr_or_rtl_combine_via_colon"), trackString, trackName];
}

+ (NSString *)buildTrackSegmentName:(OAGPXDocument *)gpxFile track:(OATrack *)track segment:(OATrkSegment *)segment
{
    NSString *trackTitle = [self getTrackTitle:gpxFile track:track];
    NSString *segmentTitle = [self getSegmentTitle:segment segmentIdx:[track.segments indexOfObject:segment]];

    BOOL oneSegmentPerTrack =
            [gpxFile getNonEmptySegmentsCount] == [gpxFile getNonEmptyTracksCount];
    BOOL oneOriginalTrack = [gpxFile hasGeneralTrack] && [gpxFile getNonEmptyTracksCount] == 2
            || ![gpxFile hasGeneralTrack] && [gpxFile getNonEmptyTracksCount] == 1;

    if (oneSegmentPerTrack)
        return trackTitle;
    else if (oneOriginalTrack)
        return segmentTitle;
    else
        return [NSString stringWithFormat:OALocalizedString(@"ltr_or_rtl_combine_via_dash"), trackTitle, segmentTitle];
}

- (NSString *) getColoringType
{
    OAGpxExtension *e = [self getExtensionByKey:@"coloring_type"];
    if (e) {
        return e.value;
    }
    return nil;
}

- (NSString *) getGradientScaleType
{
    OAGpxExtension *e = [self getExtensionByKey:@"gradient_scale_type"];
    if (e) {
        return e.value;
    }
    return nil;
}

- (void) setColoringType:(NSString *)coloringType
{
    OAGpxExtension *e = [self getExtensionByKey:@"coloring_type"];
    if (!e)
    {
        e = [[OAGpxExtension alloc] init];
        e.name = @"coloring_type";
        e.value = coloringType;
        [self addExtension:e];
        return;
    }
    e.value = coloringType;
}

- (void) removeGradientScaleType
{
    [self removeExtension:[self getExtensionByKey:@"gradient_scale_type"]];
}

- (NSString *) getSplitType
{
    OAGpxExtension *e = [self getExtensionByKey:@"split_type"];
    if (e) {
        return e.value;
    }
    return nil;
}

- (void) setSplitType:(NSString *)gpxSplitType
{
    OAGpxExtension *e = [self getExtensionByKey:@"split_type"];
    if (!e)
    {
        e = [[OAGpxExtension alloc] init];
        e.name = @"split_type";
        e.value = gpxSplitType;
        [self addExtension:e];
        return;
    }
    e.value = gpxSplitType;
}

- (double) getSplitInterval
{
    OAGpxExtension *e = [self getExtensionByKey:@"split_interval"];
    if (e) {
        return [e.value doubleValue];
    }
    return 0.;
}

- (void) setSplitInterval:(double)splitInterval
{
    OAGpxExtension *e = [self getExtensionByKey:@"split_interval"];
    if (!e)
    {
        e = [[OAGpxExtension alloc] init];
        e.name = @"split_interval";
        e.value = @(splitInterval).stringValue;
        [self addExtension:e];
        return;
    }
    e.value = @(splitInterval).stringValue;
}

- (NSString *) getWidth:(NSString *)defWidth
{
    NSString *widthValue = nil;
    OAGpxExtension *e = [self getExtensionByKey:@"width"];
    if (e) {
        widthValue = e.value;
    }
    return widthValue != nil ? widthValue : defWidth;
}

- (void) setWidth:(NSString *)width
{
    OAGpxExtension *e = [self getExtensionByKey:@"width"];
    if (!e)
    {
        e = [[OAGpxExtension alloc] init];
        e.name = @"width";
        e.value = width;
        [self addExtension:e];
        return;
    }
    e.value = width;
}

- (BOOL) isShowArrows
{
    NSString *showArrows = nil;
    OAGpxExtension *e = [self getExtensionByKey:@"show_arrows"];
    if (e) {
        showArrows = e.value;
    }
    return showArrows == nil || [showArrows isEqualToString:@"false"] ? NO : YES;
}

- (void) setShowArrows:(BOOL)showArrows
{
    NSString *strValue = showArrows ? @"true" : @"false";
    OAGpxExtension *e = [self getExtensionByKey:@"show_arrows"];
    if (!e)
    {
        e = [[OAGpxExtension alloc] init];
        e.name = @"show_arrows";
        e.value = strValue;
        [self addExtension:e];
        return;
    }
    e.value = strValue;
}

- (BOOL) isShowStartFinish
{
    OAGpxExtension *e = [self getExtensionByKey:@"show_start_finish"];
    if (e) {
        return [e.value isEqualToString:@"true"];
    }
    return YES;
}

- (void) setShowStartFinish:(BOOL)showStartFinish
{
    NSString *strValue = showStartFinish ? @"true" : @"false";
    OAGpxExtension *e = [self getExtensionByKey:@"show_start_finish"];
    if (!e)
    {
        e = [[OAGpxExtension alloc] init];
        e.name = @"show_start_finish";
        e.value = strValue;
        [self addExtension:e];
        return;
    }
    e.value = strValue;
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

- (void)initBounds
{
    left = DBL_MAX;
    top = DBL_MAX;
    right = DBL_MAX;
    bottom = DBL_MAX;
}

- (void)processBounds:(CLLocationCoordinate2D)coord
{
    if (left == DBL_MAX) {
        left = coord.longitude;
        right = coord.longitude;
        top = coord.latitude;
        bottom = coord.latitude;
        
    } else {
        
        left = MIN(left, coord.longitude);
        right = MAX(right, coord.longitude);
        top = MAX(top, coord.latitude);
        bottom = MIN(bottom, coord.latitude);
    }
}

- (void)applyBounds
{
    double clat = bottom / 2.0 + top / 2.0;
    double clon = left / 2.0 + right / 2.0;
    
    OAGpxBounds bounds;
    bounds.center = CLLocationCoordinate2DMake(clat, clon);
    bounds.topLeft = CLLocationCoordinate2DMake(top, left);
    bounds.bottomRight = CLLocationCoordinate2DMake(bottom, right);
    self.bounds = bounds;
}

+ (OAWptPt *)fetchWpt:(std::shared_ptr<OsmAnd::GpxDocument::WptPt>)mark
{
    OAWptPt *wptPt = [[OAWptPt alloc] init];
    wptPt.position = CLLocationCoordinate2DMake(mark->position.latitude, mark->position.longitude);
    wptPt.name = mark->name.toNSString();
    wptPt.desc = mark->description.toNSString();
    wptPt.elevation = mark->elevation;
    wptPt.time = mark->timestamp.toTime_t();
    wptPt.comment = mark->comment.toNSString();
    wptPt.type = mark->type.toNSString();
    wptPt.horizontalDilutionOfPrecision = mark->horizontalDilutionOfPrecision;
    wptPt.verticalDilutionOfPrecision = mark->verticalDilutionOfPrecision;
    wptPt.links = [self.class fetchLinks:mark->links];
    wptPt.speed = mark->speed;
    wptPt.heading = mark->heading;

    [wptPt fetchExtensions:mark];
    for (OAGpxExtension *e in wptPt.extensions)
    {
        if ([e.name isEqualToString:@"color"])
            [wptPt setColor:[OAUtilities colorToNumberFromString:e.value]];
    }

    return wptPt;
}

- (BOOL) fetch:(std::shared_ptr<OsmAnd::GpxDocument>)gpxDocument
{
    if (gpxDocument == nullptr)
        return false;

    [self initBounds];

    self.version = gpxDocument->version.toNSString();
    self.creator = gpxDocument->creator.toNSString();
    
    if (gpxDocument->metadata != nullptr)
    {
        OAMetadata *metadata = [[OAMetadata alloc] init];
        metadata.name = gpxDocument->metadata->name.toNSString();
        metadata.desc = gpxDocument->metadata->description.toNSString();
        metadata.time = gpxDocument->metadata->timestamp.toTime_t();
        metadata.links = [self.class fetchLinks:gpxDocument->metadata->links];
        
        OsmAnd::Ref<OsmAnd::GpxDocument::Metadata> *_metadata = &gpxDocument->metadata;
        [metadata fetchExtensions:_metadata->shared_ptr()];
        self.metadata = metadata;
    }

    [self fetchExtensions:gpxDocument];

    // Location Marks
    if (!gpxDocument->points.isEmpty())
    {
        const QList<OsmAnd::Ref<OsmAnd::GpxDocument::WptPt>> marks = gpxDocument->points;

        NSMutableArray<OAWptPt *> *_marks = [NSMutableArray array];
        for (const auto& m : marks)
        {
            OsmAnd::Ref<OsmAnd::GpxDocument::WptPt> *_m = (OsmAnd::Ref<OsmAnd::GpxDocument::WptPt>*)&m;
            const std::shared_ptr<const OsmAnd::GpxDocument::WptPt> mark = _m->shared_ptr();
            
            OAWptPt *_mark = [self.class fetchWpt:_m->shared_ptr()];
            [self processBounds:_mark.position];

            [_marks addObject:_mark];
        }
        self.points = _marks;
    }
   
    // Tracks
    if (!gpxDocument->tracks.isEmpty())
    {
        QList<OsmAnd::Ref<OsmAnd::GpxDocument::Track>> trcks = gpxDocument->tracks;
        NSMutableArray<OATrack *> *_trcks = [NSMutableArray array];
        for (const auto& t : trcks)
        {
            OsmAnd::Ref<OsmAnd::GpxDocument::Track> *_t = (OsmAnd::Ref<OsmAnd::GpxDocument::Track>*)&t;
            const std::shared_ptr<const OsmAnd::GpxDocument::Track> track = _t->shared_ptr();

            OATrack *_track = [[OATrack alloc] init];
            
            _track.name = track->name.toNSString();
            _track.desc = track->description.toNSString();
            if (!track->segments.isEmpty())
            {
                NSMutableArray<OATrkSegment *> *seg = [NSMutableArray array];
                
                for (const auto& s : track->segments)
                {
                    OsmAnd::Ref<OsmAnd::GpxDocument::TrkSegment> *_s = (OsmAnd::Ref<OsmAnd::GpxDocument::TrkSegment> *) &s;
                    OATrkSegment *_seg = [[OATrkSegment alloc] init];

                    if (!s->points.isEmpty())
                    {
                        NSMutableArray<OAWptPt *> *pts = [NSMutableArray array];
                        
                        for (const auto& pt : s->points)
                        {
                            OsmAnd::Ref<OsmAnd::GpxDocument::WptPt> *_pt = (OsmAnd::Ref<OsmAnd::GpxDocument::WptPt>*)&pt;
                            const std::shared_ptr<const OsmAnd::GpxDocument::WptPt> p = _pt->shared_ptr();

                            OAWptPt *_p = [[OAWptPt alloc] init];
                            
                            _p.position = CLLocationCoordinate2DMake(p->position.latitude, p->position.longitude);
                            _p.name = p->name.toNSString();
                            _p.desc = p->description.toNSString();
                            _p.elevation = p->elevation;
                            _p.time = p->timestamp.isNull() ? 0 : p->timestamp.toTime_t();
                            _p.comment = p->comment.toNSString();
                            _p.type = p->type.toNSString();
                            _p.links = [self.class fetchLinks:p->links];
                            _p.horizontalDilutionOfPrecision = p->horizontalDilutionOfPrecision;
                            _p.verticalDilutionOfPrecision = p->verticalDilutionOfPrecision;
                            _p.speed = p->speed;
                            _p.heading = p->heading;

                            [_p fetchExtensions:_pt->shared_ptr()];

                            [self processBounds:_p.position];
                            [pts addObject:_p];
                        }
                        _seg.points = pts;
                    }
                    _seg.trkseg = _s->shared_ptr();
                    [_seg fetchExtensions:_s->shared_ptr()];
                    [_seg fillRouteDetails];
                    [seg addObject:_seg];
                }
                
                _track.segments = seg;
            }

            [_track fetchExtensions:_t->shared_ptr()];

            _track.trk = _t->shared_ptr();
            [_trcks addObject:_track];
        }
        self.tracks = _trcks;
    }
    
    // Routes
    if (!gpxDocument->routes.isEmpty()) {
        QList<OsmAnd::Ref<OsmAnd::GpxDocument::Route>> rts = gpxDocument->routes;
        NSMutableArray<OARoute *> *_rts = [NSMutableArray array];
        for (const auto& r : rts)
        {
            OsmAnd::Ref<OsmAnd::GpxDocument::Route> *_r = (OsmAnd::Ref<OsmAnd::GpxDocument::Route>*)&r;
            const std::shared_ptr<const OsmAnd::GpxDocument::Route> route = _r->shared_ptr();

            OARoute *_route = [[OARoute alloc] init];
            
            _route.name = route->name.toNSString();
            _route.desc = route->description.toNSString();

            if (!route->points.isEmpty()) {
                NSMutableArray<OAWptPt *> *_points = [NSMutableArray array];
                
                for (const auto& pt : route->points)
                {
                    OsmAnd::Ref<OsmAnd::GpxDocument::WptPt> *_pt = (OsmAnd::Ref<OsmAnd::GpxDocument::WptPt>*)&pt;
                    const std::shared_ptr<const OsmAnd::GpxDocument::WptPt> p = _pt->shared_ptr();

                    OAWptPt *_p = [[OAWptPt alloc] init];
                    
                    _p.position = CLLocationCoordinate2DMake(p->position.latitude, p->position.longitude);
                    _p.name = p->name.toNSString();
                    _p.desc = p->description.toNSString();
                    _p.elevation = p->elevation;
                    _p.time = p->timestamp.isNull() ? 0 : p->timestamp.toTime_t();
                    _p.comment = p->comment.toNSString();
                    _p.type = p->type.toNSString();
                    _p.links = [self.class fetchLinks:p->links];
                    _p.horizontalDilutionOfPrecision = p->horizontalDilutionOfPrecision;
                    _p.verticalDilutionOfPrecision = p->verticalDilutionOfPrecision;
                    _p.speed = p->speed;
                    _p.heading = p->heading;

                    [_p fetchExtensions:_pt->shared_ptr()];

                    [self processBounds:_p.position];
                    [_points addObject:_p];
                    
                }
                
                _route.points = _points;
            }

            [_route fetchExtensions:_r->shared_ptr()];

            [_rts addObject:_route];
        }
        self.routes = _rts;
    }

    [self applyBounds];
    [self addGeneralTrack];
    [self processPoints];

    return YES;
}

- (BOOL) loadFrom:(NSString *)filename
{
    if (filename && filename.length > 0)
        return [self fetch:OsmAnd::GpxDocument::loadFrom(QString::fromNSString(filename))];
    else
        return false;
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

+ (void)fillMetadata:(std::shared_ptr<OsmAnd::GpxDocument::Metadata>)meta usingMetadata:(OAMetadata *)m
{
    meta->name = QString::fromNSString(m.name);
    meta->description = QString::fromNSString(m.desc);
    meta->timestamp = m.time > 0 ? QDateTime::fromTime_t(m.time).toUTC() : QDateTime().toUTC();
    
    [self fillLinks:meta->links linkArray:m.links];
    
    [m fillExtensions:meta];
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
    [extensions fillExtensions:wpt];
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
        [s fillExtensions:trkseg];

        trk->segments.append(trkseg);
        trkseg = nullptr;
    }

    [t fillExtensions:trk];
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
    
    [r fillExtensions:rte];
}

- (BOOL) saveTo:(NSString *)filename
{
    std::shared_ptr<OsmAnd::GpxDocument> document;
    std::shared_ptr<OsmAnd::GpxDocument::Metadata> metadata;
    std::shared_ptr<OsmAnd::GpxDocument::WptPt> wpt;
    std::shared_ptr<OsmAnd::GpxDocument::Track> trk;
    std::shared_ptr<OsmAnd::GpxDocument::Route> rte;

    document.reset(new OsmAnd::GpxDocument());
    document->version = QString::fromNSString(self.version);
    document->creator = QString::fromNSString(self.creator);

    metadata.reset(new OsmAnd::GpxDocument::Metadata());
    if (self.metadata)
        [self.class fillMetadata:metadata usingMetadata:self.metadata];

    document->metadata = metadata;
    metadata = nullptr;

    //copyright
    //author

    for (OAWptPt *w in self.points)
    {
        wpt.reset(new OsmAnd::GpxDocument::WptPt());
        [self.class fillWpt:wpt usingWpt:w];
        document->points.append(wpt);
        wpt = nullptr;
    }

    for (OATrack *t in self.tracks)
    {
        if (!t.generalTrack)
        {
            trk.reset(new OsmAnd::GpxDocument::Track());
            [self.class fillTrack:trk usingTrack:t];
            document->tracks.append(trk);
            trk = nullptr;
        }
    }

    for (OARoute *r in self.routes)
    {
        rte.reset(new OsmAnd::GpxDocument::Route());
        [self.class fillRoute:rte usingRoute:r];
        document->routes.append(rte);
        rte = nullptr;
    }

    [self fillExtensions:document];

    return document->saveTo(QString::fromNSString(filename));
}

- (BOOL) isCloudmadeRouteFile
{
    return self.creator && [@"cloudmade" isEqualToString:[self.creator lowerCase]];
}

- (OAWptPt *) findPointToShow
{
    for (OATrack *t in self.tracks) {
        for (OATrkSegment *s in t.segments) {
            if (s.points.count > 0) {
                return [s.points firstObject];
            }
        }
    }
    for (OARoute *r in self.routes) {
        if (r.points.count > 0) {
            return [r.points firstObject];
        }
    }
    if (_points.count > 0) {
        return [_points firstObject];
    }
    return nil;
}

- (BOOL) isEmpty
{
    for (OATrack *t in self.tracks)
        if (t.segments != nil)
        {
            for (OATrkSegment *s in t.segments)
            {
                BOOL tracksEmpty = (s.points.count == 0);
                if (!tracksEmpty)
                    return NO;
            }
        }
    
    return self.points.count == 0 && self.routes.count == 0;
}

- (void) addGeneralTrack
{
    OATrack *generalTrack = [self getGeneralTrack];
    if (generalTrack && ![_tracks containsObject:generalTrack])
        _tracks = [@[generalTrack] arrayByAddingObjectsFromArray:_tracks];
}

-(OATrack *) getGeneralTrack
{
    OATrkSegment *generalSegment = [self getGeneralSegment];
    if (!_generalTrack && _generalSegment)
    {
        OATrack *track = [[OATrack alloc] init];
        track.segments = @[generalSegment];
        _generalTrack = track;
        track.generalTrack = YES;
    }
    return _generalTrack;
}

- (OATrkSegment *) getGeneralSegment
{
    if (!_generalSegment && [self getNonEmptySegmentsCount] > 1)
        [self buildGeneralSegment];

    return _generalSegment;
}

- (void) buildGeneralSegment
{
    OATrkSegment *segment = [[OATrkSegment alloc] init];
    for (OATrack *track in _tracks)
    {
        for (OATrkSegment *s in track.segments)
        {
            if (s.points.count > 0)
            {
                NSMutableArray<OAWptPt *> *waypoints = [[NSMutableArray alloc] initWithCapacity:s.points.count];
                for (OAWptPt *wptPt in s.points)
                {
                    [waypoints addObject:wptPt];
                }
                waypoints[0].firstPoint = YES;
                waypoints[waypoints.count - 1].lastPoint = YES;
                segment.points = segment.points ? [segment.points arrayByAddingObjectsFromArray:waypoints] : waypoints;
            }
        }
    }
    if (segment.points.count > 0)
    {
        segment.generalSegment = YES;
        _generalSegment = segment;
    }
}

- (NSInteger)getNonEmptyTracksCount
{
    NSInteger count = 0;
    for (OATrack *track in _tracks)
    {
        for (OATrkSegment *segment in track.segments)
        {
            if (segment.points.count > 0)
            {
                count++;
                break;
            }
        }
    }
    return count;
}

- (NSInteger) getNonEmptySegmentsCount
{
    int count = 0;
    for (OATrack *t in _tracks)
    {
        for (OATrkSegment *s in t.segments)
        {
            if (s.points.count > 0)
                count++;
        }
    }
    return count;
}

// Analysis
- (OAGPXTrackAnalysis*) getAnalysis:(long)fileTimestamp
{
    OAGPXTrackAnalysis *g = [[OAGPXTrackAnalysis alloc] init];
    g.wptPoints = (int) self.points.count;
    NSMutableArray *splitSegments = [NSMutableArray array];
    for (OATrack *subtrack in self.tracks)
    {
        for (OATrkSegment *segment in subtrack.segments)
        {
            if (!segment.generalSegment)
            {
                g.totalTracks ++;
                if (segment.points.count > 1)
                    [splitSegments addObject:[[OASplitSegment alloc] initWithTrackSegment:segment]];
            }
        }
    }
    [g prepareInformation:fileTimestamp splitSegments:splitSegments];
    
    return g;
}

-(NSArray*) splitByDistance:(int)meters joinSegments:(BOOL)joinSegments
{
    return [self split:[[OADistanceMetric alloc] init] secondaryMetric:[[OATimeSplit alloc] init] metricLimit:meters joinSegments:joinSegments];
}

-(NSArray*) splitByTime:(int)seconds joinSegments:(BOOL)joinSegments
{
    return [self split:[[OATimeSplit alloc] init] secondaryMetric:[[OADistanceMetric alloc] init] metricLimit:seconds joinSegments:joinSegments];
}

-(NSArray*) split:(OASplitMetric*)metric secondaryMetric:(OASplitMetric *)secondaryMetric metricLimit:(int)metricLimit joinSegments:(BOOL)joinSegments
{
    NSMutableArray *splitSegments = [NSMutableArray array];
    for (OATrack *subtrack in self.tracks) {
        for (OATrkSegment *segment in subtrack.segments) {
            [OAGPXTrackAnalysis splitSegment:metric secondaryMetric:secondaryMetric metricLimit:metricLimit splitSegments:splitSegments segment:segment joinSegments:joinSegments];
        }
    }
    return [OAGPXTrackAnalysis convert:splitSegments];
}

- (BOOL) hasRtePt
{
    for (OARoute *r in _routes)
        if (r.points.count > 0)
            return YES;

    return NO;
}

- (BOOL) hasWptPt
{
    return _points.count > 0;
}

- (BOOL) hasTrkPt
{
    for (OATrack *t in _tracks)
        for (OATrkSegment *ts in t.segments)
            if (ts.points.count > 0)
                return YES;

    return NO;
}

- (double) getSpeed:(NSArray<OAGpxExtension *> *)extensions
{
    for (OAGpxExtension *e in extensions)
    {
        if ([e.name isEqualToString:@"speed"])
        {
            return [e.value doubleValue];
        }
    }
    return 0.;
}

- (NSArray<OATrkSegment *> *)getNonEmptyTrkSegments:(BOOL)routesOnly
{
    NSMutableArray<OATrkSegment *> *segments = [NSMutableArray new];
    for (OATrack *t in _tracks)
    {
        for (OATrkSegment *s in t.segments)
        {
            if (!s.generalSegment && s.points.count > 0 && (!routesOnly || s.hasRoute))
                [segments addObject:s];
        }
    }
    return segments;
}

- (NSArray<OATrkSegment *> *) getPointsToDisplay
{
    OAGPX *gpx = [[OAGPXDatabase sharedDb] getGPXItem:[OAUtilities getGpxShortPath:self.path]];
//    if (filteredSelectedGpxFile != null) {
//        return filteredSelectedGpxFile.getPointsToDisplay();
//    } else
    if (gpx && gpx.joinSegments)
        return [self getGeneralTrack] ? self.generalTrack.segments : [NSArray array];
    else
        return _processedPointsToDisplay;
}

- (NSArray<OATrkSegment *> *) proccessPoints
{
    NSMutableArray<OATrkSegment *> *tpoints = [NSMutableArray array];
    for (OATrack *t in _tracks)
    {
        int trackColor = [t getColor:kDefaultTrackColor];
        for (OATrkSegment *ts in t.segments)
        {
            if (!ts.generalSegment && ts.points.count > 0)
            {
                OATrkSegment *sgmt = [OATrkSegment new];
                [tpoints addObject:sgmt];
                sgmt.points = ts.points;
                [sgmt setColor:trackColor];
            }
        }
    }
    return tpoints;
}

- (NSArray<OATrkSegment *> *) processRoutePoints
{
    NSMutableArray<OATrkSegment *> *tpoints = [NSMutableArray  array];
    if (_routes.count > 0)
    {
        for (OARoute *r in _routes)
        {
            int routeColor = [r getColor:kDefaultTrackColor];
            if (r.points.count > 0)
            {
                OATrkSegment *sgmt = [OATrkSegment new];
                [tpoints addObject:sgmt];
                NSMutableArray<OAWptPt *> *rtes = [NSMutableArray array];
                for (OAWptPt *point in r.points)
                {
                    [rtes addObject:point];
                }
                sgmt.points = rtes;
                [sgmt setColor:routeColor];
            }
        }
    }
    return tpoints;
}

- (void) processPoints
{
    _processedPointsToDisplay = [self proccessPoints];
    if (!_processedPointsToDisplay || _processedPointsToDisplay.count == 0)
    {
        _processedPointsToDisplay = [self processRoutePoints];
        _routePoints = _processedPointsToDisplay && _processedPointsToDisplay.count > 0;
    }
//    if (filteredSelectedGpxFile != null) {
//        filteredSelectedGpxFile.processPoints(app);
//    }
}

- (BOOL) isRoutesPoints
{
    return _routePoints;
}

- (BOOL) hasRoute
{
	return [self getNonEmptyTrkSegments:YES].count > 0;
}

- (NSArray<OAWptPt *> *) getRoutePoints
{
    NSMutableArray<OAWptPt *> *points = [NSMutableArray new];
    for (NSInteger i = 0; i < _routes.count; i++)
    {
        OARoute *rt = _routes[i];
        [points addObjectsFromArray:rt.points];
    }
    return points;
}

- (NSArray<OAWptPt *> *) getRoutePoints:(NSInteger)routeIndex
{
    NSMutableArray<OAWptPt *> *points = [NSMutableArray new];
    if (_routes.count > routeIndex)
    {
        OARoute *rt = _routes[routeIndex];
        [points addObjectsFromArray:rt.points];
    }
    return points;
}

- (OAApplicationMode *) getRouteProfile
{
    NSArray<OAWptPt *> *points = [self getRoutePoints];
    if (points && points.count > 0)
    {
        OAApplicationMode *mode = [OAApplicationMode valueOfStringKey:[points[0] getProfileType] def:nil];
        if (mode)
            return mode;
    }
    return nil;
}

- (NSArray<NSString *> *)getWaypointCategories:(BOOL)withDefaultCategory
{
    NSMutableSet<NSString *> *categories = [NSMutableSet new];
    for (OAWptPt *point in _points)
    {
        NSString *category = point.type == nil ? @"" : point.type;
        if (withDefaultCategory || category.length != 0)
            [categories addObject:category];
    }
    return categories.allObjects;
}

- (NSDictionary<NSString *, NSString *> *)getWaypointCategoriesWithColors:(BOOL)withDefaultCategory
{
    NSMutableDictionary<NSString *, NSString *> *categories = [NSMutableDictionary new];
    for (OAWptPt *point in _points)
    {
        NSString *title = point.type == nil ? @"" : point.type;
        NSString *color = point.type == nil ? @"" : [point getColor].toHexString;
        BOOL emptyCategory = title.length == 0;
        if (!emptyCategory)
        {
            NSString *existingColor = categories[title];
            if (!existingColor || (existingColor.length == 0 && color.length != 0))
                categories[title] = color;
        }
        else if (withDefaultCategory)
        {
            categories[title] = color;
        }
    }
    return categories;
}

- (NSDictionary<NSString *, NSString *> *)getWaypointCategoriesWithCount:(BOOL)withDefaultCategory
{
    NSMutableDictionary<NSString *, NSString *> *categories = [NSMutableDictionary new];
    for (OAWptPt *point in _points)
    {
        NSString *title = point.type == nil ? @"" : point.type;
        NSString *count = @"1";
        BOOL emptyCategory = title.length == 0;
        if (!emptyCategory)
        {
            NSString *existingCount = categories[title];
            if (existingCount)
                count = [NSString stringWithFormat:@"%i", existingCount.intValue + 1];
            categories[title] = count;
        }
        else if (withDefaultCategory)
        {
            categories[title] = count;
        }
    }
    return categories;
}

- (NSArray<NSDictionary<NSString *, NSString *> *> *)getWaypointCategoriesWithAllData:(BOOL)withDefaultCategory
{
    NSMapTable<NSString *, NSDictionary *> *map = [NSMapTable new];
    for (OAWptPt *point in _points)
    {
        NSMutableDictionary<NSString *, NSString *> *categories = [NSMutableDictionary new];
        NSString *title = point.type == nil ? @"" : point.type;
        categories[@"title"] = title;
        NSString *color = point.type == nil ? @"" : [point getColor].toHexString;
        NSString *count = @"1";
        categories[@"count"] = count;

        BOOL emptyCategory = title.length == 0;
        if (!emptyCategory)
        {
            NSDictionary<NSString *, NSString *> *existing = [map objectForKey:title];
            if (existing)
            {
                count = [NSString stringWithFormat:@"%i", existing[@"count"].intValue + 1];
                color = existing[@"color"];
                categories[@"count"] = count;
                categories[@"color"] = color;
            }

            if (!existing || (existing[@"color"].length == 0 && color.length != 0))
                categories[@"color"] = color;

            [map setObject:categories forKey:title];
        }
        else if (withDefaultCategory)
        {
            categories[@"title"] = title;
            categories[@"color"] = color;
            categories[@"count"] = [NSString stringWithFormat:@"%i", [[map objectForKey:title][@"count"] intValue] + 1];
            [map setObject:categories forKey:title];
        }
    }
    return map.objectEnumerator.allObjects;
}

@end

