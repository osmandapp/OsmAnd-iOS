//
//  OAOpenStreetMapLocalUtil.m
//  OsmAnd
//
//  Created by Paul on 1/26/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAOpenStreetMapLocalUtil.h"
#import "OAEntity.h"
#import "OANode.h"
#import "OAWay.h"
#import "OAOsmEditsDBHelper.h"
#import "OAOpenStreetMapPoint.h"
#import "OsmAndApp.h"
#import "OAPOIType.h"
#import "OAPOI.h"
#import "OAObservable.h"
#import "OAPOIHelper.h"
#import "OAEditPOIData.h"
#import "OATargetPoint.h"
#import "OATransportStop.h"
#import "OAPOILocationType.h"
#import "OsmAnd_Maps-Swift.h"

#include <OsmAndCore/Utilities.h>

#define WAY_MODULO_REMAINDER 1;

@implementation OAOpenStreetMapLocalUtil

- (void)closeChangeSet {
}

- (OAEntity *)commitEntityImpl:(EOAAction)action entity:(OAEntity *)entity entityInfo:(OAEntityInfo *)info comment:(NSString *)comment closeChangeSet:(BOOL)closeChangeSet changedTags:(NSSet<NSString *> *)changedTags {
    OAEntity *newEntity = entity;
    OAOsmEditsDBHelper *osmEditsDb = [OAOsmEditsDBHelper sharedDatabase];
    if ([entity getId] == -1) {
        if ([entity isKindOfClass:[OANode class]])
            newEntity = [[OANode alloc] initWithNode:(OANode *)entity identifier:MIN(-2, ([osmEditsDb getMinID] - 1))];
        else if ([entity isKindOfClass:[OAWay class]]) {
            newEntity = [[OAWay alloc] initWithId:MIN(-2, ([osmEditsDb getMinID] - 1)) latitude:[entity getLatitude] longitude:[entity getLongitude] ids:[((OAWay *) entity) getNodeIds]];
        } else {
            return nil;
        }
    }
    OAOpenStreetMapPoint *p = [[OAOpenStreetMapPoint alloc] init];
    [newEntity setChangedTags:changedTags];
    [p setEntity:newEntity];
    [p setAction:action];
    [p setComment:comment];
    if ([p getAction] == DELETE && [newEntity getId] < 0) //if it is our local poi
        [osmEditsDb deletePOI:p];
    else
        [osmEditsDb addOpenstreetmap:p];
    
    [[OsmAndApp instance].osmEditsChangeObservable notifyEvent];
    return newEntity;
}

- (OAEntityInfo *)getEntityInfo:(long long)identifier
{
    return nil;
}

- (OAEntity *)loadEntity:(OATargetPoint *)targetPoint
{
    BOOL isTransportStop = targetPoint.type == OATargetTransportStop;
    id object = targetPoint.targetObj;
    OAPOI *poi = nil;

    if (isTransportStop)
    {
        poi = ((OATransportStop *)object).poi;
    }
    else if ([object isKindOfClass:[OAPOI class]])
    {
        poi = (OAPOI *)object;
    }
    else if ([object isKindOfClass:[OARenderedObject class]])
    {
        poi = [BaseDetailsObject convertRenderedObjectToAmenity:object];
        poi.latitude = targetPoint.location.latitude;
        poi.longitude = targetPoint.location.longitude;
        if (!poi.name && targetPoint.title.length > 0)
            poi.name = targetPoint.title;
    }
    
    else if ([object isKindOfClass:[BaseDetailsObject class]])
    {
        BaseDetailsObject *baseDetailsObject = object;
        poi = baseDetailsObject.syntheticAmenity;
    }
    if (!poi)
        return nil;
    
    NSString *type = [ObfConstants getOsmEntityType:poi];
    if (!type || type.length == 0 || [type isEqualToString:kEntityTypeRelation])
    {
        return nil;
    }
    
    BOOL isWay = type == kEntityTypeWay;
    uint64_t entityId = [ObfConstants getOsmObjectId:poi];
    
    BOOL isAmenity = poi.type && ![poi.type isKindOfClass:[OAPOILocationType class]];
    OAPOIHelper *poiHelper = [OAPOIHelper sharedInstance];
    OAPOIType *poiType = poi.type;
    
    OAEntity *entity;
    if (isWay)
        entity = [[OAWay alloc] initWithId:entityId latitude:poi.latitude longitude:poi.longitude ids:[NSArray new]];
    else
        entity = [[OANode alloc] initWithId:entityId latitude:poi.latitude longitude:poi.longitude];
    
    if (poiType && isAmenity)
    {
        [entity putTagNoLC:POI_TYPE_TAG value:[poiType.name stringByReplacingOccurrencesOfString:@"_" withString:@" "]];
        if (poiType.getOsmTag2)
            [entity putTagNoLC:poiType.getOsmTag2 value:poiType.getOsmValue2];
        if (poiType.getEditOsmTag2)
            [entity putTagNoLC:poiType.getEditOsmTag2 value:poiType.getEditOsmValue2];
    }
    
    NSString *name = poi.name;
    if (name && [name length] > 0)
    {
        NSString *ref = poi.values[@"ref"];
        NSString *subtype = [poiType getOsmValue];
        if (![name isEqualToString:ref] && ![subtype hasSuffix:@"_ref"])
        {
            [entity putTagNoLC:[OAOSMSettings getOSMKey:NAME] value:poi.name];
        }
    }
    
    if ([poi.openingHours length] > 0)
        [entity putTagNoLC:[OAOSMSettings getOSMKey:OSM_TAG_OPENING_HOURS] value:poi.openingHours];
    
    [poi.values enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL * _Nonnull stop) {
        OAPOIBaseType *pt = [poiHelper getAnyPoiAdditionalTypeByKey:key];
        if (pt && [pt isKindOfClass:OAPOIType.class]) {
            OAPOIType *p = (OAPOIType *) pt;
            if (!p.nonEditableOsm && p.getEditOsmTag.length > 0)
                [entity putTagNoLC:p.getEditOsmTag value:value];
        }
    }];

    // check whether this is node (because id of node could be the same as relation)
    if ([entity isKindOfClass:OANode.class] && OsmAnd::Utilities::distance([entity getLongitude], [entity getLatitude], poi.longitude, poi.latitude) < 50)
        return entity;
    else if ([entity isKindOfClass:OAWay.class])
        return entity;
    
    return nil;
}

@end
