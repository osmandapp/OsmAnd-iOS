//
//  OAGPXRouteDocument.m
//  OsmAnd
//
//  Created by Alexey Kulish on 02/07/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAGPXRouteDocument.h"
#import "OAGpxRoutePoint.h"

#include <OsmAndCore/GeoInfoDocument.h>
#include <OsmAndCore/GpxDocument.h>

@implementation OAGPXRouteDocument
{
    std::shared_ptr<OsmAnd::GpxDocument> document;
}

- (BOOL) loadFrom:(NSString *)filename
{
    document = OsmAnd::GpxDocument::loadFrom(QString::fromNSString(filename));
    return [self fetch:document];
}

- (const std::shared_ptr<OsmAnd::GpxDocument>&) getDocument
{
    return document;
}

+ (OAGpxWpt *)fetchWpt:(const std::shared_ptr<const OsmAnd::GpxDocument::GpxWpt>)mark
{
    OAGpxWpt* wpt = [super fetchWpt:mark];
    std::shared_ptr<OsmAnd::GpxDocument::GpxWpt> m = std::const_pointer_cast<OsmAnd::GpxDocument::GpxWpt>(mark);
    wpt.wpt = m;
    
    OAGpxRoutePoint *rp = [[OAGpxRoutePoint alloc] initWithWpt:wpt];
    
    return rp;
}

- (BOOL) saveTo:(NSString *)filename
{
    for (OAGpxRoutePoint *rp in self.locationMarks)
        [rp applyRouteInfo];

    return document->saveTo(QString::fromNSString(filename));
}

- (void)buildRouteTrack
{
    NSMutableArray *tracks = (NSMutableArray *)self.tracks;
    if (!tracks)
    {
        tracks = [NSMutableArray array];
        self.tracks = tracks;
    }
    
    OAGpxTrk *track;
    for (OAGpxTrk *t in tracks)
    {
        if ([t.name isEqualToString:@"routeHelperTrack"])
        {
            track = t;
            break;
        }
    }
    
    if (!track)
    {
        track = [[OAGpxTrk alloc] init];
        track.name = @"routeHelperTrack";
        [tracks addObject:track];
    }
    
    NSArray *rps = [self.locationMarks sortedArrayUsingComparator:^NSComparisonResult(OAGpxRoutePoint *rp1, OAGpxRoutePoint *rp2)
    {
        if (rp2.index > rp1.index)
            return NSOrderedAscending;
        else if (rp2.index < rp1.index)
            return NSOrderedDescending;
        else
            return NSOrderedSame;
    }];
    
    
    OAGpxTrkSeg *seg = [[OAGpxTrkSeg alloc] init];
    NSMutableArray *points = [NSMutableArray array];
    for (OAGpxRoutePoint *rp in rps)
    {
        if (rp.disabled || rp.visited)
            continue;
        
        OAGpxTrkPt *p = [[OAGpxTrkPt alloc] init];
        p.position = rp.position;
        [points addObject:p];
    }
    seg.points = points;
    track.segments = @[seg];
    
    std::shared_ptr<OsmAnd::GpxDocument::GpxTrk> trk;
    trk.reset(new OsmAnd::GpxDocument::GpxTrk());
    [self.class fillTrack:trk usingTrack:track];
    track.trk = trk;
    
    for (auto& t : document->tracks)
    {
        if (t->name == QString("routeHelperTrack"))
        {
            t = trk;
            document->tracks.removeOne(t);
            break;
        }
    }
    
    document->tracks.append(trk);
}


@end
