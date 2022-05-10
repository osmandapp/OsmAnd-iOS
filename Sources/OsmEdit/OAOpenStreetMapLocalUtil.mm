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
#import "OAPOIHelper.h"
#import "OAEditPOIData.h"
#import "OATargetPoint.h"
#import "OATransportStop.h"
#import "OAPOILocationType.h"

#include <OsmAndCore/Utilities.h>

#define WAY_MODULO_REMAINDER 1;

static const int AMENITY_ID_RIGHT_SHIFT = 1;
static const int NON_AMENITY_ID_RIGHT_SHIFT = 7;

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
    OAPOIHelper *poiHelper = [OAPOIHelper sharedInstance];
    long long objectId = targetPoint.obfId;
    BOOL isTransportStop = targetPoint.type == OATargetTransportStop;
    if (isTransportStop)
        objectId = ((OATransportStop *)targetPoint.targetObj).poi.obfId;
    
    if (!(objectId > 0 && ((objectId % 2 == AMENITY_ID_RIGHT_SHIFT) || (objectId >> NON_AMENITY_ID_RIGHT_SHIFT) < INT_MAX)))
        return nil;
    OAPOI *poi = isTransportStop ? ((OATransportStop *)targetPoint.targetObj).poi : (OAPOI *)targetPoint.targetObj;
    if (!poi)
        return nil;
    OAPOIType *poiType = poi.type;
    BOOL isAmenity = poiType && ![poiType isKindOfClass:[OAPOILocationType class]];
    
    long long entityId = objectId >> (isAmenity ? AMENITY_ID_RIGHT_SHIFT : NON_AMENITY_ID_RIGHT_SHIFT);
    BOOL isWay = objectId % 2 == WAY_MODULO_REMAINDER; // check if mapObject is a way
    
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
    }
    if ([poi.name length] > 0 && ![poi.name isEqualToString:poiType.getOsmValue])
        [entity putTagNoLC:[OAOSMSettings getOSMKey:NAME] value:poi.name];
    
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
