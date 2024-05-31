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
#import "OAAppVersion.h"
#import "OAGPXAppearanceCollection.h"
#import "OANativeUtilities.h"

#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/QKeyValueIterator.h>
#include <qmap.h>

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
    return [NSString stringWithFormat:OALocalizedString(@"ltr_or_rtl_combine_via_space"), segmentString, segmentName];
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
    BOOL oneOriginalTrack = ([gpxFile hasGeneralTrack] && [gpxFile getNonEmptyTracksCount] == 2)
            || (![gpxFile hasGeneralTrack] && [gpxFile getNonEmptyTracksCount] == 1);

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
    [self setExtension:@"coloring_type" value:coloringType];
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
    [self setExtension:@"split_type" value:gpxSplitType];
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
    [self setExtension:@"split_interval" value:@(splitInterval).stringValue];
}

- (NSString *) getWidth:(NSString *)defWidth
{
    NSString *widthValue = defWidth;
    OAGpxExtension *e = [self getExtensionByKey:@"width"];
    if (e)
        widthValue = e.value;
    
    return widthValue;
}

- (long)getLastPointTime
{
    long time = [self getLastPointTime:[self getAllSegmentsPoints]];
    if (time == 0)
        time = [self getLastPointTime:[self getRoutePoints]];
    if (time == 0)
        time = [self getLastPointTime:[self getAllPoints]];
    
    return time;
}

- (long)getLastPointTime:(NSArray<OAWptPt *> *)points
{
    for (NSInteger i = points.count - 1; i >= 0; i--) 
    {
        OAWptPt *point = points[i];
        if (point.time > 0)
            return point.time;
    }
    
    return 0;
}

- (void) setWidth:(NSString *)width
{
    [self setExtension:@"width" value:width];
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
    [self setExtension:@"show_arrows" value:strValue];
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
    [self setExtension:@"show_start_finish" value:strValue];
}

- (CGFloat)getVerticalExaggerationScale
{
    OAGpxExtension *e = [self getExtensionByKey:@"vertical_exaggeration_scale"];
    if (e) {
        CGFloat value = [e.value floatValue];
        if (value && value >= 1.0 && value <= 3.0)
            return value;
        else
            return 1.0;
    }
    return 1.0;
}

- (void)setVerticalExaggerationScale:(CGFloat)scale
{
    [self setExtension:@"vertical_exaggeration_scale" value:[NSString stringWithFormat:@"%f",scale]];
}

- (NSInteger)getElevationMeters
{
    OAGpxExtension *e = [self getExtensionByKey:@"elevation_meters"];
    if (e) {
        NSInteger value = [e.value integerValue];
        if (value && value >= 0 && value <= 2000)
            return value;
        else
            return 1000;
    }
    return 1000;
}

- (void)setElevationMeters:(NSInteger)meters
{
    [self setExtension:@"elevation_meters" value:[NSString stringWithFormat:@"%ld", meters]];
}

- (NSString *)getVisualization3dByTypeValue
{
   OAGpxExtension *e = [self getExtensionByKey:@"line_3d_visualization_by_type"];
   if (e) {
       return e.value;
   }
   return nil;
}

- (void)setVisualization3dByType:(EOAGPX3DLineVisualizationByType)type
{
   [self setExtension:@"line_3d_visualization_by_type" value:[OAGPXDatabase lineVisualizationByTypeNameForType:type]];
}

- (NSString *)getVisualization3dWallColorTypeValue
{
    OAGpxExtension *e = [self getExtensionByKey:@"line_3d_visualization_wall_color_type"];
    if (e) {
        return e.value;
    }
    return nil;
}
- (void)setVisualization3dWallColorType:(EOAGPX3DLineVisualizationWallColorType)type
{
    [self setExtension:@"line_3d_visualization_wall_color_type" value:[OAGPXDatabase lineVisualizationWallColorTypeNameForType:type]];
}

- (NSString *)getVisualization3dPositionTypeValue
{
    OAGpxExtension *e = [self getExtensionByKey:@"line_3d_visualization_position_type"];
    if (e) {
        return e.value;
    }
    return nil;
}

- (void)setVisualization3dPositionType:(EOAGPX3DLineVisualizationPositionType)type
{
    [self setExtension:@"line_3d_visualization_position_type" value:[OAGPXDatabase lineVisualizationPositionTypeNameForType:type]];
}

+ (NSArray<OALink *> *)fetchLinks:(QList<OsmAnd::Ref<OsmAnd::GpxDocument::Link>>)links
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
    wptPt.time = mark->timestamp.toSecsSinceEpoch();
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
            [wptPt setColor:[UIColor toNumberFromString:e.value]];
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
        metadata.time = gpxDocument->metadata->timestamp.toSecsSinceEpoch();
        metadata.links = [self.class fetchLinks:gpxDocument->metadata->links];
        metadata.keywords = gpxDocument->metadata->keywords.toNSString();
        OsmAnd::Ref<OsmAnd::GpxDocument::Metadata> *metadataRef = &gpxDocument->metadata;
        [metadata fetchExtensions:metadataRef->shared_ptr()];

        if (gpxDocument->metadata->author != nullptr)
        {
            OAAuthor *author = [[OAAuthor alloc] init];
            author.name = gpxDocument->metadata->author->name.toNSString();
            author.email = gpxDocument->metadata->author->email.toNSString();
            if (gpxDocument->metadata->author->link != nullptr)
                author.link = [self.class fetchLinks:{ gpxDocument->metadata->author->link }].firstObject;
            OsmAnd::Ref<OsmAnd::GpxDocument::Author> *authorRef = &gpxDocument->metadata->author;
            [author fetchExtensions:authorRef->shared_ptr()];
            metadata.author = author;
        }

        if (gpxDocument->metadata->copyright != nullptr)
        {
            OACopyright *copyright = [[OACopyright alloc] init];
            copyright.author = gpxDocument->metadata->copyright->author.toNSString();
            copyright.year = gpxDocument->metadata->copyright->year.toNSString();
            copyright.license = gpxDocument->metadata->copyright->license.toNSString();
            OsmAnd::Ref<OsmAnd::GpxDocument::Copyright> *copyrightRef = &gpxDocument->metadata->copyright;
            [copyright fetchExtensions:copyrightRef->shared_ptr()];
            metadata.copyright = copyright;
        }

        self.metadata = metadata;
    }

    [self fetchExtensions:gpxDocument];

    NSMutableDictionary<NSString *, NSString *> *routeKeyTags = [NSMutableDictionary dictionary];
    for (auto it = gpxDocument->networkRouteKeyTags.begin(); it != gpxDocument->networkRouteKeyTags.end(); ++it)
    {
        routeKeyTags[it.key().toNSString()] = it.value().toNSString();
    }
    _networkRouteKeyTags = routeKeyTags;

    // Tracks
    if (!gpxDocument->tracks.isEmpty())
    {
        NSMutableArray<OATrack *> *tracks = [NSMutableArray array];
        for (const auto& trackConst : gpxDocument->tracks)
        {
            OsmAnd::Ref<OsmAnd::GpxDocument::Track> *trackRef = (OsmAnd::Ref<OsmAnd::GpxDocument::Track> *) &trackConst;
            const std::shared_ptr<const OsmAnd::GpxDocument::Track> trackPtr = trackRef->shared_ptr();

            OATrack *track = [[OATrack alloc] init];
            track.name = trackPtr->name.toNSString();
            track.desc = trackPtr->description.toNSString();

            if (!trackPtr->segments.isEmpty())
            {
                NSMutableArray<OATrkSegment *> *trkSegments = [NSMutableArray array];
                for (const auto& trkSegmentConst : trackPtr->segments)
                {
                    OsmAnd::Ref<OsmAnd::GpxDocument::TrkSegment> *trkSegmentRef = (OsmAnd::Ref<OsmAnd::GpxDocument::TrkSegment> *) &trkSegmentConst;

                    OATrkSegment *trkSegment = [[OATrkSegment alloc] init];

                    if (!trkSegmentConst->points.isEmpty())
                    {
                        NSMutableArray<OAWptPt *> *segmentPoints = [NSMutableArray array];
                        for (const auto& segmentPointConst : trkSegmentConst->points)
                        {
                            OsmAnd::Ref<OsmAnd::GpxDocument::WptPt> *segmentPointRef = (OsmAnd::Ref<OsmAnd::GpxDocument::WptPt> *) &segmentPointConst;
                            const std::shared_ptr<const OsmAnd::GpxDocument::WptPt> segmentPointPtr = segmentPointRef->shared_ptr();
                            
                            OAWptPt *segmentPoint = [[OAWptPt alloc] init];
                            
                            segmentPoint.position = CLLocationCoordinate2DMake(segmentPointPtr->position.latitude, segmentPointPtr->position.longitude);
                            segmentPoint.name = segmentPointPtr->name.toNSString();
                            segmentPoint.desc = segmentPointPtr->description.toNSString();
                            segmentPoint.elevation = segmentPointPtr->elevation;
                            segmentPoint.time = segmentPointPtr->timestamp.isNull() ? 0 : segmentPointPtr->timestamp.toSecsSinceEpoch();
                            segmentPoint.comment = segmentPointPtr->comment.toNSString();
                            segmentPoint.type = segmentPointPtr->type.toNSString();
                            segmentPoint.links = [self.class fetchLinks:segmentPointPtr->links];
                            segmentPoint.horizontalDilutionOfPrecision = segmentPointPtr->horizontalDilutionOfPrecision;
                            segmentPoint.verticalDilutionOfPrecision = segmentPointPtr->verticalDilutionOfPrecision;
                            segmentPoint.speed = segmentPointPtr->speed;
                            segmentPoint.heading = segmentPointPtr->heading;
                            
                            [segmentPoint fetchExtensions:segmentPointRef->shared_ptr()];
                            
                            [self processBounds:segmentPoint.position];
                            [segmentPoints addObject:segmentPoint];
                        }
                        trkSegment.points = segmentPoints;
                    }
                    trkSegment.trkseg = trkSegmentRef->shared_ptr();
                    [trkSegment fetchExtensions:trkSegmentRef->shared_ptr()];
                    [trkSegment fillRouteDetails];
                    [trkSegment fillExtensions];
                    [trkSegment fillExtensions:trkSegmentRef->shared_ptr()];
                    [trkSegments addObject:trkSegment];
                }
                
                track.segments = trkSegments;
            }
            
            [track fetchExtensions:trackRef->shared_ptr()];
            
            track.trk = trackRef->shared_ptr();
            [tracks addObject:track];
        }
        self.tracks = tracks;
    }

    // Routes
    if (!gpxDocument->routes.isEmpty())
    {
        QList<OsmAnd::Ref<OsmAnd::GpxDocument::Route>> routesRef = gpxDocument->routes;
        NSMutableArray<OARoute *> *routes = [NSMutableArray array];
        for (const auto& routeConst : routesRef)
        {
            OsmAnd::Ref<OsmAnd::GpxDocument::Route> *routeRef = (OsmAnd::Ref<OsmAnd::GpxDocument::Route> *) &routeConst;
            const std::shared_ptr<const OsmAnd::GpxDocument::Route> routePtr = routeRef->shared_ptr();

            OARoute *route = [[OARoute alloc] init];
            route.name = routePtr->name.toNSString();
            route.desc = routePtr->description.toNSString();

            if (!routePtr->points.isEmpty())
            {
                NSMutableArray<OAWptPt *> *routePoints = [NSMutableArray array];

                for (const auto& routePointConst : routePtr->points)
                {
                    OsmAnd::Ref<OsmAnd::GpxDocument::WptPt> *routePointRef = (OsmAnd::Ref<OsmAnd::GpxDocument::WptPt>*) & routePointConst;
                    const std::shared_ptr<const OsmAnd::GpxDocument::WptPt> routePointPtr = routePointRef->shared_ptr();

                    OAWptPt *routePoint = [[OAWptPt alloc] init];

                    routePoint.position = CLLocationCoordinate2DMake(routePointPtr->position.latitude, routePointPtr->position.longitude);
                    routePoint.name = routePointPtr->name.toNSString();
                    routePoint.desc = routePointPtr->description.toNSString();
                    routePoint.elevation = routePointPtr->elevation;
                    routePoint.time = routePointPtr->timestamp.isNull() ? 0 : routePointPtr->timestamp.toSecsSinceEpoch();
                    routePoint.comment = routePointPtr->comment.toNSString();
                    routePoint.type = routePointPtr->type.toNSString();
                    routePoint.links = [self.class fetchLinks:routePointPtr->links];
                    routePoint.horizontalDilutionOfPrecision = routePointPtr->horizontalDilutionOfPrecision;
                    routePoint.verticalDilutionOfPrecision = routePointPtr->verticalDilutionOfPrecision;
                    routePoint.speed = routePointPtr->speed;
                    routePoint.heading = routePointPtr->heading;
                    
                    [routePoint fetchExtensions:routePointRef->shared_ptr()];
                    
                    [self processBounds:routePoint.position];
                    [routePoints addObject:routePoint];
                    
                }
                route.points = routePoints;
            }
            [route fetchExtensions:routeRef->shared_ptr()];
            [routes addObject:route];
        }
        self.routes = routes;
    }

    NSMutableArray<OAWptPt *> *points = [NSMutableArray array];
    NSMutableDictionary<NSString *, OAPointsGroup *> *pointsGroups = [NSMutableDictionary dictionary];

    // Points group
    if (!gpxDocument->pointsGroups.isEmpty())
    {
        for (auto it = gpxDocument->pointsGroups.constBegin(); it != gpxDocument->pointsGroups.constEnd(); ++it)
        {
            const QString &groupName = it.key();
            OsmAnd::Ref<OsmAnd::GpxDocument::PointsGroup> *groupRef = (OsmAnd::Ref<OsmAnd::GpxDocument::PointsGroup>*)&it.value();
            const std::shared_ptr<const OsmAnd::GpxDocument::PointsGroup> groupPtr = groupRef->shared_ptr();

            OAPointsGroup *pointsGroup = [[OAPointsGroup alloc] initWithName:groupPtr->name.toNSString()];
            pointsGroup.iconName = groupPtr->iconName.toNSString();
            pointsGroup.backgroundType = groupPtr->backgroundType.toNSString();
            pointsGroup.color = [UIColor colorWithRed:groupPtr->color.r/255.0
                                                green:groupPtr->color.g/255.0
                                                 blue:groupPtr->color.b/255.0
                                                alpha:groupPtr->color.a/255.0];

            if (!groupPtr->points.isEmpty())
            {
                const QList<OsmAnd::Ref<OsmAnd::GpxDocument::WptPt>> pointsConst = groupPtr->points;

                NSMutableArray<OAWptPt *> *wptPts = [NSMutableArray array];
                for (const auto& wptPtConst : pointsConst)
                {
                    OsmAnd::Ref<OsmAnd::GpxDocument::WptPt> *wptPtRef = (OsmAnd::Ref<OsmAnd::GpxDocument::WptPt> *) &wptPtConst;
                    const std::shared_ptr<const OsmAnd::GpxDocument::WptPt> wptPtPtr = wptPtRef->shared_ptr();

                    OAWptPt *wptPt = [self.class fetchWpt:wptPtRef->shared_ptr()];
                    [self processBounds:wptPt.position];

                    [wptPts addObject:wptPt];
                    [points addObject:wptPt];
                }
                pointsGroup.points = wptPts;
            }
            pointsGroups[groupName.toNSString()] = pointsGroup;
        }
    }
    // Location Marks
    else if (!gpxDocument->points.isEmpty())
    {
        for (const auto& wptPtConst : gpxDocument->points)
        {
            OsmAnd::Ref<OsmAnd::GpxDocument::WptPt> *wptPtRef = (OsmAnd::Ref<OsmAnd::GpxDocument::WptPt> *) &wptPtConst;

            OAWptPt *wptPt = [self.class fetchWpt:wptPtRef->shared_ptr()];
            [self processBounds:wptPt.position];

            OAPointsGroup *pointsGroup =  pointsGroups[pointsGroup.name];
            if (!pointsGroup)
            {
                pointsGroup = [[OAPointsGroup alloc] initWithWptPt:wptPt];
                pointsGroups[pointsGroup.name] = pointsGroup;
            }

            pointsGroup.points = [pointsGroup.points arrayByAddingObject:wptPt];
            [points addObject:wptPt];
        }
    }

    self.points = points;
    self.pointsGroups = pointsGroups;

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

+ (void) fillLinks:(QList<OsmAnd::Ref<OsmAnd::GpxDocument::Link>>&)links linkArray:(NSArray<OALink *> *)linkArray
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
    if (m.links)
        [self fillLinks:meta->links linkArray:m.links];
    meta->keywords = QString::fromNSString(m.keywords);
    [m fillExtensions:meta];

    if (m.author)
    {
        std::shared_ptr<OsmAnd::GpxDocument::Author> author;
        author.reset(new OsmAnd::GpxDocument::Author());
        author->name = QString::fromNSString(m.author.name);
        author->email = QString::fromNSString(m.author.email);
        if (m.author.link)
        {
            QList<OsmAnd::Ref<OsmAnd::GpxDocument::Link>> links;
            [self fillLinks:links linkArray:@[m.author.link]];
            if (links.size() > 0)
                author->link = links.first();
        }
        [m.author fillExtensions:author];
        meta->author = author;
    }

    if (m.copyright)
    {
        std::shared_ptr<OsmAnd::GpxDocument::Copyright> copyright;
        copyright.reset(new OsmAnd::GpxDocument::Copyright());
        copyright->author = QString::fromNSString(m.copyright.author);
        copyright->year = QString::fromNSString(m.copyright.year);
        copyright->license = QString::fromNSString(m.copyright.license);
        [m.copyright fillExtensions:copyright];
        meta->copyright = copyright;
    }
}

+ (void)fillPointsGroup:(OAWptPt *)wptPt
               wptPtPtr:(const std::shared_ptr<OsmAnd::GpxDocument::WptPt> &)wptPtPtr
                    doc:(const std::shared_ptr<OsmAnd::GpxDocument> &)doc
{
    std::shared_ptr<OsmAnd::GpxDocument::PointsGroup> pointsGroupRef = doc->pointsGroups[QString::fromNSString(wptPt.type)];
    if (pointsGroupRef == nullptr)
    {
        pointsGroupRef.reset(new OsmAnd::GpxDocument::PointsGroup());
        pointsGroupRef->name = QString::fromNSString(wptPt.type);
        pointsGroupRef->iconName = QString::fromNSString([wptPt getIcon]);
        pointsGroupRef->backgroundType = QString::fromNSString([wptPt getBackgroundIcon]);
        pointsGroupRef->color = [[wptPt getColor] toFColorARGB];
        doc->pointsGroups[pointsGroupRef->name] = pointsGroupRef;
    }
    if (!pointsGroupRef->points.contains(wptPtPtr))
        pointsGroupRef->points.append(wptPtPtr);
    if (!doc->points.contains(wptPtPtr))
        doc->points.append(wptPtPtr);
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

    NSMutableArray<OAGpxExtension *> *extArray = [w.extensions mutableCopy];
    NSString *profile = [w getProfileType];
    if ([GAP_PROFILE_TYPE isEqualToString:profile])
    {
        OAGpxExtension *profileExtension = [w getExtensionByKey:PROFILE_TYPE_EXTENSION];
        [extArray removeObject:profileExtension];
    }

    w.extensions = extArray;
    [w fillExtensions:wpt];
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

+ (void)fillPointsGroup:(std::shared_ptr<OsmAnd::GpxDocument::PointsGroup>)pg usingPointsGroup:(OAPointsGroup *)pointsGroup
{
    std::shared_ptr<OsmAnd::GpxDocument::WptPt> wpt;

    pg->name = QString::fromNSString(pointsGroup.name);
    pg->iconName = QString::fromNSString(pointsGroup.iconName);
    pg->backgroundType = QString::fromNSString(pointsGroup.backgroundType);
    pg->color = [pointsGroup.color toFColorARGB];

    for (OAWptPt *wptPt in pointsGroup.points)
    {
        wpt.reset(new OsmAnd::GpxDocument::WptPt());
        [self.class fillWpt:wpt usingWpt:wptPt];
        pg->points.append(wpt);
        wpt = nullptr;
    }
}

- (BOOL) saveTo:(NSString *)filename
{
    std::shared_ptr<OsmAnd::GpxDocument> document;
    std::shared_ptr<OsmAnd::GpxDocument::Metadata> metadata;
    std::shared_ptr<OsmAnd::GpxDocument::WptPt> wpt;
    std::shared_ptr<OsmAnd::GpxDocument::Track> trk;
    std::shared_ptr<OsmAnd::GpxDocument::Route> rte;
    std::shared_ptr<OsmAnd::GpxDocument::PointsGroup> pg;

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

    if (self.pointsGroups.count > 0)
    {
        for (NSString *groupName in self.pointsGroups.allKeys)
        {
            OAPointsGroup *pointsGroup = self.pointsGroups[groupName];

            pg.reset(new OsmAnd::GpxDocument::PointsGroup());
            [self.class fillPointsGroup:pg usingPointsGroup:pointsGroup];
            document->pointsGroups.insert(QString::fromNSString(groupName), pg);
            document->points.append(pg->points);
            pg = nullptr;
        }
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
    [self fillNetworkRouteKeys:document];

    return document->saveTo(QString::fromNSString(filename), QString::fromNSString([OAAppVersion getFullVersionWithAppName]));
}

- (void) fillNetworkRouteKeys:(const std::shared_ptr<OsmAnd::GpxDocument> &)doc
{
    QMap<QString, QString> res;
    for (NSString *key in self.networkRouteKeyTags)
    {
        res.insert(QString::fromNSString(key), QString::fromNSString(self.networkRouteKeyTags[key]));
    }
    doc->networkRouteKeyTags = res;
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
    NSMutableArray<OAWptPt *> *points = [NSMutableArray array];
    for (OATrack *track in _tracks)
    {
        for (OATrkSegment *s in track.segments)
        {
            if (s.points.count > 0)
            {
                s.points.firstObject.firstPoint = YES;
                s.points.lastObject.lastPoint = YES;
                [points addObjectsFromArray:s.points];
            }
        }
    }
    segment.points = points;
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
    OATrkSegment *generalSegment = [self getGeneralSegment];
    if (generalSegment)
    {
        [OAGPXTrackAnalysis splitSegment:metric secondaryMetric:secondaryMetric metricLimit:metricLimit splitSegments:splitSegments segment:generalSegment joinSegments:joinSegments];
    }
    else
    {
        for (OATrack *subtrack in self.tracks)
        {
            for (OATrkSegment *segment in subtrack.segments)
            {
                [OAGPXTrackAnalysis splitSegment:metric secondaryMetric:secondaryMetric metricLimit:metricLimit splitSegments:splitSegments segment:segment joinSegments:joinSegments];
            }
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

- (BOOL) hasTrkPtWithElevation
{
    return [self hasTrkPt:YES];
}

- (BOOL) hasTrkPt
{
    return [self hasTrkPt:NO];
}

- (BOOL) hasTrkPt:(BOOL)withElevation
{
    for (OATrack *t in _tracks)
    {
        for (OATrkSegment *ts in t.segments)
        {
            if (withElevation)
            {
                for (OAWptPt *tPt in ts.points)
                {
                    if (!isnan(tPt.elevation))
                        return YES;
                }
            }
            else if (ts.points.count > 0)
            {
                return YES;
            }
        }
    }
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

- (NSArray<OAWptPt *> *)getAllPoints
{
    NSMutableArray<OAWptPt *> *total = [NSMutableArray array];
    [total addObjectsFromArray:_points];
    [total addObjectsFromArray:[self getAllSegmentsPoints]];
    return total;
}

- (NSArray<OAWptPt *> *)getAllSegmentsPoints
{
    NSMutableArray<OAWptPt *> *points = [NSMutableArray array];
    for (OATrack *track in self.tracks)
    {
        if (!track.generalTrack)
        {
            for (OATrkSegment *segment in track.segments)
            {
                if (!segment.generalSegment)
                    [points addObjectsFromArray:segment.points];
            }
        }
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
        NSString *color = point.type == nil ? @"" : [point getColor].toHexARGBString;
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
        NSString *color = point.type == nil ? @"" : [point getColor].toHexARGBString;
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

- (NSArray<OATrack *> *) getTracks:(BOOL)includeGeneralTrack
{
    NSMutableArray<OATrack *> *tracks = [NSMutableArray array];
    for (OATrack *track in self.tracks)
    {
        if (includeGeneralTrack || !track.generalTrack)
        {
            [tracks addObject:track];
        }
    }
    return tracks;
}

@end

