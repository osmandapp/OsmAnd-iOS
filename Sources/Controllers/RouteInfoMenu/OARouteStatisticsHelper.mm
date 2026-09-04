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
#import "OsmAndApp.h"
#import "OANativeUtilities.h"
#import "OAApplicationMode.h"
#import "OAMapSource.h"
#import "OAAppData.h"
#import "OsmAndSharedWrapper.h"

#include <OsmAndCore.h>
#include <OsmAndCore/ResourcesManager.h>
#include <OsmAndCore/Map/MapStylesCollection.h>
#include <OsmAndCore/Map/ResolvedMapStyle.h>

#include <cstdint>


#define MIN_INCLINE -101
#define MIN_DIVIDED_INCLINE -20
#define MAX_INCLINE 100
#define MAX_DIVIDED_INCLINE 21
#define STEP 4

#define STEEPNESS_TAG @"steepness="
#define ROUTE_INFO_STEEPNESS @"routeInfo_steepness"

static NSArray<NSString *> *OARouteSlopeBoundaryClasses(void)
{
    static NSArray<NSString *> *boundariesClass;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSInteger count = ((MAX_DIVIDED_INCLINE - MIN_DIVIDED_INCLINE) / STEP) + 3;
        NSMutableArray<NSNumber *> *boundaries = [NSMutableArray arrayWithCapacity:count];
        NSMutableArray<NSString *> *classes = [NSMutableArray arrayWithCapacity:count];
        [boundaries addObject:@(MIN_INCLINE)];
        [classes addObject:[NSString stringWithFormat:@"%@%d_%d",
                                                      STEEPNESS_TAG,
                                                      MIN_INCLINE + 1,
                                                      MIN_DIVIDED_INCLINE]];
        for (int index = 1; index < count - 1; index++)
        {
            [boundaries addObject:@(MIN_DIVIDED_INCLINE + (index - 1) * STEP)];
            [classes addObject:[NSString stringWithFormat:@"%@%d_%d",
                                                          STEEPNESS_TAG,
                                                          boundaries[index - 1].intValue + 1,
                                                          boundaries[index].intValue]];
        }
        [classes addObject:[NSString stringWithFormat:@"%@%d_%d",
                                                      STEEPNESS_TAG,
                                                      MAX_DIVIDED_INCLINE,
                                                      MAX_INCLINE]];
        boundariesClass = [classes copy];
    });
    return boundariesClass;
}

static BOOL OAIsUndefinedRenderingAttribute(NSDictionary<NSString *, NSNumber *> * _Nullable attributes)
{
    NSString *name = attributes.allKeys.firstObject;
    NSNumber *color = name ? attributes[name] : nil;
    return name == nil || ([name isEqualToString:kUndefinedAttr] && color.unsignedIntValue == UINT32_MAX);
}

@implementation OARouteSegmentWithIncline

@end

@interface OARouteStatisticsAccessor : NSObject <OASIRouteStatisticsAccessor>

- (instancetype)initWithRoute:(const vector<SHARED_PTR<RouteSegmentResult> > &)route;

@end

@implementation OARouteStatisticsAccessor
{
    const vector<SHARED_PTR<RouteSegmentResult> > *_route;
}

- (instancetype)initWithRoute:(const vector<SHARED_PTR<RouteSegmentResult> > &)route
{
    self = [super init];
    if (self)
        _route = &route;
    return self;
}

- (int32_t)getSegmentsCount
{
    return (int32_t) _route->size();
}

- (float)getDistanceMetersSegmentIndex:(int32_t)segmentIndex
{
    return (*_route)[segmentIndex]->distance;
}

- (OASKotlinFloatArray *)getHeightValuesSegmentIndex:(int32_t)segmentIndex
{
    const std::vector<double> heightValues = (*_route)[segmentIndex]->getHeightValues();
    OASKotlinFloatArray *result = [OASKotlinFloatArray arrayWithSize:(int32_t) heightValues.size()];
    for (NSUInteger index = 0; index < heightValues.size(); index++)
        [result setIndex:(int32_t) index value:(float) heightValues[index]];
    return result;
}

- (int32_t)getRouteTypesCountSegmentIndex:(int32_t)segmentIndex
{
    const auto &segment = (*_route)[segmentIndex];
    return segment && segment->object ? (int32_t) segment->object->types.size() : 0;
}

- (NSString * _Nullable)getRouteTypeTagSegmentIndex:(int32_t)segmentIndex
                                     routeTypeIndex:(int32_t)routeTypeIndex
{
    return [self routeTypeStringSegmentIndex:segmentIndex routeTypeIndex:routeTypeIndex value:NO];
}

- (NSString * _Nullable)getRouteTypeValueSegmentIndex:(int32_t)segmentIndex
                                       routeTypeIndex:(int32_t)routeTypeIndex
{
    return [self routeTypeStringSegmentIndex:segmentIndex routeTypeIndex:routeTypeIndex value:YES];
}

- (NSString * _Nullable)routeTypeStringSegmentIndex:(int32_t)segmentIndex
                                      routeTypeIndex:(int32_t)routeTypeIndex
                                               value:(BOOL)value
{
    const auto &segment = (*_route)[segmentIndex];
    if (!segment || !segment->object || !segment->object->region
        || routeTypeIndex < 0 || routeTypeIndex >= (int32_t) segment->object->types.size())
    {
        return nil;
    }
    const auto &road = segment->object;
    uint32_t ruleId = road->types[routeTypeIndex];
    if (ruleId >= road->region->routeEncodingRules.size())
        return nil;

    const auto &rule = road->region->quickGetEncodingRule(ruleId);
    const std::string &result = value ? rule.getValue() : rule.getTag();
    return [NSString stringWithUTF8String:result.c_str()];
}

@end

@implementation OARouteStatisticsHelper

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

+ (NSArray<OASRouteStatistic *> *) calculateRouteStatistic:(vector<SHARED_PTR<RouteSegmentResult> >)route
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

+ (NSArray<OASRouteStatistic *> *) calculateRouteStatistic:(vector<SHARED_PTR<RouteSegmentResult> >)route attributeNames:(NSArray<NSString *> *)attributeNames
{
    const auto& defaultPresentationEnv = OsmAndApp.instance.defaultRenderer;
    OARouteStatisticsComputer *statisticsComputer =
        [[OARouteStatisticsComputer alloc] initWithPresentationEnvironment:defaultPresentationEnv];
    return [self calculateRouteStatistic:route
                          attributeNames:attributeNames
                      statisticsComputer:statisticsComputer];
}

+ (NSArray<OASRouteStatistic *> *) calculateRouteStatistic:(vector<SHARED_PTR<RouteSegmentResult> >)route
                                            attributeNames:(NSArray<NSString *> *)attributeNames
                                        statisticsComputer:(OARouteStatisticsComputer *)statisticsComputer
{
    return [OASRouteStatisticsCalculator.shared
        calculateAccessor:[[OARouteStatisticsAccessor alloc] initWithRoute:route]
        attributeNames:attributeNames
        classifier:(id<OASRouteAttributeClassifier>) statisticsComputer];
}

+ (NSArray<NSString *> *) getRouteStatisticAttrsNames:(BOOL)excludeSteepness
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
    if (excludeSteepness)
        [attributeNames removeObject:ROUTE_INFO_STEEPNESS];
    
    return attributeNames;
}

@end

@interface OARouteStatisticsComputer () <OASRouteAttributeClassifier>

@end

@implementation OARouteStatisticsComputer
{
    OAMapViewController *_mapViewController;
    std::shared_ptr<OsmAnd::MapPresentationEnvironment> _defaultPresentationEnvironment;
    OARouteStatisticsRenderingLookup _currentRendererLookup;
    OARouteStatisticsRenderingLookup _defaultRendererLookup;
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

- (instancetype)initWithCurrentRendererLookup:(OARouteStatisticsRenderingLookup)currentRendererLookup
                        defaultRendererLookup:(OARouteStatisticsRenderingLookup)defaultRendererLookup
{
    self = [super init];
    if (self)
    {
        _currentRendererLookup = [currentRendererLookup copy];
        _defaultRendererLookup = [defaultRendererLookup copy];
    }
    return self;
}

- (OASRouteAttributeClassification * _Nullable)classifyRequest:(OASRouteAttributeClassificationRequest *)request
{
    NSMutableDictionary<NSString *, NSString *> *settings = [NSMutableDictionary new];
    if (request.mainTag && request.mainValue)
    {
        settings[@"tag"] = request.mainTag;
        settings[@"value"] = request.mainValue;
    }
    settings[@"additional"] = request.additional;

    NSDictionary<NSString *, NSNumber *> *renderingAttributes = _currentRendererLookup
        ? _currentRendererLookup(request.attributeName, settings)
        : [_mapViewController getRoadRenderingAttributes:request.attributeName additionalSettings:settings];
    if (OAIsUndefinedRenderingAttribute(renderingAttributes))
    {
        if (_defaultRendererLookup)
        {
            renderingAttributes = _defaultRendererLookup(request.attributeName, settings);
        }
        else if (_defaultPresentationEnvironment)
        {
            const auto &defaultAttribute = _defaultPresentationEnvironment->getRoadRenderingAttributes(
                QString::fromNSString(request.attributeName),
                [OANativeUtilities dictionaryToQHash:settings]);
            uint32_t color = defaultAttribute.second == 0 ? UINT32_MAX : defaultAttribute.second;
            renderingAttributes = @{defaultAttribute.first.toNSString() : @(color)};
        }
    }
    if (OAIsUndefinedRenderingAttribute(renderingAttributes))
        return nil;

    NSString *name = renderingAttributes.allKeys.firstObject;
    return [[OASRouteAttributeClassification alloc]
        initWithPropertyName:name
        color:(int32_t) renderingAttributes[name].intValue];
}

- (OASRouteAttributeClassification *) classifySegment:(NSString *) attribute slopeClass:(int) slopeClass segment:(OARouteSegmentWithIncline *) segment
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
    
    return [[OASRouteAttributeClassification alloc]
        initWithPropertyName:name ?: kUndefinedAttr
        color:(int32_t) color];
}

- (NSDictionary<NSString *, NSString *> *) getRenderingParamsForAttribute:(NSString *) attribute
                                                                  segment:(OARouteSegmentWithIncline *) segment
                                                               slopeClass:(int) slopeClass
{
    SHARED_PTR<RouteDataObject> obj = segment.obj;
    const auto& tps = obj->types;
    if ([attribute isEqualToString:@"routeInfo_steepness"] && slopeClass >= 0)
        return @{ @"additional" : OARouteSlopeBoundaryClasses()[slopeClass] };
    
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
