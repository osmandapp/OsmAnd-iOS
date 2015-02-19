//
//  OAGPXDocument.m
//  OsmAnd
//
//  Created by Alexey Kulish on 12/02/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAGPXDocument.h"
#import "OsmAndCore/GeoInfoDocument.h"
#include <QList>
#include <QHash>
#include <OsmAndCore/QKeyValueIterator.h>
#import "OAGPXTrackAnalysis.h"


@implementation OAGPXDocument {

    double left;
    double top;
    double right;
    double bottom;

}

- (id)initWithGpxDocument:(std::shared_ptr<OsmAnd::GpxDocument>)gpxDocument
{
    if ( self = [super init] ) {
        
        if ([self fetch:gpxDocument])
            return self;
        else
            return nil;
        
    } else {
        return nil;
    }
}

- (id)initWithGpxFile:(NSString *)filename
{
    if ( self = [super init] ) {
        
        if ([self loadFrom:filename])
            return self;
        else
            return nil;
        
    } else {
        return nil;
    }
}


- (NSArray *)fetchExtensions:(QList<OsmAnd::Ref<OsmAnd::GpxDocument::GpxExtension>>)extensions
{
    if (!extensions.isEmpty()) {
        
        NSMutableArray *_OAExtensions = [NSMutableArray array];
        for (const auto& ext : extensions)
        {
            OAGpxExtension *e = [[OAGpxExtension alloc] init];
            
            e.name = ext->name.toNSString();
            e.value = ext->value.toNSString();
            if (!ext->attributes.isEmpty()) {
                NSMutableDictionary *dict = [NSMutableDictionary dictionary];
                for(const auto& entry : OsmAnd::rangeOf(OsmAnd::constOf(ext->attributes))) {
                    [dict setObject:entry.value().toNSString() forKey:entry.key().toNSString()];
                }
                e.attributes = dict;
            }
            
            e.subextensions = [self fetchExtensions:ext->subextensions];
            
            [_OAExtensions addObject:e];
        }
        
        return _OAExtensions;
    }
    
    return nil;
}

- (OAGpxExtensions *)fetchExtra:(OsmAnd::Ref<OsmAnd::GeoInfoDocument::ExtraData>)extraData
{
    if (extraData != nullptr) {
        
        OsmAnd::Ref<OsmAnd::GpxDocument::GpxExtensions> *_e = (OsmAnd::Ref<OsmAnd::GpxDocument::GpxExtensions>*)&extraData;
        const std::shared_ptr<const OsmAnd::GpxDocument::GpxExtensions> e = _e->shared_ptr();
        
        OAGpxExtensions *exts = [[OAGpxExtensions alloc] init];
        exts.value = e->value.toNSString();
        if (!e->attributes.isEmpty()) {
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            for(const auto& entry : OsmAnd::rangeOf(OsmAnd::constOf(e->attributes))) {
                [dict setObject:entry.value().toNSString() forKey:entry.key().toNSString()];
            }
            exts.attributes = dict;
        }
        
        exts.extensions = [self fetchExtensions:e->extensions];
        
        return exts;
    }
    return nil;
}

- (NSArray *)fetchLinks:(QList<OsmAnd::Ref<OsmAnd::GeoInfoDocument::Link>>)links
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

- (BOOL) fetch:(std::shared_ptr<OsmAnd::GpxDocument>)gpxDocument
{
    left = DBL_MAX;
    top = DBL_MAX;
    right = DBL_MAX;
    bottom = DBL_MAX;

    self.version = gpxDocument->version.toNSString();
    self.creator = gpxDocument->creator.toNSString();
    
    if (gpxDocument->metadata != nullptr) {
        OAGpxMetadata *metadata = [[OAGpxMetadata alloc] init];
        metadata.name = gpxDocument->metadata->name.toNSString();
        metadata.desc = gpxDocument->metadata->description.toNSString();
        metadata.time = gpxDocument->metadata->timestamp.toTime_t();
        metadata.links = [self fetchLinks:gpxDocument->metadata->links];        
        metadata.extraData = [self fetchExtra:gpxDocument->extraData];
        
        self.metadata = metadata;
    }
    
    // Location Marks
    if (!gpxDocument->locationMarks.isEmpty()) {
        const QList<OsmAnd::Ref<OsmAnd::GeoInfoDocument::LocationMark>> marks = gpxDocument->locationMarks;
        
        NSMutableArray *_marks = [NSMutableArray array];
        for (const auto& m : marks)
        {
            OsmAnd::Ref<OsmAnd::GpxDocument::GpxWpt> *_m = (OsmAnd::Ref<OsmAnd::GpxDocument::GpxWpt>*)&m;
            const std::shared_ptr<const OsmAnd::GpxDocument::GpxWpt> mark = _m->shared_ptr();
            
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
            
            _mark.links = [self fetchLinks:mark->links];

            _mark.extraData = [self fetchExtra:mark->extraData];
            
            [self processBounds:_mark.position];

            [_marks addObject:_mark];
        }
        self.locationMarks = _marks;
    }
   
    // Tracks
    if (!gpxDocument->tracks.isEmpty()) {
        QList<OsmAnd::Ref<OsmAnd::GeoInfoDocument::Track>> trcks = gpxDocument->tracks;
        NSMutableArray *_trcks = [NSMutableArray array];
        for (const auto& t : trcks)
        {
            OsmAnd::Ref<OsmAnd::GpxDocument::GpxTrk> *_t = (OsmAnd::Ref<OsmAnd::GpxDocument::GpxTrk>*)&t;
            const std::shared_ptr<const OsmAnd::GpxDocument::GpxTrk> track = _t->shared_ptr();

            OAGpxTrk *_track = [[OAGpxTrk alloc] init];
            
            _track.name = track->name.toNSString();
            _track.desc = track->description.toNSString();
            _track.comment = track->comment.toNSString();
            _track.type = track->type.toNSString();
            _track.links = [self fetchLinks:track->links];
            
            _track.source = track->source.toNSString();
            _track.slotNumber = track->slotNumber;

            if (!track->segments.isEmpty()) {
                NSMutableArray *seg = [NSMutableArray array];
                
                for (const auto& s : track->segments)
                {
                    OAGpxTrkSeg *_s = [[OAGpxTrkSeg alloc] init];

                    if (!s->points.isEmpty()) {
                        NSMutableArray *pts = [NSMutableArray array];
                        
                        for (const auto& pt : s->points)
                        {
                            OsmAnd::Ref<OsmAnd::GpxDocument::GpxTrkPt> *_pt = (OsmAnd::Ref<OsmAnd::GpxDocument::GpxTrkPt>*)&pt;
                            const std::shared_ptr<const OsmAnd::GpxDocument::GpxTrkPt> p = _pt->shared_ptr();

                            OAGpxTrkPt *_p = [[OAGpxTrkPt alloc] init];
                            
                            _p.position = CLLocationCoordinate2DMake(p->position.latitude, p->position.longitude);
                            _p.name = p->name.toNSString();
                            _p.desc = p->description.toNSString();
                            _p.elevation = p->elevation;
                            _p.time = p->timestamp.toTime_t();
                            _p.comment = p->comment.toNSString();
                            _p.type = p->type.toNSString();
                            _p.links = [self fetchLinks:p->links];
                            
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

                            _p.extraData = [self fetchExtra:p->extraData];
                            if (_p.extraData) {
                                OAGpxExtensions *exts = (OAGpxExtensions *)_p.extraData;
                                for (OAGpxExtension *e in exts.extensions) {
                                    if ([e.name isEqualToString:@"speed"]) {
                                        _p.speed = [e.value doubleValue];
                                        break;
                                    }
                                }
                            }

                            [self processBounds:_p.position];
                            [pts addObject:_p];
                        }
                        _s.points = pts;
                    }
                    
                    _s.extraData = [self fetchExtra:s->extraData];
                    
                    [seg addObject:_s];
                }
                
                _track.segments = seg;
            }
            
            _track.extraData = [self fetchExtra:t->extraData];
            
            [_trcks addObject:_track];
        }
        self.tracks = _trcks;
    }
    
    // Routes
    if (!gpxDocument->routes.isEmpty()) {
        QList<OsmAnd::Ref<OsmAnd::GeoInfoDocument::Route>> rts = gpxDocument->routes;
        NSMutableArray *_rts = [NSMutableArray array];
        for (const auto& r : rts)
        {
            OsmAnd::Ref<OsmAnd::GpxDocument::GpxRte> *_r = (OsmAnd::Ref<OsmAnd::GpxDocument::GpxRte>*)&r;
            const std::shared_ptr<const OsmAnd::GpxDocument::GpxRte> route = _r->shared_ptr();

            OAGpxRte *_route = [[OAGpxRte alloc] init];
            
            _route.name = route->name.toNSString();
            _route.desc = route->description.toNSString();
            _route.comment = route->comment.toNSString();
            _route.type = route->type.toNSString();
            _route.links = [self fetchLinks:route->links];
            
            _route.source = route->source.toNSString();
            _route.slotNumber = route->slotNumber;

            if (!route->points.isEmpty()) {
                NSMutableArray *_points = [NSMutableArray array];
                
                for (const auto& pt : route->points)
                {
                    OsmAnd::Ref<OsmAnd::GpxDocument::GpxRtePt> *_pt = (OsmAnd::Ref<OsmAnd::GpxDocument::GpxRtePt>*)&pt;
                    const std::shared_ptr<const OsmAnd::GpxDocument::GpxRtePt> p = _pt->shared_ptr();

                    OAGpxRtePt *_p = [[OAGpxRtePt alloc] init];
                    
                    _p.position = CLLocationCoordinate2DMake(p->position.latitude, p->position.longitude);
                    _p.name = p->name.toNSString();
                    _p.desc = p->description.toNSString();
                    _p.elevation = p->elevation;
                    _p.time = p->timestamp.toTime_t();
                    _p.comment = p->comment.toNSString();
                    _p.type = p->type.toNSString();
                    _p.links = [self fetchLinks:p->links];
                    
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
                    
                    _p.extraData = [self fetchExtra:p->extraData];
                    if (_p.extraData) {
                        OAGpxExtensions *exts = (OAGpxExtensions *)_p.extraData;
                        for (OAGpxExtension *e in exts.extensions) {
                            if ([e.name isEqualToString:@"speed"]) {
                                _p.speed = [e.value doubleValue];
                                break;
                            }
                        }
                    }
                    
                    [self processBounds:_p.position];
                    [_points addObject:_p];
                    
                }
                
                _route.points = _points;
            }
            
            _route.extraData = [self fetchExtra:r->extraData];
            
            [_rts addObject:_route];
        }
        self.routes = _rts;
    }

    double clat = bottom / 2.0 + top / 2.0;
    double clon = left / 2.0 + right / 2.0;
    
    self.bounds.center = CLLocationCoordinate2DMake(clat, clon);
    self.bounds.topLeft = CLLocationCoordinate2DMake(top, left);
    self.bounds.bottomRight = CLLocationCoordinate2DMake(bottom, right);
    
    return YES;
}

- (BOOL) loadFrom:(NSString *)filename
{
    return [self fetch:OsmAnd::GpxDocument::loadFrom(QString::fromNSString(filename))];
}

- (void) saveTo:(NSString *)filename
{
    
}


// Analysis
- (OAGPXTrackAnalysis*) getAnalysis:(long)fileTimestamp
{
    OAGPXTrackAnalysis *g = [[OAGPXTrackAnalysis alloc] init];
    g.wptPoints = self.locationMarks.count;
    NSMutableArray *splitSegments = [NSMutableArray array];
    for(OAGpxTrk *subtrack in self.tracks){
        for(OAGpxTrkSeg *segment in subtrack.segments){
            g.totalTracks ++;
            if(segment.points.count > 1) {
                [splitSegments addObject:[[OASplitSegment alloc] initWithTrackSegment:segment]];
            }
        }
    }
    [g prepareInformation:fileTimestamp splitSegments:splitSegments];
    
    return g;
}


-(NSArray*) splitByDistance:(int)meters
{
    return [self split:[[OADistanceMetric alloc] init] metricLimit:meters];
}

-(NSArray*) splitByTime:(int)seconds
{
    return [self split:[[OATimeSplit alloc] init] metricLimit:seconds];
}

-(NSArray*) split:(OASplitMetric*)metric metricLimit:(int)metricLimit
{
    NSMutableArray *splitSegments = [NSMutableArray array];
    for (OAGpxTrk *subtrack in self.tracks) {
        for (OAGpxTrkSeg *segment in subtrack.segments) {
            [OAGPXTrackAnalysis splitSegment:metric metricLimit:metricLimit splitSegments:splitSegments segment:segment];
        }
    }
    return [OAGPXTrackAnalysis convert:splitSegments];
}

@end
