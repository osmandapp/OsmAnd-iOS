//
//  OARouteStatisticsHelper.m
//  OsmAnd
//
//  Created by Paul on 13.12.2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OARouteStatisticsHelper.h"
#import "OARootViewController.h"
#import "OAMapViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapStyleSettings.h"
#import "OrderedDictionary.h"
#import "OsmAndApp.h"
#import "OARouteStatistics.h"
#import "OANativeUtilities.h"
#import "OAApplicationMode.h"

#include <OsmAndCore.h>
#include <OsmAndCore/ResourcesManager.h>
#include <OsmAndCore/Map/MapStylesCollection.h>
#include <OsmAndCore/Map/ResolvedMapStyle.h>


#define H_STEP 5.0
#define H_SLOPE_APPROX 100
#define MIN_INCLINE -101
#define MIN_DIVIDED_INCLINE -20
#define MAX_INCLINE 100
#define MAX_DIVIDED_INCLINE 21
#define STEP 4

#define STEEPNESS_TAG @"steepness="

static NSArray<NSNumber *> *_boundariesArray;
static NSArray<NSString *> *_boundariesClass;

@implementation OARouteSegmentWithIncline

@end

@implementation OATrackChartPoints

@end

@implementation OARouteStatisticsHelper

+ (void)initialize
{
    NSInteger NUM = ((MAX_DIVIDED_INCLINE - MIN_DIVIDED_INCLINE) / STEP) + 3;
    NSMutableArray<NSNumber *> *boundariesArr = [NSMutableArray arrayWithCapacity:NUM];
    NSMutableArray<NSString *> *boundariesClass = [NSMutableArray arrayWithCapacity:NUM];
    [boundariesArr addObject:@(MIN_INCLINE)];
    [boundariesClass addObject:[NSString stringWithFormat:@"%@%d_%d", STEEPNESS_TAG, MIN_INCLINE + 1, MIN_DIVIDED_INCLINE]];
    
    for (int i = 1; i < NUM - 1; i++)
    {
        [boundariesArr addObject:@(MIN_DIVIDED_INCLINE + (i - 1) * STEP)];
        [boundariesClass addObject:[NSString stringWithFormat:@"%@%d_%d", STEEPNESS_TAG, (boundariesArr[i - 1].intValue + 1), boundariesArr[i].intValue]];
    }
    [boundariesArr addObject:@(MAX_INCLINE)];
    [boundariesClass addObject:[NSString stringWithFormat:@"%@%d_%d", STEEPNESS_TAG, MAX_DIVIDED_INCLINE, MAX_INCLINE]];
    
    _boundariesArray = [NSArray arrayWithArray:boundariesArr];
    _boundariesClass = [NSArray arrayWithArray:boundariesClass];
}

+ (void) getAttributeNames:(NSMutableArray<NSString *> *)attributeNames mapSourceResource:(const std::shared_ptr<const OsmAnd::ResourcesManager::Resource> &)mapSourceResource {
    if (mapSourceResource->type == OsmAnd::ResourcesManager::ResourceType::MapStyle)
    {
        const auto& unresolvedMapStyle = std::static_pointer_cast<const OsmAnd::ResourcesManager::MapStyleMetadata>(mapSourceResource->metadata)->mapStyle;
        if (unresolvedMapStyle == nullptr)
            return;
        
        QString infoPrefix = QString::fromNSString(ROUTE_INFO_PREFIX);
        for (const auto& param : unresolvedMapStyle->attributes)
        {
            QString paramName = param->name;
            if (paramName.startsWith(infoPrefix))
            {
                [attributeNames addObject:paramName.toNSString()];
            }
        }
    }
}

+ (NSArray<OARouteStatistics *> *) calculateRouteStatistic:(vector<SHARED_PTR<RouteSegmentResult> >)route
{
    NSMutableArray<NSString *> *attributeNames = [NSMutableArray new];
    OsmAndAppInstance app = [OsmAndApp instance];
    
    auto resourceId = QString::fromNSString(app.data.lastMapSource.resourceId);
    auto mapSourceResource = app.resourcesManager->getResource(resourceId);
    
    if (!mapSourceResource)
    {
        resourceId = QString::fromNSString([OAAppData defaultMapSource].resourceId);
        mapSourceResource = app.resourcesManager->getResource(resourceId);
    }

    if (!mapSourceResource)
        return nil;
    
    [self getAttributeNames:attributeNames mapSourceResource:mapSourceResource];
    
    if (attributeNames.count == 0)
    {
        resourceId = QString::fromNSString([OAAppData defaultMapSource].resourceId);
        mapSourceResource = app.resourcesManager->getResource(resourceId);
        [self getAttributeNames:attributeNames mapSourceResource:mapSourceResource];
    }
    
    return [self calculateRouteStatistic:route attributeNames:attributeNames];
}

+ (NSArray<OARouteStatistics *> *) calculateRouteStatistic:(vector<SHARED_PTR<RouteSegmentResult> >)route attributeNames:(NSArray<NSString *> *)attributeNames
{
    NSArray<OARouteSegmentWithIncline *> *routeSegmentWithInclines = [self.class calculateInclineRouteSegments:route];
    
    const auto& defaultPresentationEnv = OsmAndApp.instance.defaultRenderer;
    
    // "steepnessColor", "surfaceColor", "roadClassColor", "smoothnessColor"
    // steepness=-19_-16
    NSMutableArray<OARouteStatistics *> *result = [NSMutableArray new];
    for(NSString *attributeName in attributeNames)
    {
        OARouteStatisticsComputer *statisticsComputer =
                [[OARouteStatisticsComputer alloc] initWithPresentationEnvironment:defaultPresentationEnv];
        OARouteStatistics *routeStatistics = [statisticsComputer computeStatistic:routeSegmentWithInclines attribute:attributeName];
        if (routeStatistics.partition.count != 0 && (routeStatistics.partition.count != 1 || !routeStatistics.partition[kUndefinedAttr]))
            [result addObject:routeStatistics];
    }
    return result;
}

+ (NSArray<OARouteSegmentWithIncline *> *) calculateInclineRouteSegments:(vector<SHARED_PTR<RouteSegmentResult> >) route
{
    NSMutableArray<OARouteSegmentWithIncline *> *input = [NSMutableArray new];
    float prevHeight = 0;
    int totalArrayHeightsLength = 0;
    for (const auto& r : route)
    {
        const auto& heightValues = r->getHeightValues();
        OARouteSegmentWithIncline *incl = [[OARouteSegmentWithIncline alloc] init];
        incl.dist = r->distance;
        incl.obj = r->object;
        [input addObject:incl];
        float prevH = prevHeight;
        int indStep = 0;
        int capacity = (int) ((incl.dist) / H_STEP) + 1;
        if (incl.dist > H_STEP)
        {
            // for 10.1 meters 3 points (0, 5, 10)
            incl.interpolatedHeightByStep = [NSMutableArray arrayWithObject:@(0) count:capacity];
            totalArrayHeightsLength += incl.interpolatedHeightByStep.count;
        }
        if (heightValues.size() > 0)
        {
            int indH = 2;
            float distCum = 0;
            prevH = heightValues[1];
            incl.h = prevH;
            if (incl.interpolatedHeightByStep != nil && incl.interpolatedHeightByStep.count > indStep)
                incl.interpolatedHeightByStep[indStep++] = @(prevH);

            while(incl.interpolatedHeightByStep != nil &&
                    indStep < incl.interpolatedHeightByStep.count && indH < heightValues.size())
            {
                float dist = heightValues[indH] + distCum;
                if(dist > indStep * H_STEP)
                {
                    if(dist == distCum)
                    {
                        incl.interpolatedHeightByStep[indStep] = @(prevH);
                    }
                    else
                    {
                        incl.interpolatedHeightByStep[indStep] = @((float) (prevH +
                                                                            (indStep * H_STEP - distCum) *
                                                                            (heightValues[indH + 1] - prevH) / (dist - distCum)));
                    }
                    indStep++;
                }
                else
                {
                    distCum = dist;
                    prevH = heightValues[indH + 1];
                    indH += 2;
                }
            }
        }
        else
        {
            // skip first point if it doesn't have height values. This happens when the first segment is not connected to any road
            if (indStep == 0)
            {
                totalArrayHeightsLength -= incl.interpolatedHeightByStep.count;
                [input removeObject:incl];
                continue;
            }
            incl.h = prevH;
        }
        
        while(incl.interpolatedHeightByStep != nil &&
                indStep < incl.interpolatedHeightByStep.count)
        {
            incl.interpolatedHeightByStep[indStep++] = @(prevH);
        }
        prevHeight = prevH;
    }
    int slopeSmoothShift = (int) (H_SLOPE_APPROX / (2 * H_STEP));
    NSMutableArray<NSNumber *> *heightArray = [NSMutableArray arrayWithObject:@(0) count:totalArrayHeightsLength];
    int iter = 0;
    for (int i = 0; i < input.count; i++)
    {
        OARouteSegmentWithIncline *rswi = input[i];
        for (int k = 0; rswi.interpolatedHeightByStep != nil &&
                    k < rswi.interpolatedHeightByStep.count; k++)
        {
            heightArray[iter++] = rswi.interpolatedHeightByStep[k];
        }
    }
    iter = 0;
    int minSlope = INT_MAX;
    int maxSlope = INT_MIN;
    for(int i = 0; i < input.count; i++)
    {
        OARouteSegmentWithIncline *rswi = input[i];
        if(rswi.interpolatedHeightByStep != nil)
        {
            rswi.slopeByStep = [NSMutableArray arrayWithObject:@(0.f) count:rswi.interpolatedHeightByStep.count];
            
            for (int k = 0; k < rswi.slopeByStep.count; k++)
            {
                if (iter > slopeSmoothShift && iter + slopeSmoothShift < heightArray.count)
                {
                    double slope = (heightArray[iter + slopeSmoothShift].floatValue - heightArray[iter - slopeSmoothShift].floatValue) * 100 / H_SLOPE_APPROX;
                    rswi.slopeByStep[k] = @((float) slope);
                    minSlope = min((int) slope, minSlope);
                    maxSlope = max((int) slope, maxSlope);
                }
                iter++;
            }
        }
    }
    NSMutableArray<NSString *> *classFormattedStrings = [NSMutableArray arrayWithObject:@"" count:_boundariesArray.count];
    classFormattedStrings[0] = [self.class formatSlopeString:minSlope next:MIN_DIVIDED_INCLINE];
    classFormattedStrings[1] = [self.class formatSlopeString:minSlope next:MIN_DIVIDED_INCLINE];
    
    for (int k = 2; k < (NSInteger) _boundariesArray.count - 1; k++)
    {
        classFormattedStrings[k] = [self.class formatSlopeString:_boundariesArray[k - 1].intValue next:_boundariesArray[k].intValue];
    }
    classFormattedStrings[(NSInteger) _boundariesArray.count - 1] = [self.class formatSlopeString:MAX_DIVIDED_INCLINE next:maxSlope];
    
    for(NSInteger i = 0; i < input.count; i ++)
    {
        OARouteSegmentWithIncline *rswi = input[i];
        if(rswi.slopeByStep != nil)
        {
            rswi.slopeClass = [NSMutableArray arrayWithObject:@(0) count:rswi.slopeByStep.count];
            rswi.slopeClassUserString = [NSMutableArray arrayWithObject:@"" count:rswi.slopeByStep.count];
            
            for (int t = 0; t < rswi.slopeByStep.count; t++)
            {
                for (int k = 0; k < _boundariesArray.count; k++)
                {
                    if (rswi.slopeByStep[t].intValue <= _boundariesArray[k].intValue || k == _boundariesArray.count - 1)
                    {
                        rswi.slopeClass[t] = @(k);
                        rswi.slopeClassUserString[t] = classFormattedStrings[k];
                        break;
                    }
                }
                // end of break
            }
        }
    }
    return input;
}

+ (NSString *) formatSlopeString:(int) slope next:(int) next
{
    return [NSString stringWithFormat:@"%d%% → %d%%", slope, next];
}

@end

@implementation OARouteStatisticsComputer
{
    OAMapViewController *_mapViewController;
    std::shared_ptr<OsmAnd::MapPresentationEnvironment> _defaultPresentationEnvironment;
}

- (instancetype)initWithPresentationEnvironment:(std::shared_ptr<OsmAnd::MapPresentationEnvironment>)defaultPresentationEnv
{
    self = [super init];
    if (self) {
        _mapViewController = [OARootViewController instance].mapPanel.mapViewController;
        _defaultPresentationEnvironment = defaultPresentationEnv;
    }
    return self;
}

- (OARouteStatistics *) computeStatistic:(NSArray<OARouteSegmentWithIncline *> *) route attribute:(NSString *) attribute
{
    NSArray<OARouteSegmentAttribute *> *routeAttributes = [self processRoute:route attribute:attribute];
    NSDictionary<NSString *, OARouteSegmentAttribute *> *partition = [self makePartition:routeAttributes];
    float totalDistance = [self computeTotalDistance:routeAttributes];
    return [[OARouteStatistics alloc] initWithName:attribute elements:routeAttributes partition:partition totalDistance:totalDistance];
}

- (NSDictionary<NSString *, OARouteSegmentAttribute *> *) makePartition:(NSArray<OARouteSegmentAttribute *> *) routeAttributes
{
    NSMutableDictionary<NSString *, OARouteSegmentAttribute *> *partition = [NSMutableDictionary new];
    for (OARouteSegmentAttribute *attribute in routeAttributes)
    {
        OARouteSegmentAttribute *attr = attribute.getUserPropertyName == nil ? nil : partition[attribute.getUserPropertyName];
        if (attr == nil)
        {
            attr = [[OARouteSegmentAttribute alloc] initWithSegmentAttribute:attribute];
            [partition setObject:attr forKey:attribute.getUserPropertyName];
        }
        [attr incrementDistanceBy:attribute.distance];
    }
    NSArray<NSString *> *tmpKeys = partition.allKeys;
    NSArray<NSString *> *sortedKeys = [tmpKeys sortedArrayUsingComparator:^NSComparisonResult(NSString * _Nonnull obj1, NSString * _Nonnull obj2) {
        if ([obj1.lowerCase isEqualToString:kUndefinedAttr])
        {
            return NSOrderedDescending;
        }
        if ([obj2.lowerCase isEqualToString:kUndefinedAttr]) {
            return NSOrderedAscending;
        }
        NSInteger index1 = partition[obj1].slopeIndex;
        NSInteger index2 = partition[obj2].slopeIndex;
        if (index1 > index2)
            return NSOrderedDescending;
        else if (index1 < index2)
            return NSOrderedAscending;
        else
        {
            float dist1 = partition[obj1].distance;
            float dist2 = partition[obj2].distance;
            if (dist1 > dist2)
                return NSOrderedAscending;
            else if (dist1 < dist2)
                return NSOrderedDescending;
            else
                return NSOrderedSame;
        }
    }];
    
    MutableOrderedDictionary<NSString *, OARouteSegmentAttribute *> *sorted = [[MutableOrderedDictionary alloc] init];
    for (NSString *key in sortedKeys)
    {
        [sorted setObject:partition[key] forKey:key];
    }
    
    return sorted;
}

- (float) computeTotalDistance:(NSArray<OARouteSegmentAttribute *> *) attributes
{
    float distance = 0.;
    for (OARouteSegmentAttribute *attribute in attributes)
    {
        distance += attribute.distance;
    }
    return distance;
}

- (NSArray<OARouteSegmentAttribute *> *) processRoute:(NSArray<OARouteSegmentWithIncline *> *) route attribute:(NSString *) attribute
{
    NSMutableArray<OARouteSegmentAttribute *> *routes = [NSMutableArray new];
    OARouteSegmentAttribute *prev = nil;
    for (OARouteSegmentWithIncline *segment in route)
    {
        if (segment.slopeClass == nil || segment.slopeClass.count == 0)
        {
            OARouteSegmentAttribute *current = [self classifySegment:attribute slopeClass:-1 segment:segment];
            current.distance = segment.dist;
            if (prev != nil && prev.propertyName != nil &&
                [prev.propertyName isEqualToString:current.propertyName])
            {
                [prev incrementDistanceBy:current.distance];
            }
            else
            {
                [routes addObject:current];
                prev = current;
            }
        }
        else
        {
            for(NSInteger i = 0; i < segment.slopeClass.count; i++)
            {
                float d = (float) (i == 0 ? (segment.dist - H_STEP * (segment.slopeClass.count - 1)) : H_STEP);
                if (i > 0 && segment.slopeClass[i] == segment.slopeClass[i-1])
                {
                    [prev incrementDistanceBy:d];
                }
                else
                {
                    OARouteSegmentAttribute *current = [self classifySegment:attribute
                                                                  slopeClass:segment.slopeClass[i].intValue
                                                                     segment:segment];
                    current.distance = d;
                    if (prev != nil && prev.propertyName != nil &&
                        [prev.propertyName isEqualToString:current.propertyName])
                    {
                        [prev incrementDistanceBy:current.distance];
                    }
                    else
                    {
                        if(current.slopeIndex == segment.slopeClass[i].integerValue)
                            current.userPropertyName = segment.slopeClassUserString[i];

                        [routes addObject:current];
                        prev = current;
                    }
                }
            }
        }
    }
    return routes;
}


- (OARouteSegmentAttribute *) classifySegment:(NSString *) attribute slopeClass:(int) slopeClass segment:(OARouteSegmentWithIncline *) segment
{
    NSDictionary<NSString *, NSString *> *settings = [self getRenderingParamsForAttribute:attribute segment:segment slopeClass:slopeClass];
    NSDictionary<NSString *, NSNumber *> *renderingAttrs = [_mapViewController getRoadRenderingAttributes:attribute additionalSettings:settings];
    NSString *name = renderingAttrs.allKeys.firstObject;
    NSInteger color = renderingAttrs[name].integerValue;
    if ([name isEqualToString:kUndefinedAttr] && color == 0xFFFFFFFF)
    {
        // Search in the default environment
        const auto& defaultPair = _defaultPresentationEnvironment->getRoadRenderingAttributes(QString::fromNSString(attribute), [OANativeUtilities dictionaryToQHash:settings]);
        name = defaultPair.first.toNSString();
        color = defaultPair.second == 0 ? 0xFFFFFFFF : @(defaultPair.second).integerValue;
    }
    
    return [[OARouteSegmentAttribute alloc] initWithPropertyName:name color:color slopeIndex:slopeClass boundariesClass:_boundariesClass];
}

- (NSDictionary<NSString *, NSString *> *) getRenderingParamsForAttribute:(NSString *) attribute
                                                                  segment:(OARouteSegmentWithIncline *) segment
                                                               slopeClass:(int) slopeClass
{
    SHARED_PTR<RouteDataObject> obj = segment.obj;
    const auto& tps = obj->types;
    if ([attribute isEqualToString:@"routeInfo_steepness"] && slopeClass >= 0)
        return @{ @"additional" : _boundariesClass[slopeClass] };
    
    NSMutableDictionary<NSString *, NSString *> *result = [NSMutableDictionary new];
    for (int k = 0; k < tps.size(); k++)
    {
        auto& tp = obj->region->quickGetEncodingRule(tps[k]);
        if (tp.getTag() == "highway" || tp.getTag() == "route" ||
            tp.getTag() == "railway" || tp.getTag() == "aeroway" || tp.getTag() == "aerialway")
        {
            [result setObject:[[NSString alloc] initWithUTF8String:tp.getTag().c_str()] forKey:@"tag"];
            [result setObject:[[NSString alloc] initWithUTF8String:tp.getValue().c_str()] forKey:@"value"];
        }
        else if (([attribute isEqualToString:@"routeInfo_surface"] && tp.getTag() == "surface") ||
                 ([attribute isEqualToString:@"routeInfo_smoothness"] && tp.getTag() == "smoothness") ||
                 ([attribute isEqualToString:@"routeInfo_winter_ice_road"] && (tp.getTag() == "winter_road" || tp.getTag() == "ice_road")) ||
                 ([attribute isEqualToString:@"routeInfo_tracktype"] && tp.getTag() == "tracktype"))
        {
            [result setObject:[NSString stringWithFormat:@"%@=%@", [[NSString alloc] initWithUTF8String:tp.getTag().c_str()], [[NSString alloc] initWithUTF8String:tp.getValue().c_str()]] forKey:@"additional"];
        }
    }
    
    if (![attribute isEqualToString:@"routeInfo_roadClass"] && !result[@"additional"])
        return nil;
    
    return result;
}

@end
