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

#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/QKeyValueIterator.h>

@implementation OAGPXDocument
{
    double left;
    double top;
    double right;
    double bottom;

    NSArray<OAGpxTrkSeg *> *_processedPointsToDisplay;
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

+ (NSString *)getSegmentTitle:(OAGpxTrkSeg *)segment segmentIdx:(NSInteger)segmentIdx
{
    NSString *segmentName = !segment.name || segment.name.length == 0
            ? [NSString stringWithFormat:@"%li", segmentIdx + 1]
            : segment.name;
    NSString *segmentString = OALocalizedString(@"gpx_selection_segment_title");
    return [NSString stringWithFormat:OALocalizedString(@"ltr_or_rtl_combine_via_colon"), segmentString, segmentName];
}

+ (NSString *)getTrackTitle:(OAGPXDocument *)gpxFile track:(OAGpxTrk *)track
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

+ (NSString *)buildTrackSegmentName:(OAGPXDocument *)gpxFile track:(OAGpxTrk *)track segment:(OAGpxTrkSeg *)segment
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

+ (NSArray<OAGpxExtension *> *)fetchExtensions:(QList<OsmAnd::Ref<OsmAnd::GpxDocument::GpxExtension>>)extensions
{
    if (!extensions.isEmpty())
    {
        NSMutableArray<OAGpxExtension *> *extensionsArray = [NSMutableArray array];
        NSString *name = extensions[0]->name.toNSString();
        if ([name isEqualToString:@"TrackExtension"] || [name isEqualToString:@"WaypointExtension"])
        {
            [extensionsArray addObjectsFromArray:[self fetchExtensions:extensions[0]->subextensions]];
        }
        else
        {
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
                e.subextensions = [self fetchExtensions:ext->subextensions];
                [extensionsArray addObject:e];
            }
        }
        return extensionsArray;
    }
    return @[];
}

+ (NSArray<OAGpxExtension *> *)fetchExtra:(OsmAnd::Ref<OsmAnd::GeoInfoDocument::ExtraData>)extraData
{
    if (extraData != nullptr)
    {
        OsmAnd::Ref<OsmAnd::GpxDocument::GpxExtensions> *_e = (OsmAnd::Ref<OsmAnd::GpxDocument::GpxExtensions>*)&extraData;
        const std::shared_ptr<const OsmAnd::GpxDocument::GpxExtensions> e = _e->shared_ptr();
        return [self fetchExtensions:e->extensions];
    }
}

+ (NSArray *)fetchLinks:(QList<OsmAnd::Ref<OsmAnd::GeoInfoDocument::Link>>)links
{
    if (!links.isEmpty()) {
        NSMutableArray *_OALinks = [NSMutableArray array];
        for (const auto& l : links)
        {
            OsmAnd::Ref<OsmAnd::GpxDocument::GpxLink> *_l = (OsmAnd::Ref<OsmAnd::GpxDocument::GpxLink>*)&l;
            const std::shared_ptr<const OsmAnd::GpxDocument::GpxLink> link = _l->shared_ptr();

            OAGpxLink *_OALink = [[OAGpxLink alloc] init];
            _OALink.type = link->type.toNSString();
            _OALink.text = link->text.toNSString();
            _OALink.url = link->url.toNSURL();
            [_OALinks addObject:_OALink];
        }
        return _OALinks;
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

+ (OAGpxWpt *)fetchWpt:(const std::shared_ptr<const OsmAnd::GpxDocument::GpxWpt>)mark
{
    OAGpxWpt *_mark = [[OAGpxWpt alloc] init];
    _mark.position = CLLocationCoordinate2DMake(mark->position.latitude, mark->position.longitude);
    _mark.name = mark->name.toNSString();
    _mark.desc = mark->description.toNSString();
    _mark.elevation = mark->elevation;
    _mark.time = mark->timestamp.toTime_t();
    _mark.comment = mark->comment.toNSString();
    _mark.type = mark->type.toNSString();
    
    _mark.magneticVariation = mark->magneticVariation;
    _mark.geoidHeight = mark->geoidHeight;
    _mark.source = mark->source.toNSString();
    _mark.symbol = mark->symbol.toNSString();
    _mark.fixType = (OAGpxFixType)mark->fixType;
    _mark.satellitesUsedForFixCalculation = mark->satellitesUsedForFixCalculation;
    _mark.horizontalDilutionOfPrecision = mark->horizontalDilutionOfPrecision;
    _mark.verticalDilutionOfPrecision = mark->verticalDilutionOfPrecision;
    _mark.positionDilutionOfPrecision = mark->positionDilutionOfPrecision;
    _mark.ageOfGpsData = mark->ageOfGpsData;
    _mark.dgpsStationId = mark->dgpsStationId;
    
    _mark.links = [self.class fetchLinks:mark->links];

    if (mark->extraData != nullptr)
        _mark.extensions = [self fetchExtra:mark->extraData];

    for (OAGpxExtension *e in _mark.extensions)
    {
        if ([e.name isEqualToString:@"speed"])
            _mark.speed = [e.value doubleValue];
        else if ([e.name isEqualToString:@"color"])
            [_mark setColor:[OAUtilities colorToNumberFromString:e.value]];
    }

    return _mark;
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
        OAGpxMetadata *metadata = [[OAGpxMetadata alloc] init];
        metadata.name = gpxDocument->metadata->name.toNSString();
        metadata.desc = gpxDocument->metadata->description.toNSString();
        metadata.time = gpxDocument->metadata->timestamp.toTime_t();
        metadata.links = [self.class fetchLinks:gpxDocument->metadata->links];

        if (gpxDocument->extraData != nullptr)
            self.extensions = [self.class fetchExtra:gpxDocument->extraData];

        self.metadata = metadata;
    }
    
    // Location Marks
    if (!gpxDocument->locationMarks.isEmpty()) {
        const QList<OsmAnd::Ref<OsmAnd::GeoInfoDocument::LocationMark>> marks = gpxDocument->locationMarks;
        
        NSMutableArray<OAGpxWpt *> *_marks = [NSMutableArray array];
        for (const auto& m : marks)
        {
            OsmAnd::Ref<OsmAnd::GpxDocument::GpxWpt> *_m = (OsmAnd::Ref<OsmAnd::GpxDocument::GpxWpt>*)&m;
            const std::shared_ptr<const OsmAnd::GpxDocument::GpxWpt> mark = _m->shared_ptr();
            
            OAGpxWpt *_mark = [self.class fetchWpt:mark];
            [self processBounds:_mark.position];

            [_marks addObject:_mark];
        }
        self.locationMarks = _marks;
    }
   
    // Tracks
    if (!gpxDocument->tracks.isEmpty()) {
        QList<OsmAnd::Ref<OsmAnd::GeoInfoDocument::Track>> trcks = gpxDocument->tracks;
        NSMutableArray<OAGpxTrk *> *_trcks = [NSMutableArray array];
        for (const auto& t : trcks)
        {
            OsmAnd::Ref<OsmAnd::GpxDocument::GpxTrk> *_t = (OsmAnd::Ref<OsmAnd::GpxDocument::GpxTrk>*)&t;
            const std::shared_ptr<const OsmAnd::GpxDocument::GpxTrk> track = _t->shared_ptr();

            OAGpxTrk *_track = [[OAGpxTrk alloc] init];
            
            _track.name = track->name.toNSString();
            _track.desc = track->description.toNSString();
            _track.comment = track->comment.toNSString();
            _track.type = track->type.toNSString();
            _track.links = [self.class fetchLinks:track->links];
            
            _track.source = track->source.toNSString();
            _track.slotNumber = track->slotNumber;

            if (!track->segments.isEmpty()) {
                NSMutableArray<OAGpxTrkSeg *> *seg = [NSMutableArray array];
                
                for (const auto& s : track->segments)
                {
                    OsmAnd::Ref<OsmAnd::GpxDocument::GpxTrkSeg> *_s = (OsmAnd::Ref<OsmAnd::GpxDocument::GpxTrkSeg> *) &s;
                    OAGpxTrkSeg *_seg = [[OAGpxTrkSeg alloc] init];

                    if (!s->points.isEmpty()) {
                        NSMutableArray<OAGpxTrkPt *> *pts = [NSMutableArray array];
                        
                        for (const auto& pt : s->points)
                        {
                            OsmAnd::Ref<OsmAnd::GpxDocument::GpxTrkPt> *_pt = (OsmAnd::Ref<OsmAnd::GpxDocument::GpxTrkPt>*)&pt;
                            const std::shared_ptr<const OsmAnd::GpxDocument::GpxTrkPt> p = _pt->shared_ptr();

                            OAGpxTrkPt *_p = [[OAGpxTrkPt alloc] init];
                            
                            _p.position = CLLocationCoordinate2DMake(p->position.latitude, p->position.longitude);
                            _p.name = p->name.toNSString();
                            _p.desc = p->description.toNSString();
                            _p.elevation = p->elevation;
                            _p.time = p->timestamp.isNull() ? 0 : p->timestamp.toTime_t();
                            _p.comment = p->comment.toNSString();
                            _p.type = p->type.toNSString();
                            _p.links = [self.class fetchLinks:p->links];
                            
                            _p.magneticVariation = p->magneticVariation;
                            _p.geoidHeight = p->geoidHeight;
                            _p.source = p->source.toNSString();
                            _p.symbol = p->symbol.toNSString();
                            _p.fixType = (OAGpxFixType)p->fixType;
                            _p.satellitesUsedForFixCalculation = p->satellitesUsedForFixCalculation;
                            _p.horizontalDilutionOfPrecision = p->horizontalDilutionOfPrecision;
                            _p.verticalDilutionOfPrecision = p->verticalDilutionOfPrecision;
                            _p.positionDilutionOfPrecision = p->positionDilutionOfPrecision;
                            _p.ageOfGpsData = p->ageOfGpsData;
                            _p.dgpsStationId = p->dgpsStationId;

                            if (p->extraData != nullptr)
                                _p.extensions = [self.class fetchExtra:p->extraData];

                            for (OAGpxExtension *e in _p.extensions)
                            {
                                if ([e.name isEqualToString:@"speed"])
                                {
                                    _p.speed = [e.value doubleValue];
                                    break;
                                }
                            }

                            [self processBounds:_p.position];
                            [pts addObject:_p];
                        }
                        _seg.points = pts;
                    }

                    if (s->extraData != nullptr)
                        _seg.extensions = [self.class fetchExtra:s->extraData];

                    [_seg fillRouteDetails];
                    _seg.trkseg = _s->shared_ptr();
                    [seg addObject:_seg];
                }
                
                _track.segments = seg;
            }

            if (t->extraData != nullptr)
                _track.extensions = [self.class fetchExtra:t->extraData];

            _track.trk = _t->shared_ptr();
            [_trcks addObject:_track];
        }
        self.tracks = _trcks;
    }
    
    // Routes
    if (!gpxDocument->routes.isEmpty()) {
        QList<OsmAnd::Ref<OsmAnd::GeoInfoDocument::Route>> rts = gpxDocument->routes;
        NSMutableArray<OAGpxRte *> *_rts = [NSMutableArray array];
        for (const auto& r : rts)
        {
            OsmAnd::Ref<OsmAnd::GpxDocument::GpxRte> *_r = (OsmAnd::Ref<OsmAnd::GpxDocument::GpxRte>*)&r;
            const std::shared_ptr<const OsmAnd::GpxDocument::GpxRte> route = _r->shared_ptr();

            OAGpxRte *_route = [[OAGpxRte alloc] init];
            
            _route.name = route->name.toNSString();
            _route.desc = route->description.toNSString();
            _route.comment = route->comment.toNSString();
            _route.type = route->type.toNSString();
            _route.links = [self.class fetchLinks:route->links];
            
            _route.source = route->source.toNSString();
            _route.slotNumber = route->slotNumber;

            if (!route->points.isEmpty()) {
                NSMutableArray<OAGpxRtePt *> *_points = [NSMutableArray array];
                
                for (const auto& pt : route->points)
                {
                    OsmAnd::Ref<OsmAnd::GpxDocument::GpxRtePt> *_pt = (OsmAnd::Ref<OsmAnd::GpxDocument::GpxRtePt>*)&pt;
                    const std::shared_ptr<const OsmAnd::GpxDocument::GpxRtePt> p = _pt->shared_ptr();

                    OAGpxRtePt *_p = [[OAGpxRtePt alloc] init];
                    
                    _p.position = CLLocationCoordinate2DMake(p->position.latitude, p->position.longitude);
                    _p.name = p->name.toNSString();
                    _p.desc = p->description.toNSString();
                    _p.elevation = p->elevation;
                    _p.time = p->timestamp.isNull() ? 0 : p->timestamp.toTime_t();
                    _p.comment = p->comment.toNSString();
                    _p.type = p->type.toNSString();
                    _p.links = [self.class fetchLinks:p->links];
                    
                    _p.magneticVariation = p->magneticVariation;
                    _p.geoidHeight = p->geoidHeight;
                    _p.source = p->source.toNSString();
                    _p.symbol = p->symbol.toNSString();
                    _p.fixType = (OAGpxFixType)p->fixType;
                    _p.satellitesUsedForFixCalculation = p->satellitesUsedForFixCalculation;
                    _p.horizontalDilutionOfPrecision = p->horizontalDilutionOfPrecision;
                    _p.verticalDilutionOfPrecision = p->verticalDilutionOfPrecision;
                    _p.positionDilutionOfPrecision = p->positionDilutionOfPrecision;
                    _p.ageOfGpsData = p->ageOfGpsData;
                    _p.dgpsStationId = p->dgpsStationId;

                    if (p->extraData != nullptr)
                        _p.extensions = [self.class fetchExtra:p->extraData];

                    for (OAGpxExtension *e in _p.extensions)
                    {
                        if ([e.name isEqualToString:@"speed"])
                        {
                            _p.speed = [e.value doubleValue];
                            break;
                        }
                    }

                    [self processBounds:_p.position];
                    [_points addObject:_p];
                    
                }
                
                _route.points = _points;
            }

            if (r->extraData != nullptr)
                _route.extensions = [self.class fetchExtra:r->extraData];

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
    std::shared_ptr<OsmAnd::GpxDocument::GpxLink> link;
    for (OAGpxLink *l in linkArray)
    {
        link.reset(new OsmAnd::GpxDocument::GpxLink());
        link->url = QUrl::fromNSURL(l.url);
        link->type = QString::fromNSString(l.type);
        link->text = QString::fromNSString(l.text);
        links.append(link);
        link = nullptr;
    }
}

+ (void) fillExtensions:(const std::shared_ptr<OsmAnd::GpxDocument::GpxExtensions>&)extensions ext:(OAGpxExtensions *)ext
{
    for (OAGpxExtension *e in ext.extensions)
    {
        std::shared_ptr<OsmAnd::GpxDocument::GpxExtension> extension(new OsmAnd::GpxDocument::GpxExtension());
        [self fillExtension:extension ext:e];
        extensions->extensions.push_back(extension);
        extension = nullptr;
    }
}

+ (void) fillExtension:(const std::shared_ptr<OsmAnd::GpxDocument::GpxExtension>&)extension ext:(OAGpxExtension *)e
{
    extension->name = QString::fromNSString(e.name);
    extension->value = QString::fromNSString(e.value);
    for (NSString *key in e.attributes.allKeys)
    {
        extension->attributes[QString::fromNSString(key)] = QString::fromNSString(e.attributes[key]);
    }
    for (OAGpxExtension *es in e.subextensions)
    {
        std::shared_ptr<OsmAnd::GpxDocument::GpxExtension> subextension(new OsmAnd::GpxDocument::GpxExtension());
        [self fillExtension:subextension ext:es];
        extension->subextensions.push_back(subextension);
        subextension = nullptr;
    }
}

+ (void)fillMetadata:(std::shared_ptr<OsmAnd::GpxDocument::GpxMetadata>)meta usingMetadata:(OAGpxMetadata *)m
{
    meta->name = QString::fromNSString(m.name);
    meta->description = QString::fromNSString(m.desc);
    meta->timestamp = m.time > 0 ? QDateTime::fromTime_t(m.time) : QDateTime();
    
    [self fillLinks:meta->links linkArray:m.links];
    
    std::shared_ptr<OsmAnd::GpxDocument::GpxExtensions> extensions;
    extensions.reset(new OsmAnd::GpxDocument::GpxExtensions());
    [self fillExtensions:extensions ext:m];
    meta->extraData = extensions;
    extensions = nullptr;
}

+ (void)fillWpt:(std::shared_ptr<OsmAnd::GpxDocument::GpxWpt>)wpt usingWpt:(OAGpxWpt *)w
{
    wpt->position.latitude = w.position.latitude;
    wpt->position.longitude = w.position.longitude;
    wpt->name = QString::fromNSString(w.name);
    wpt->description = QString::fromNSString(w.desc);
    wpt->elevation = w.elevation;
    wpt->timestamp = w.time > 0 ? QDateTime::fromTime_t(w.time) : QDateTime();
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
    
    [self fillLinks:wpt->links linkArray:w.links];
    
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
    
    std::shared_ptr<OsmAnd::GpxDocument::GpxExtensions> extensions;
    extensions.reset(new OsmAnd::GpxDocument::GpxExtensions());
    [self fillExtensions:extensions ext:w];
    wpt->extraData = extensions;
    extensions = nullptr;
}

+ (void)fillTrack:(std::shared_ptr<OsmAnd::GpxDocument::GpxTrk>)trk usingTrack:(OAGpxTrk *)t
{
    std::shared_ptr<OsmAnd::GpxDocument::GpxTrkPt> trkpt;
    std::shared_ptr<OsmAnd::GpxDocument::GpxTrkSeg> trkseg;

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
            trkpt->timestamp = p.time == 0 ? QDateTime() : QDateTime::fromTime_t(p.time);
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
            
            NSMutableArray *extArray = [NSMutableArray array];
            for (OAGpxExtension *e in p.extensions)
            {
                if (![e.name isEqualToString:@"speed"])
                    [extArray addObject:e];
            }
            
            if (p.speed >= 0.0)
            {
                OAGpxExtension *e = [[OAGpxExtension alloc] init];
                e.name = @"speed";
                e.value = [NSString stringWithFormat:@"%.3f", p.speed];
                [extArray addObject:e];
            }
            
            p.extensions = extArray;
            
            std::shared_ptr<OsmAnd::GpxDocument::GpxExtensions> extensions;
            extensions.reset(new OsmAnd::GpxDocument::GpxExtensions());
            [self.class fillExtensions:extensions ext:p];
            trkpt->extraData = extensions;
            extensions = nullptr;
            
            trkseg->points.append(trkpt);
            trkpt = nullptr;
        }
        
        std::shared_ptr<OsmAnd::GpxDocument::GpxExtensions> extensions;
        extensions.reset(new OsmAnd::GpxDocument::GpxExtensions());
        [self.class fillExtensions:extensions ext:s];
        trkseg->extraData = extensions;
        extensions = nullptr;
        
        trk->segments.append(trkseg);
        trkseg = nullptr;
    }
    
    [self.class fillLinks:trk->links linkArray:t.links];
    
    std::shared_ptr<OsmAnd::GpxDocument::GpxExtensions> extensions;
    extensions.reset(new OsmAnd::GpxDocument::GpxExtensions());
    [self.class fillExtensions:extensions ext:t];
    trk->extraData = extensions;
    extensions = nullptr;
}

+ (void)fillRoute:(std::shared_ptr<OsmAnd::GpxDocument::GpxRte>)rte usingRoute:(OAGpxRte *)r
{
    std::shared_ptr<OsmAnd::GpxDocument::GpxRtePt> rtept;

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
        rtept->category = QString::fromNSString(p.name);
        rtept->name = QString::fromNSString(p.name);
        rtept->description = QString::fromNSString(p.desc);
        rtept->elevation = p.elevation;
        rtept->timestamp = p.time > 0 ? QDateTime::fromTime_t(p.time) : QDateTime();
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
        
        NSMutableArray *extArray = [NSMutableArray array];
        for (OAGpxExtension *e in p.extensions)
        {
            if (![e.name isEqualToString:@"speed"])
                [extArray addObject:e];
        }

        if (p.speed >= 0.0)
        {
            OAGpxExtension *e = [[OAGpxExtension alloc] init];
            e.name = @"speed";
            e.value = [NSString stringWithFormat:@"%.3f", p.speed];
            [extArray addObject:e];
        }
        
        p.extensions = [NSArray arrayWithArray:extArray];
        
        std::shared_ptr<OsmAnd::GpxDocument::GpxExtensions> extensions;
        extensions.reset(new OsmAnd::GpxDocument::GpxExtensions());
        [self.class fillExtensions:extensions ext:p];
        rtept->extraData = extensions;
        extensions = nullptr;
        
        rte->points.append(rtept);
    }
    
    [self.class fillLinks:rte->links linkArray:r.links];
    
    std::shared_ptr<OsmAnd::GpxDocument::GpxExtensions> extensions;
    extensions.reset(new OsmAnd::GpxDocument::GpxExtensions());
    [self.class fillExtensions:extensions ext:r];
    rte->extraData = extensions;
    extensions = nullptr;
}

- (BOOL) saveTo:(NSString *)filename
{
    std::shared_ptr<OsmAnd::GpxDocument> document;
    std::shared_ptr<OsmAnd::GpxDocument::GpxMetadata> metadata;
    std::shared_ptr<OsmAnd::GpxDocument::GpxWpt> wpt;
    std::shared_ptr<OsmAnd::GpxDocument::GpxTrk> trk;
    std::shared_ptr<OsmAnd::GpxDocument::GpxRte> rte;
    std::shared_ptr<OsmAnd::GpxDocument::GpxExtensions> extensions;

    document.reset(new OsmAnd::GpxDocument());
    document->version = QString::fromNSString(self.version);
    document->creator = QString::fromNSString(self.creator);

    extensions.reset(new OsmAnd::GpxDocument::GpxExtensions());
    [self.class fillExtensions:extensions ext:self];
    document->extraData = extensions;
    extensions = nullptr;

    metadata.reset(new OsmAnd::GpxDocument::GpxMetadata());
    if (self.metadata)
        [self.class fillMetadata:metadata usingMetadata:(OAGpxMetadata *)self.metadata];

    document->metadata = metadata;
    metadata = nullptr;

    for (OAGpxWpt *w in self.locationMarks)
    {
        wpt.reset(new OsmAnd::GpxDocument::GpxWpt());
        [self.class fillWpt:wpt usingWpt:w];

        document->locationMarks.append(wpt);
        wpt = nullptr;
    }

    for (OAGpxTrk *t in self.tracks)
    {
        trk.reset(new OsmAnd::GpxDocument::GpxTrk());
        [self.class fillTrack:trk usingTrack:t];
        
        document->tracks.append(trk);
        trk = nullptr;
    }

    for (OAGpxRte *r in self.routes)
    {
        rte.reset(new OsmAnd::GpxDocument::GpxRte());
        [self.class fillRoute:rte usingRoute:r];
        
        document->routes.append(rte);
        rte = nullptr;
    }
    
    return document->saveTo(QString::fromNSString(filename));
}

- (BOOL) isCloudmadeRouteFile
{
    return self.creator && [@"cloudmade" isEqualToString:[self.creator lowerCase]];
}

- (OALocationMark *) findPointToShow
{
    for (OAGpxTrk *t in self.tracks) {
        for (OAGpxTrkSeg *s in t.segments) {
            if (s.points.count > 0) {
                return [s.points firstObject];
            }
        }
    }
    for (OAGpxRte *r in self.routes) {
        if (r.points.count > 0) {
            return [r.points firstObject];
        }
    }
    if (_locationMarks.count > 0) {
        return [_locationMarks firstObject];
    }
    return nil;
}

- (BOOL) isEmpty
{
    for (OAGpxTrk *t in self.tracks)
        if (t.segments != nil)
        {
            for (OAGpxTrkSeg *s in t.segments)
            {
                BOOL tracksEmpty = (s.points.count == 0);
                if (!tracksEmpty)
                    return NO;
            }
        }
    
    return self.locationMarks.count == 0 && self.routes.count == 0;
}

- (void) addGeneralTrack
{
    OAGpxTrk *generalTrack = [self getGeneralTrack];
    if (generalTrack && ![_tracks containsObject:generalTrack])
        _tracks = [@[generalTrack] arrayByAddingObjectsFromArray:_tracks];
}

-(OAGpxTrk *) getGeneralTrack
{
    OAGpxTrkSeg *generalSegment = [self getGeneralSegment];
    if (!_generalTrack && _generalSegment)
    {
        OAGpxTrk *track = [[OAGpxTrk alloc] init];
        track.segments = @[generalSegment];
        _generalTrack = track;
        track.generalTrack = YES;
    }
    return _generalTrack;
}

- (OAGpxTrkSeg *) getGeneralSegment
{
    if (!_generalSegment && [self getNonEmptySegmentsCount] > 1)
        [self buildGeneralSegment];

    return _generalSegment;
}

- (void) buildGeneralSegment
{
    OAGpxTrkSeg *segment = [[OAGpxTrkSeg alloc] init];
    for (OAGpxTrk *track in _tracks)
    {
        for (OAGpxTrkSeg *s in track.segments)
        {
            if (s.points.count > 0)
            {
                NSMutableArray <OAGpxTrkPt *> *waypoints = [[NSMutableArray alloc] initWithCapacity:s.points.count];
                for (OAGpxTrkPt *wptPt in s.points)
                {
                    [waypoints addObject:[[OAGpxTrkPt alloc] initWithPoint:wptPt]];
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
    for (OAGpxTrk *track in _tracks)
    {
        for (OAGpxTrkSeg *segment in track.segments)
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
    for (OAGpxTrk *t in _tracks)
    {
        for (OAGpxTrkSeg *s in t.segments)
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
    g.wptPoints = (int) self.locationMarks.count;
    NSMutableArray *splitSegments = [NSMutableArray array];
    for (OAGpxTrk *subtrack in self.tracks)
    {
        for (OAGpxTrkSeg *segment in subtrack.segments)
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
    for (OAGpxTrk *subtrack in self.tracks) {
        for (OAGpxTrkSeg *segment in subtrack.segments) {
            [OAGPXTrackAnalysis splitSegment:metric secondaryMetric:secondaryMetric metricLimit:metricLimit splitSegments:splitSegments segment:segment joinSegments:joinSegments];
        }
    }
    return [OAGPXTrackAnalysis convert:splitSegments];
}

- (BOOL) hasRtePt
{
    for (OAGpxRte *r in _routes)
        if (r.points.count > 0)
            return YES;

    return NO;
}

- (BOOL) hasWptPt
{
    return _locationMarks.count > 0;
}

- (BOOL) hasTrkPt
{
    for (OAGpxTrk *t in _tracks)
        for (OAGpxTrkSeg *ts in t.segments)
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

- (NSArray<OAGpxTrkSeg *> *) getNonEmptyTrkSegments:(BOOL)routesOnly
{
    NSMutableArray<OAGpxTrkSeg *> *segments = [NSMutableArray new];
    for (OAGpxTrk *t in _tracks)
    {
        for (OAGpxTrkSeg *s in t.segments)
        {
            if (!s.generalSegment && s.points.count > 0 && (!routesOnly || s.hasRoute))
                [segments addObject:s];
        }
    }
    return segments;
}

- (NSArray<OAGpxTrkSeg *> *) getPointsToDisplay
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

- (NSArray<OAGpxTrkSeg *> *) proccessPoints
{
    NSMutableArray<OAGpxTrkSeg *> *tpoints = [NSMutableArray array];
    for (OAGpxTrk *t in _tracks)
    {
        int trackColor = [t getColor:kDefaultTrackColor];
        for (OAGpxTrkSeg *ts in t.segments)
        {
            if (!ts.generalSegment && ts.points.count > 0)
            {
                OAGpxTrkSeg *sgmt = [OAGpxTrkSeg new];
                [tpoints addObject:sgmt];
                sgmt.points = ts.points;
                [sgmt setColor:trackColor];
            }
        }
    }
    return tpoints;
}

- (NSArray<OAGpxTrkSeg *> *) processRoutePoints
{
    NSMutableArray<OAGpxTrkSeg *> *tpoints = [NSMutableArray  array];
    if (_routes.count > 0)
    {
        for (OAGpxRte *r in _routes)
        {
            int routeColor = [r getColor:kDefaultTrackColor];
            if (r.points.count > 0)
            {
                OAGpxTrkSeg *sgmt = [OAGpxTrkSeg new];
                [tpoints addObject:sgmt];
                NSMutableArray *rtes = [NSMutableArray array];
                for (OAGpxRtePt *point in r.points)
                {
                    [rtes addObject:[[OAGpxTrkPt alloc] initWithRtePt:point]];
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

- (NSArray<OAGpxRtePt *> *) getRoutePoints
{
    NSMutableArray<OAGpxRtePt *> *points = [NSMutableArray new];
    for (NSInteger i = 0; i < _routes.count; i++)
    {
        OAGpxRte *rt = _routes[i];
        [points addObjectsFromArray:rt.points];
    }
    return points;
}

- (NSArray<OAGpxRtePt *> *) getRoutePoints:(NSInteger)routeIndex
{
    NSMutableArray<OAGpxRtePt *> *points = [NSMutableArray new];
    if (_routes.count > routeIndex)
    {
        OAGpxRte *rt = _routes[routeIndex];
        [points addObjectsFromArray:rt.points];
    }
    return points;
}

- (OAApplicationMode *) getRouteProfile
{
    NSArray<OAGpxRtePt *> *points = [self getRoutePoints];
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
    for (OAGpxWpt *point in _locationMarks)
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
    for (OAGpxWpt *point in _locationMarks)
    {
        NSString *title = point.type == nil ? @"" : point.type;
        NSString *color = point.type == nil ? @"" : UIColorFromRGBA([point getColor:0]).toHexString;
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
    for (OAGpxWpt *point in _locationMarks)
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
    for (OAGpxWpt *point in _locationMarks)
    {
        NSMutableDictionary<NSString *, NSString *> *categories = [NSMutableDictionary new];
        NSString *title = point.type == nil ? @"" : point.type;
        categories[@"title"] = title;
        NSString *color = point.type == nil ? @"" : UIColorFromRGBA([point getColor:0]).toHexString;
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

