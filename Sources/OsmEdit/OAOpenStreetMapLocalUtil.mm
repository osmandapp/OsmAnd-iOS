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
#import "OARelation.h"
#import "OAOsmEditsDBHelper.h"
#import "OAOpenStreetMapPoint.h"
#import "OsmAndApp.h"

#include <OsmAndCore/Data/Amenity.h>
#include <OsmAndCore/Data/ObfPoiSectionInfo.h>
#include <OsmAndCore/Map/AmenitySymbolsProvider.h>
#include <OsmAndCore/Map/MapObjectsSymbolsProvider.h>
#include <OsmAndCore/ObfDataInterface.h>

@implementation OAOpenStreetMapLocalUtil

- (void)closeChangeSet {
}

- (OAEntity *)commitEntityImpl:(EOAAction)action entity:(OAEntity *)entity entityInfo:(OAEntityInfo *)info comment:(NSString *)comment closeChangeSet:(BOOL)closeChangeSet changedTags:(NSSet<NSString *> *)changedTags {
    OAEntity *newEntity = [entity copy];
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
    
//    for (OnNodeCommittedListener listener : listeners) {
//        listener.onNoteCommitted();
//    }
    return newEntity;
}

- (OAEntityInfo *)getEntityInfo:(long)identifier {
    return nil;
}

- (OAEntity *)loadEntity:(const shared_ptr<const OsmAnd::ObfMapObject>)mapObject {
    std::shared_ptr<const OsmAnd::Amenity> amenity;
    const auto& obfsDataInterface = [OsmAndApp instance].resourcesManager->obfsCollection->obtainDataInterface();
    BOOL amenityFound = obfsDataInterface->findAmenityForObfMapObject(mapObject, &amenity);
    if (!amenityFound)
        return nil;
    
    const auto& objectId = amenity->id;
    if (!(objectId != nil && objectId > 0 && (objectId % 2 == MapObject.AMENITY_ID_RIGHT_SHIFT
                                               || (objectId >> MapObject.NON_AMENITY_ID_RIGHT_SHIFT) < Integer.MAX_VALUE))) {
        return null;
    }
    Amenity amenity = null;
    long entityId;
    boolean isWay = objectId % 2 == MapObject.WAY_MODULO_REMAINDER; // check if mapObject is a way
    if (mapObject instanceof Amenity) {
        amenity = (Amenity) mapObject;
        entityId = mapObject.getId() >> MapObject.AMENITY_ID_RIGHT_SHIFT;
    } else {
        entityId = mapObject.getId() >> MapObject.NON_AMENITY_ID_RIGHT_SHIFT;
    }
    PoiType poiType = null;
    if (amenity != null) {
        poiType = amenity.getType().getPoiTypeByKeyName(amenity.getSubType());
    }
    if (poiType == null && mapObject instanceof Amenity) {
        return null;
    }

    Entity entity;
    LatLon loc = mapObject.getLocation();
    if (loc == null) {
        if (mapObject instanceof NativeLibrary.RenderedObject) {
            loc = ((NativeLibrary.RenderedObject) mapObject).getLabelLatLon();
        } else if (mapObject instanceof Building) {
            loc = ((Building) mapObject).getLatLon2();
        }
    }
    if (loc == null) {
        return null;
    }
    if (isWay) {
        entity = new Way(entityId, null, loc.getLatitude(), loc.getLongitude());
    } else {
        entity = new Node(loc.getLatitude(), loc.getLongitude(), entityId);
    }
    if (poiType != null) {
        entity.putTagNoLC(EditPoiData.POI_TYPE_TAG, poiType.getTranslation());
        if (poiType.getOsmTag2() != null) {
            entity.putTagNoLC(poiType.getOsmTag2(), poiType.getOsmValue2());
        }
    }
    if (!Algorithms.isEmpty(mapObject.getName())) {
        entity.putTagNoLC(OSMTagKey.NAME.getValue(), mapObject.getName());
    }
    if (amenity != null) {
        if (!Algorithms.isEmpty(amenity.getOpeningHours())) {
            entity.putTagNoLC(OSMTagKey.OPENING_HOURS.getValue(), amenity.getOpeningHours());
        }
        for (Map.Entry<String, String> entry : amenity.getAdditionalInfo().entrySet()) {
            AbstractPoiType abstractPoi = MapPoiTypes.getDefault().getAnyPoiAdditionalTypeByKey(entry.getKey());
            if (abstractPoi != null && abstractPoi instanceof PoiType) {
                PoiType p = (PoiType) abstractPoi;
                if (!p.isNotEditableOsm() && !Algorithms.isEmpty(p.getEditOsmTag())) {
                    entity.putTagNoLC(p.getEditOsmTag(), entry.getValue());
                }
            }
        }
    }

    // check whether this is node (because id of node could be the same as relation)
    if (entity instanceof Node && MapUtils.getDistance(entity.getLatLon(), loc) < 50) {
        return entity;
    } else if (entity instanceof Way) {
        return entity;
    }
    return null;
}

@end
