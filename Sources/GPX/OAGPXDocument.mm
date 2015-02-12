//
//  OAGPXDocument.m
//  OsmAnd
//
//  Created by Admin on 12/02/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAGPXDocument.h"
#import "OsmAndCore/GeoInfoDocument.h"
#include <QList>
#include <QHash>
#include <OsmAndCore/QKeyValueIterator.h>

@implementation OAMetadata
@end
@implementation OALink
@end
@implementation OAGpxExtension
@end
@implementation OAGpxExtensions
@end
@implementation OARoute
@end
@implementation OARoutePoint
@end
@implementation OATrack
@end
@implementation OATrackPoint
@end
@implementation OATrackSegment
@end
@implementation OALocationMark
@end
@implementation OAExtraData
@end


@implementation OAGPXDocument

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


/* Extra data
 if (gpxDocument->extraData != nullptr) {
 if (typeid(gpxDocument->extraData) == typeid(OsmAnd::GpxDocument::GpxExtension)) {
 
 std::shared_ptr<OsmAnd::GpxDocument::GpxExtension> e = static_cast<OsmAnd::Ref<OsmAnd::GpxDocument::GpxExtension>>(gpxDocument->extraData);
 
 OAGpxExtension *ext = [[OAGpxExtension alloc] init];
 ext.name = e->name.toNSString();
 ext.value = e->value.toNSString();
 if (!e->attributes.isEmpty()) {
 NSMutableDictionary *dict = [NSMutableDictionary dictionary];
 for(const auto& entry : OsmAnd::rangeOf(OsmAnd::constOf(e->attributes))) {
 [dict setObject:entry.value().toNSString() forKey:entry.key().toNSString()];
 }
 ext.attributes = dict;
 }
 
 // todo subextensions
 
 
 } else if (typeid(gpxDocument->extraData) == typeid(OsmAnd::GpxDocument::GpxExtensions)) {
 
 std::shared_ptr<OsmAnd::GpxDocument::GpxExtensions> e = static_cast<OsmAnd::Ref<OsmAnd::GpxDocument::GpxExtensions>>(gpxDocument->extraData);
 
 OAGpxExtensions *exts = [[OAGpxExtensions alloc] init];
 exts.value = e->value.toNSString();
 if (!e->attributes.isEmpty()) {
 NSMutableDictionary *dict = [NSMutableDictionary dictionary];
 for(const auto& entry : OsmAnd::rangeOf(OsmAnd::constOf(e->attributes))) {
 [dict setObject:entry.value().toNSString() forKey:entry.key().toNSString()];
 }
 exts.attributes = dict;
 }
 
 // todo extensions
 }
 }
 */

- (NSArray *)fetchLinks:(QList<OsmAnd::Ref<OsmAnd::GeoInfoDocument::Link>>)links
{
    if (!links.isEmpty()) {
        NSMutableArray *_OALinks = [NSMutableArray array];
        for (const auto& link : links)
        {
            OALink *_OALink = [[OALink alloc] init];
            _OALink.text = link->text.toNSString();
            _OALink.url = link->url.toNSURL();
            [_OALinks addObject:_OALink];
        }
        return _OALinks;
    }
    return nil;
}

- (BOOL) fetch:(std::shared_ptr<OsmAnd::GpxDocument>)gpxDocument
{
    self.version = gpxDocument->version.toNSString();
    self.creator = gpxDocument->creator.toNSString();
    
    if (gpxDocument->metadata != nullptr) {
        OAMetadata *metadata = [[OAMetadata alloc] init];
        metadata.name = gpxDocument->metadata->name.toNSString();
        metadata.desc = gpxDocument->metadata->description.toNSString();
        metadata.timestamp = [NSDate dateWithTimeIntervalSince1970:gpxDocument->metadata->timestamp.toTime_t()];
        metadata.links = [self fetchLinks:gpxDocument->metadata->links];
        
        // todo extra data
        
    }
    
    // Location Marks
    if (!gpxDocument->locationMarks.isEmpty()) {
        QList<OsmAnd::Ref<OsmAnd::GeoInfoDocument::LocationMark>> marks = gpxDocument->locationMarks;
        NSMutableArray *_marks = [NSMutableArray array];
        for (const auto& mark : marks)
        {
            OALocationMark *_mark = [[OALocationMark alloc] init];
            
            _mark.position = CLLocationCoordinate2DMake(mark->position.latitude, mark->position.longitude);
            _mark.name = mark->name.toNSString();
            _mark.desc = mark->description.toNSString();
            _mark.elevation = mark->elevation;
            _mark.timestamp = [NSDate dateWithTimeIntervalSince1970:mark->timestamp.toTime_t()];
            _mark.comment = mark->comment.toNSString();
            _mark.type = mark->type.toNSString();
            _mark.links = [self fetchLinks:mark->links];
            
            // todo extra data

            [_marks addObject:_mark];
        }
        self.locationMarks = _marks;
    }
   
    // Tracks
    if (!gpxDocument->tracks.isEmpty()) {
        QList<OsmAnd::Ref<OsmAnd::GeoInfoDocument::Track>> trcks = gpxDocument->tracks;
        NSMutableArray *_trcks = [NSMutableArray array];
        for (const auto& track : trcks)
        {
            OATrack *_track = [[OATrack alloc] init];
            
            _track.name = track->name.toNSString();
            _track.desc = track->description.toNSString();
            _track.comment = track->comment.toNSString();
            _track.type = track->type.toNSString();
            _track.links = [self fetchLinks:track->links];

            if (!track->segments.isEmpty()) {
                NSMutableArray *seg = [NSMutableArray array];
                
                for (const auto& s : track->segments)
                {
                    OATrackSegment *_s = [[OATrackSegment alloc] init];

                    if (!s->points.isEmpty()) {
                        NSMutableArray *pts = [NSMutableArray array];
                        
                        for (const auto& p : s->points)
                        {
                            OATrackPoint *_p = [[OATrackPoint alloc] init];
                            
                            _p.position = CLLocationCoordinate2DMake(p->position.latitude, p->position.longitude);
                            _p.name = p->name.toNSString();
                            _p.desc = p->description.toNSString();
                            _p.elevation = p->elevation;
                            _p.timestamp = [NSDate dateWithTimeIntervalSince1970:p->timestamp.toTime_t()];
                            _p.comment = p->comment.toNSString();
                            _p.type = p->type.toNSString();
                            _p.links = [self fetchLinks:p->links];
                            
                            [pts addObject:_p];
                        }
                        _s.points = pts;
                    }
                    
                    // todo extra data
                    
                    [seg addObject:_s];
                }
                
                _track.segments = seg;
            }
            
            // todo extra data
            
            [_trcks addObject:_track];
        }
        self.tracks = _trcks;
    }
    
    // Routes
    if (!gpxDocument->routes.isEmpty()) {
        QList<OsmAnd::Ref<OsmAnd::GeoInfoDocument::Route>> rts = gpxDocument->routes;
        NSMutableArray *_rts = [NSMutableArray array];
        for (const auto& route : rts)
        {
            OARoute *_route = [[OARoute alloc] init];
            
            _route.name = route->name.toNSString();
            _route.desc = route->description.toNSString();
            _route.comment = route->comment.toNSString();
            _route.type = route->type.toNSString();
            _route.links = [self fetchLinks:route->links];
            
            if (!route->points.isEmpty()) {
                NSMutableArray *_points = [NSMutableArray array];
                
                for (const auto& p : route->points)
                {
                    OATrackPoint *_p = [[OATrackPoint alloc] init];
                    
                    _p.position = CLLocationCoordinate2DMake(p->position.latitude, p->position.longitude);
                    _p.name = p->name.toNSString();
                    _p.desc = p->description.toNSString();
                    _p.elevation = p->elevation;
                    _p.timestamp = [NSDate dateWithTimeIntervalSince1970:p->timestamp.toTime_t()];
                    _p.comment = p->comment.toNSString();
                    _p.type = p->type.toNSString();
                    _p.links = [self fetchLinks:p->links];
                    
                    [_points addObject:_p];
                    
                    // todo extra data
                    
                }
                
                _route.points = _points;
            }
            
            // todo extra data
            
            [_rts addObject:_route];
        }
        self.routes = _rts;
    }

    return YES;
}

- (BOOL) loadFrom:(NSString *)filename
{
    return [self fetch:OsmAnd::GpxDocument::loadFrom(QString::fromNSString(filename))];
}

- (void) saveTo:(NSString *)filename
{
    
}

@end
