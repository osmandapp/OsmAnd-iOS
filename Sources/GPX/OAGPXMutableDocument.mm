//
//  OAGPXMutableDocument.m
//  OsmAnd
//
//  Created by Alexey Kulish on 30/04/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAGPXMutableDocument.h"


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
        [OAGPXDocument fillExtensions:extensions ext:(OAGpxExtensions *)self.extraData];
    document->extraData = extensions;
    extensions = nullptr;
    
    metadata.reset(new OsmAnd::GpxDocument::GpxMetadata());
    if (self.metadata)
    {
        metadata->name = QString::fromNSString(self.metadata.name);
        metadata->description = QString::fromNSString(self.metadata.desc);
        metadata->timestamp = QDateTime::fromTime_t(self.metadata.time);
        
        [OAGPXDocument fillLinks:metadata->links linkArray:self.metadata.links];
        
        extensions.reset(new OsmAnd::GpxDocument::GpxExtensions());
        if (self.metadata.extraData)
            [OAGPXDocument fillExtensions:extensions ext:(OAGpxExtensions *)self.metadata.extraData];
        metadata->extraData = extensions;
        extensions = nullptr;
    }
    document->metadata = metadata;
    metadata = nullptr;
    
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
    wpt->timestamp = QDateTime::fromTime_t(w.time);
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
    
    [OAGPXDocument fillLinks:wpt->links linkArray:w.links];
    
    if (w.speed > 0)
    {
        OAGpxExtensions *ext = [[OAGpxExtensions alloc] init];
        OAGpxExtension *e = [[OAGpxExtension alloc] init];
        e.name = @"speed";
        e.value = [NSString stringWithFormat:@"%.3f", w.speed];
        ext.extensions = @[e];
        w.extraData = ext;
    }

    extensions.reset(new OsmAnd::GpxDocument::GpxExtensions());
    if (w.extraData)
        [OAGPXDocument fillExtensions:extensions ext:(OAGpxExtensions *)w.extraData];
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
            trkpt->timestamp = QDateTime::fromTime_t(p.time);
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
            
            [OAGPXDocument fillLinks:trkpt->links linkArray:p.links];
            
            OAGpxExtensions *ext = [[OAGpxExtensions alloc] init];
            OAGpxExtension *e = [[OAGpxExtension alloc] init];
            e.name = @"speed";
            e.value = [NSString stringWithFormat:@"%.3f", p.speed];
            ext.extensions = @[e];
            p.extraData = ext;

            extensions.reset(new OsmAnd::GpxDocument::GpxExtensions());
            if (p.extraData)
                [OAGPXDocument fillExtensions:extensions ext:(OAGpxExtensions *)p.extraData];
            trkpt->extraData = extensions;
            extensions = nullptr;
            
            p.trkpt = trkpt;
            trkseg->points.append(trkpt);
            trkpt = nullptr;
            
            [self processBounds:p.position];
        }
        
        extensions.reset(new OsmAnd::GpxDocument::GpxExtensions());
        if (s.extraData)
            [OAGPXDocument fillExtensions:extensions ext:(OAGpxExtensions *)s.extraData];
        trkseg->extraData = extensions;
        extensions = nullptr;
        
        s.trkseg = trkseg;
        trk->segments.append(trkseg);
        trkseg = nullptr;
    }
    
    [OAGPXDocument fillLinks:trk->links linkArray:t.links];
    
    extensions.reset(new OsmAnd::GpxDocument::GpxExtensions());
    if (t.extraData)
        [OAGPXDocument fillExtensions:extensions ext:(OAGpxExtensions *)t.extraData];
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
        trkpt->timestamp = QDateTime::fromTime_t(p.time);
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
        
        [OAGPXDocument fillLinks:trkpt->links linkArray:p.links];
        
        OAGpxExtensions *ext = [[OAGpxExtensions alloc] init];
        OAGpxExtension *e = [[OAGpxExtension alloc] init];
        e.name = @"speed";
        e.value = [NSString stringWithFormat:@"%.3f", p.speed];
        ext.extensions = @[e];
        p.extraData = ext;

        extensions.reset(new OsmAnd::GpxDocument::GpxExtensions());
        if (p.extraData)
            [OAGPXDocument fillExtensions:extensions ext:(OAGpxExtensions *)p.extraData];
        trkpt->extraData = extensions;
        extensions = nullptr;
        
        p.trkpt = trkpt;
        trkseg->points.append(trkpt);
        trkpt = nullptr;

        [self processBounds:p.position];
    }
    
    extensions.reset(new OsmAnd::GpxDocument::GpxExtensions());
    if (s.extraData)
        [OAGPXDocument fillExtensions:extensions ext:(OAGpxExtensions *)s.extraData];
    trkseg->extraData = extensions;
    extensions = nullptr;
    
    s.trkseg = trkseg;
    track.trk->segments.append(trkseg);
    trkseg = nullptr;
    
    [((NSMutableArray *)track.segments) addObject:s];
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
    trkpt->timestamp = QDateTime::fromTime_t(p.time);
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
    
    [OAGPXDocument fillLinks:trkpt->links linkArray:p.links];
    
    OAGpxExtensions *ext = [[OAGpxExtensions alloc] init];
    OAGpxExtension *e = [[OAGpxExtension alloc] init];
    e.name = @"speed";
    e.value = [NSString stringWithFormat:@"%.3f", p.speed];
    ext.extensions = @[e];
    p.extraData = ext;
    
    extensions.reset(new OsmAnd::GpxDocument::GpxExtensions());
    if (p.extraData)
        [OAGPXDocument fillExtensions:extensions ext:(OAGpxExtensions *)p.extraData];
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
