//
//  OAPlaceDetailsObject.mm
//  OsmAnd
//
//  Created by Max Kojin on 02/05/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

#import "OAPlaceDetailsObject.h"
#import "OAMapSelectionResult.h"
#import "OASelectedMapObject.h"
#import "OAPOI.h"
#import "OsmAnd_Maps-Swift.h"

@implementation OAPlaceDetailsObject
{
    OAPOI *_syntheticAmenity;
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        _osmIds = [NSMutableSet new];
        _wikidataIds = [NSMutableSet new];
        _selectedObjects = [NSMutableArray new];
        _syntheticAmenity = [[OAPOI alloc] init];
    }
    return self;
}

- (instancetype) initWithObject:(id<OAContextMenuProvider>)object provider:(id<OAContextMenuProvider>)provider
{
    self = [self init];
    if (self)
    {
        [self addObject:object provider:provider];
        [self combineData];
    }
    return self;
}

- (OAPOI *) getSyntheticAmenity
{
    return _syntheticAmenity;
}

- (CLLocation *) getLocation
{
    
    return [_syntheticAmenity getLocation];
}

- (NSMutableArray<OASelectedMapObject *> *) getSelectedObjects
{
    return _selectedObjects;
}

- (void) addObject:(id)object provider:(id<OAContextMenuProvider>)provider
{
    if ([self.class shouldSkip:object])
        return;
    
    OASelectedMapObject *selectedObject = [[OASelectedMapObject alloc] initWithMapObject:object provider:provider];
    [_selectedObjects addObject:selectedObject];
    
    if ([object isKindOfClass:OAMapObject.class])
    {
        OAMapObject *mapObject = (OAMapObject*) object;
        NSInteger osmObfId = [ObfConstants getOsmObjectId:mapObject];
        [_osmIds addObject:@(osmObfId)];
    }
    if ([object isKindOfClass:OAPOI.class])
    {
        OAPOI *amenity = (OAPOI*) object;
        NSString *wikidata = [amenity getWikidata];
        if (![NSString isEmpty:wikidata])
        {
            [_wikidataIds addObject:wikidata];
        }
    }
}

- (BOOL) overlapsWith:(id)object
{
    NSInteger osmObfId = -1;
    if ([object isKindOfClass:OAMapObject.class])
    {
        OAMapObject *mapObject = (OAMapObject*) object;
        osmObfId = [ObfConstants getOsmObjectId:mapObject];
    }
    NSString *wikidata = nil;
    if ([object isKindOfClass:OAPOI.class])
    {
        OAPOI *amenity = (OAPOI*) object;
        wikidata = [amenity getWikidata];
        if (![NSString isEmpty:wikidata])
        {
            [_wikidataIds addObject:wikidata];
        }
    }
    
    return (osmObfId != -1 && [_osmIds containsObject:@(osmObfId)]) ||
        (![NSString isEmpty:wikidata] && [_wikidataIds containsObject:wikidata]);
}

- (void) merge:(OAPlaceDetailsObject*)other
{
    [_osmIds addObjectsFromArray:other.osmIds.allObjects];
    [_wikidataIds addObjectsFromArray:other.wikidataIds.allObjects];
    [_selectedObjects addObjectsFromArray:other.selectedObjects];
}

- (void) combineData
{
    NSMutableSet<NSString *> *contentLocales = [NSMutableSet new];
    for (OASelectedMapObject *selectedObject in _selectedObjects)
    {
        id object = selectedObject.object;
        if ([object isKindOfClass:OAPOI.class])
        {
            OAPOI *amenity = (OAPOI*) object;
            [self processAmenity:amenity contentLocales:contentLocales];
        }
    }
    if (contentLocales.count > 0)
    {
        [_syntheticAmenity updateContentLocales:contentLocales];
    }
}

- (void) processAmenity:(OAPOI *)amenity contentLocales:(NSMutableSet<NSString *> *)contentLocales
{
    if (_syntheticAmenity.obfId != -1 && [ObfConstants isOsmUrlAvailable:amenity])
    {
        [_syntheticAmenity setObfId:amenity.obfId];
    }
    if (_syntheticAmenity.latitude == 0 && _syntheticAmenity.longitude == 0 &&
        amenity.latitude != 0 && amenity.longitude != 0)
    {
        _syntheticAmenity.latitude = amenity.latitude;
        _syntheticAmenity.longitude = amenity.longitude;
    }
    OAPOIType *type = [amenity type];
    if (![_syntheticAmenity type] && type)
    {
        [_syntheticAmenity setType:type];
    }
    NSString *subType = [amenity subType];
    if (![_syntheticAmenity subType] && subType)
    {
        [_syntheticAmenity setSubType:subType];
    }
    NSString *mapIconName = [amenity mapIconName];
    if (![_syntheticAmenity mapIconName] && mapIconName)
    {
        [_syntheticAmenity setMapIconName:mapIconName];
    }
    NSString *regionName = [amenity regionName];
    if (![_syntheticAmenity regionName] && regionName)
    {
        [_syntheticAmenity setRegionName:regionName];
    }
    
    // Android also reads here tagGroups.
    //Map<Integer, List<TagValuePair>> groups = amenity.getTagGroups();
    //if (syntheticAmenity.getTagGroups() == null && groups != null) {
    //    syntheticAmenity.setTagGroups(new HashMap<>(groups));
    //}
    
    int travelElo = [amenity getTravelEloNumber];
    if ([_syntheticAmenity getTravelEloNumber] == DEFAULT_ELO && travelElo != DEFAULT_ELO)
    {
        [_syntheticAmenity setTravelEloNumber:travelElo];
    }
    NSMutableArray<NSNumber *> * x= amenity.x;
    if ([NSArray isEmpty:_syntheticAmenity.x] && ![NSArray isEmpty:x])
    {
        [_syntheticAmenity.x addObjectsFromArray:x];
    }
    NSMutableArray<NSNumber *> * y= amenity.y;
    if ([NSArray isEmpty:_syntheticAmenity.y] && ![NSArray isEmpty:y])
    {
        [_syntheticAmenity.y addObjectsFromArray:y];
    }
    
    [_syntheticAmenity copyNames:amenity];
    [_syntheticAmenity copyAdditionalInfo:amenity overwrite:NO];
    
    if (!_syntheticAmenity.localizedContent)
        _syntheticAmenity.localizedContent = [MutableOrderedDictionary dictionaryWithDictionary:_syntheticAmenity.localizedContent];
    if (amenity.localizedContent.count > 0)
    {
        MutableOrderedDictionary *localizedContent = [MutableOrderedDictionary dictionaryWithDictionary:_syntheticAmenity.localizedContent];
        [localizedContent addEntriesFromDictionary:amenity.localizedContent];
        _syntheticAmenity.localizedContent = localizedContent;
    }
    
    [contentLocales addObjectsFromArray:[amenity getSupportedContentLocales].allObjects];
}

+ (BOOL) shouldSkip:(id) object
{
    return ![object isKindOfClass:OAPOI.class];
}

@end
