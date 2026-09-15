//
//  OACppRouteConverter.mm
//  OsmAnd
//

#import "OACppRouteConverter.h"
#import "OsmAndSharedWrapper.h"

#include <routeSegmentResult.h>
#include <binaryRead.h>
#include <routeTypeRule.h>
#include <turnType.h>

#include <unordered_map>

// A road and the region it was read from are shared between every segment that sits on them, so
// each is converted once per call and handed out again afterwards.
typedef std::unordered_map<const RoutingIndex *, OASRouteRegion *> OARegionCache;
typedef std::unordered_map<const RouteDataObject *, OASRouteDataObject *> OARoadCache;

static NSString * toString(const std::string &s)
{
    NSString *res = [NSString stringWithUTF8String:s.c_str()];
    return res ? res : @"";
}

static OASKotlinIntArray * toIntArray(const std::vector<uint32_t> &values)
{
    OASKotlinIntArray *res = [OASKotlinIntArray arrayWithSize:(int32_t) values.size()];
    for (int32_t i = 0; i < (int32_t) values.size(); i++)
        [res setIndex:i value:(int32_t) values[i]];
    return res;
}

static OASKotlinIntArray * toIntArray(const std::vector<int> &values)
{
    OASKotlinIntArray *res = [OASKotlinIntArray arrayWithSize:(int32_t) values.size()];
    for (int32_t i = 0; i < (int32_t) values.size(); i++)
        [res setIndex:i value:values[i]];
    return res;
}

// An empty entry becomes null rather than an empty array: that is what the reader leaves behind for
// a point that carries nothing, and the callers test for it.
static OASKotlinArray<OASKotlinIntArray *> * toIntArrays(const std::vector<std::vector<uint32_t>> &values)
{
    if (values.empty())
        return nil;

    return [OASKotlinArray arrayWithSize:(int32_t) values.size() init:^id(OASInt *index) {
        const auto &value = values[index.intValue];
        return value.empty() ? nil : toIntArray(value);
    }];
}

@implementation OACppRouteConverter

+ (OASRouteRegion *) toSharedRegion:(const std::shared_ptr<RoutingIndex> &)region
{
    OASRouteRegion *res = [[OASRouteRegion alloc] init];
    res.name = toString(region->name);
    res.filePointer = region->filePointer;
    res.length = region->length;

    // Replaying the rules also sets the name, ref, destination, traffic sign and direction rule ids:
    // both sides derive them from the tag the same way, so they need no copying of their own.
    for (int32_t i = 0; i < (int32_t) region->routeEncodingRules.size(); i++)
    {
        const auto &rule = region->routeEncodingRules[i];
        if (rule.getTag().empty())
            continue;
        [res doInitRouteEncodingRuleId:i tags:toString(rule.getTag()) val:toString(rule.getValue())];
    }
    [res completeRouteEncodingRules];
    return res;
}

+ (OASRouteDataObject *) toSharedObject:(const std::shared_ptr<RouteDataObject> &)object
                                 region:(OASRouteRegion *)region
{
    OASRouteDataObject *res = [[OASRouteDataObject alloc] initWithRegion:region];
    res.id = object->id;
    res.pointsX = toIntArray(object->pointsX);
    res.pointsY = toIntArray(object->pointsY);
    res.types = toIntArray(object->types);
    res.pointTypes = toIntArrays(object->pointTypes);
    res.pointNameTypes = toIntArrays(object->pointNameTypes);

    if (!object->pointNames.empty())
    {
        res.pointNames = [OASKotlinArray arrayWithSize:(int32_t) object->pointNames.size()
                                                  init:^id(OASInt *index) {
            const auto &names = object->pointNames[index.intValue];
            if (names.empty())
                return nil;

            return [OASKotlinArray arrayWithSize:(int32_t) names.size() init:^id(OASInt *nameIndex) {
                return toString(names[nameIndex.intValue]);
            }];
        }];
    }

    if (!object->heightDistanceArray.empty())
    {
        OASKotlinFloatArray *heights = [OASKotlinFloatArray arrayWithSize:(int32_t) object->heightDistanceArray.size()];
        for (int32_t i = 0; i < (int32_t) object->heightDistanceArray.size(); i++)
            [heights setIndex:i value:(float) object->heightDistanceArray[i]];
        res.heightDistanceArray = heights;
    }

    if (!object->names.empty())
    {
        // The rule ids are kept in the order they were read in, as the reader keeps them; the values
        // live in a map on both sides. Roads built in code carry names without that order - then the
        // map's own order is the only one there is.
        std::vector<uint32_t> nameIds;
        if (!object->namesIds.empty())
        {
            for (const auto &nameId : object->namesIds)
                nameIds.push_back(nameId.first);
        }
        else
        {
            for (const auto &name : object->names)
                nameIds.push_back(name.first);
        }
        res.nameIds = toIntArray(nameIds);

        OASKTIntObjectMap<NSString *> *names = [[OASKTIntObjectMap alloc] initWithInitialCapacity:(int32_t) object->names.size()];
        for (const auto &name : object->names)
            [names putKey:name.first value:toString(name.second)];
        res.names = names;
    }

    for (int32_t i = 0; i < (int32_t) object->restrictions.size(); i++)
    {
        const auto &restriction = object->restrictions[i];
        [res setRestrictionK:i to:(int64_t) restriction.to type:(int32_t) restriction.type viaWay:(int64_t) restriction.via];
    }

    return res;
}

+ (OASTurnType *) toSharedTurnType:(const std::shared_ptr<TurnType> &)turnType
{
    if (!turnType)
        return nil;

    const auto &lanes = turnType->getLanes();
    return [[OASTurnType alloc] initWithValue:turnType->getValue()
                                      exitOut:turnType->getExitOut()
                                    turnAngle:turnType->getTurnAngle()
                                isSkipToSpeak:turnType->isSkipToSpeak()
                                        lanes:lanes.empty() ? nil : toIntArray(lanes)
                           isPossibleLeftTurn:turnType->isPossibleLeftTurn()
                          isPossibleRightTurn:turnType->isPossibleRightTurn()];
}

+ (OASRouteSegmentResult *) toSharedSegment:(const std::shared_ptr<RouteSegmentResult> &)segment
                               regionsCache:(OARegionCache &)regions
                                 roadsCache:(OARoadCache &)roads
                        withAttachedRoutes:(BOOL)withAttachedRoutes
{
    OASRouteDataObject *object = nil;
    if (segment->object)
    {
        auto road = roads.find(segment->object.get());
        if (road != roads.end())
        {
            object = road->second;
        }
        else
        {
            OASRouteRegion *region = nil;
            if (segment->object->region)
            {
                auto cached = regions.find(segment->object->region.get());
                if (cached != regions.end())
                    region = cached->second;
                else
                    regions[segment->object->region.get()] = region = [self toSharedRegion:segment->object->region];
            }
            roads[segment->object.get()] = object = [self toSharedObject:segment->object region:region];
        }
    }

    OASRouteSegmentResult *res = [[OASRouteSegmentResult alloc] initWithRouteObject:object
                                                                    startPointIndex:segment->getStartPointIndex()
                                                                      endPointIndex:segment->getEndPointIndex()
                                                                  preAttachedRoutes:nil
                                                                        segmentTime:segment->segmentTime
                                                                        routingTime:segment->routingTime
                                                                              speed:segment->segmentSpeed
                                                                           distance:segment->distance
                                                                      gpxPointIndex:segment->getGpxPointIndex()
                                                                           turnType:[self toSharedTurnType:segment->turnType]];
    if (!segment->description.empty())
        [res setDescriptionShortD:toString(segment->description) full:toString(segment->description)];

    if (withAttachedRoutes)
    {
        // The roads that meet the segment at each of its points. The turn preparation has already
        // used them, but the exit information is read off them later, so they come over - one level
        // deep, without the roads that meet them in turn, which nothing reads.
        const auto &attached = segment->attachedRoutesFrontEnd;
        for (int i = 0; i < (int) attached.size(); i++)
        {
            for (const auto &route : attached[i])
            {
                [res attachRouteRoadIndex:segment->getStartPointIndex() + i
                                        r:[self toSharedSegment:route regionsCache:regions roadsCache:roads withAttachedRoutes:NO]];
            }
        }
    }

    return res;
}

+ (NSArray<OASRouteSegmentResult *> *) toSharedSegments:(const std::vector<std::shared_ptr<RouteSegmentResult>> &)segments
{
    OARegionCache regions;
    OARoadCache roads;
    NSMutableArray<OASRouteSegmentResult *> *res = [NSMutableArray arrayWithCapacity:segments.size()];
    for (const auto &segment : segments)
        [res addObject:[self toSharedSegment:segment regionsCache:regions roadsCache:roads withAttachedRoutes:YES]];

    return res;
}

@end
