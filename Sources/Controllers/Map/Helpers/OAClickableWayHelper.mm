//
//  OAClickableWayHelper.mm
//  OsmAnd
//
//  Created by Max Kojin on 07/05/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

// OsmAnd/src/net/osmand/plus/track/clickable/ClickableWayHelper.java
// git revision 67986ad06706ddf7f5a87eb3bb3c7a545ad957fe

#import "OAClickableWayHelper.h"
#import "OARenderedObject.h"
#import "QuadRect.h"
#import "OAAppVersion.h"
#import "OAClickableWayMenuProvider.h"
#import "OsmAnd_Maps-Swift.h"

#include <OsmAndCore/Data/ObfMapObject.h>
#include <OsmAndCore/Data/BinaryMapObject.h>

@implementation OAClickableWayHelper
{
    NSSet<NSString *> *_clickableTags;
    NSDictionary<NSString *, NSString *> *_forbiddenTags;
    NSSet<NSString *> *_requiredTagsAny;
    NSDictionary<NSString *, NSString *> *_gpxColors;
    OAClickableWayMenuProvider *_activator;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    _clickableTags = [NSSet setWithArray:@[
        @"piste:type",
        @"piste:difficulty",
        @"mtb:scale",
        @"dirtbike:scale",
        @"snowmobile=yes",
        @"snowmobile=designated",
        @"snowmobile=permissive"
    ]];
    
    _requiredTagsAny = [NSSet setWithArray:@[
        @"name",
        @"ref",
        @"piste:name",
        @"mtb:name"
    ]];
    
    _forbiddenTags = @{
        @"area": @"yes",
        @"access": @"no",
        @"aerialway": @"*"
    };
    _gpxColors = @{
        @"0": @"brown",
        @"1": @"green",
        @"2": @"blue",
        @"3": @"red",
        @"4": @"black",
        @"5": @"black",
        @"6": @"black",
        @"novice": @"green",
        @"easy": @"blue",
        @"intermediate": @"red",
        @"advanced": @"black",
        @"expert": @"black",
        @"freeride": @"yellow"
        // others are default (red)
    };
    
    _activator = [[OAClickableWayMenuProvider alloc] init];
}

- (OAClickableWayMenuProvider *)getContextMenuProvider
{
    return _activator;
}

- (BOOL)isClickableWay:(OARenderedObject *)renderedObject
{
    NSString *name = [renderedObject name];
    return renderedObject.x.count > 1 && [self isClickableWayTags:name tags:renderedObject.tags]; // v1
}

- (BOOL)isClickableWay:(const std::shared_ptr<const OsmAnd::MapObject>)obfMapObject tags:(NSDictionary<NSString *, NSString *> *)tags
{
    NSString *name = obfMapObject->getCaptionInNativeLanguage().toNSString();
    return obfMapObject->points31.size() > 1 && [self isClickableWayTags:name tags:tags]; // v2 with prefetched tags
}

- (ClickableWay *)loadClickableWay:(CLLocation *)selectedLatLon renderedObject:(OARenderedObject *)renderedObject
{
    uint64_t osmId = [ObfConstants getOsmId:renderedObject.obfId >> AMENITY_ID_RIGHT_SHIFT];
    MutableOrderedDictionary<NSString *,NSString *> *tags = renderedObject.tags;
    NSString *name = renderedObject.name;
    NSMutableArray<NSNumber *> *xPoints = renderedObject.x;
    NSMutableArray<NSNumber *> *yPoints = renderedObject.y;
    OASKQuadRect *bbox = [self calcSearchQuadRect:xPoints yPoints:yPoints];
    return [self loadClickableWay:selectedLatLon bbox:bbox xPoints:xPoints yPoints:yPoints osmId:osmId name:name tags:tags];
}

- (ClickableWay *)loadClickableWay:(CLLocation *)selectedLatLon obfMapObject:(const std::shared_ptr<const OsmAnd::MapObject>)obfMapObject tags:(NSDictionary<NSString *, NSString *> *)tags
{
    if (const auto binaryMapObject = std::dynamic_pointer_cast<const OsmAnd::BinaryMapObject>(obfMapObject))
    {
        uint64_t obfId = binaryMapObject->id.id;
        uint64_t osmId = [ObfConstants getOsmId:obfId >> AMENITY_ID_RIGHT_SHIFT];
        NSString *name = obfMapObject->getCaptionInNativeLanguage().toNSString();
        const auto points31 = obfMapObject->points31;
        NSMutableArray<NSNumber *> *xPoints = [NSMutableArray new];
        NSMutableArray<NSNumber *> *yPoints = [NSMutableArray new];
        
        for (int i = 0; i < points31.size(); i++)
        {
            [xPoints addObject:@(points31[i].x)];
            [yPoints addObject:@(points31[i].y)];
        }
        OASKQuadRect *bbox = [self calcSearchQuadRect:xPoints yPoints:yPoints];
        return [self loadClickableWay:selectedLatLon bbox:bbox xPoints:xPoints yPoints:yPoints osmId:osmId name:name tags:tags];
    }
    return nil;
}

- (ClickableWay *)loadClickableWay:(CLLocation *)selectedLatLon bbox:(OASKQuadRect *)bbox xPoints:(NSMutableArray<NSNumber *> *)xPoints yPoints:(NSMutableArray<NSNumber *> *)yPoints osmId:(uint64_t)osmId name:(NSString *)name tags:(MutableOrderedDictionary<NSString *,NSString *> *)tags
{
    
    OASGpxFile *gpxFile = [[OASGpxFile alloc] initWithAuthor:[OAAppVersion getFullVersionWithAppName]];
    OASRouteActivityHelper *helper = OASRouteActivityHelper.shared;
    
    for (NSString *clickableTagValue in _clickableTags)
    {
        NSString *tag = [[clickableTagValue componentsSeparatedByString:@"="] firstObject];
        NSString *value = tags[tag];
        if (!NSStringIsEmpty(value))
        {
            OASRouteActivity *activity = [helper findActivityByTagTag:clickableTagValue];
            if (activity)
            {
                NSString *activityType = activity.id;
                [gpxFile.metadata getExtensionsToWrite][[OASGpxUtilities.shared ACTIVITY_TYPE]] = activityType;
                break;
            }
        }
    }
    
    [[gpxFile.metadata getExtensionsToWrite] addEntriesFromDictionary:tags];
    [gpxFile.metadata getExtensionsToWrite][@"way_id"] = [NSString stringWithFormat:@"%d", osmId];
    
    OASTrkSegment *trkSegment = [[OASTrkSegment alloc] init];
    for (int i = 0; i < min(xPoints.count, yPoints.count); i++)
    {
        OASWptPt *wpt = [[OASWptPt alloc] init];
        [wpt setLat:[OASKMapUtils.shared get31LatitudeYTileY:[yPoints[i] doubleValue]]];
        [wpt setLon:[OASKMapUtils.shared get31LongitudeXTileX:[xPoints[i] doubleValue]]];
        [trkSegment.points addObject:wpt];
    }
    
    OASTrack *track = [[OASTrack alloc] init];
    [track.segments addObject:trkSegment];
    [gpxFile setTracks:@[track]];
    
    NSString *color = [self getGpxColorByTags:tags];
    if (color)
    {
        [gpxFile setColorColor_:color];
    }
   
    return [[ClickableWay alloc] initWithGpxFile:gpxFile osmId:osmId name:name selectedLatLon:selectedLatLon bbox:bbox];
}

- (NSString *)getGpxColorByTags:(MutableOrderedDictionary<NSString *,NSString *> *)tags
{
    for (NSString *key in _clickableTags)
    {
        NSString *value = tags[key];
        if (value)
        {
            for (NSString *matchColorKey in _gpxColors)
            {
                if ([value containsString:matchColorKey])
                {
                    return _gpxColors[matchColorKey];
                }
            }
        }
    }
    return nil;
}

- (OASKQuadRect *)calcSearchQuadRect:(NSMutableArray<NSNumber *> *)xPoints yPoints:(NSMutableArray<NSNumber *> *)yPoints
{
    OASKQuadRect *bbox = [[OASKQuadRect alloc] init];
    for (int i = 0; i < min(xPoints.count, yPoints.count); i++)
    {
        double x = [xPoints[i] doubleValue];
        double y = [yPoints[i] doubleValue];
        
        // [bbox expandLeft:x top:y right:x bottom:y];  // Kotlin func runs with bug. Sometimes it swaps left-right, or top-bottom;
        [self expandBbox:bbox left:x top:y right:x bottom:y];
    }
    return bbox;
}

- (void)expandBbox:(OASKQuadRect *)bbox left:(double)left top:(double)top right:(double)right bottom:(double)bottom
{
    BOOL hasInitialState = bbox.left == 0 && bbox.top == 0 && bbox.right == 0 && bbox.bottom == 0;
    if (hasInitialState)
    {
        bbox.left = left;
        bbox.top = top;
        bbox.right = right;
        bbox.bottom = bottom;
    }
    else
    {
        bbox.left = left <= right ? min(left, bbox.left) : max(left, bbox.left);
        bbox.right = left <= right ? max(right, bbox.right) : min(right, bbox.right);
        bbox.top = top <= bottom ? min(top, bbox.top) : max(top, bbox.top);
        bbox.bottom = top <= bottom ? max(bottom, bbox.bottom) : min(bottom, bbox.bottom);
    }
}

- (BOOL)isClickableWayTags:(NSString *)name tags:(NSDictionary<NSString *, NSString *> *)tags
{
    for (NSString *forbiddenKey in _forbiddenTags)
    {
        NSString *forbiddenValue = _forbiddenTags[forbiddenKey];
        NSString *tagValue = tags[forbiddenKey];
        if ([forbiddenValue isEqualToString:tagValue] ||
            ([@"*" isEqualToString:forbiddenValue] && tagValue))
        {
            return  NO;
        }
    }
    
    for (NSString *required in _requiredTagsAny)
    {
        // some objects have name passed from object props but not in the tags
        BOOL isRequiredNameFound = [required isEqualToString:@"name"] && !NSStringIsEmpty(name);
                    
        if (tags[required] || isRequiredNameFound)
        {
            for (NSString *key in tags)
            {
                if ([_clickableTags containsObject:key])
                    return YES;
                
                NSString *value = tags[key]; // snowmobile=yes, etc
                if (value )
                {
                    NSString *keyValueLine = [NSString stringWithFormat:@"%@=%@", key, value];
                    if ([_clickableTags containsObject:keyValueLine])
                        return YES;
                }
            }
        }
    }
    return NO;
}

@end
