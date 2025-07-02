//
//  OABaseDetailsObject.mm
//  OsmAnd
//
//  Created by Max Kojin on 02/05/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

#import "OABaseDetailsObject.h"
#import "OAMapSelectionResult.h"
#import "OASelectedMapObject.h"
#import "OAPOI.h"
#import "OATransportStop.h"
#import "OARenderedObject.h"
#import "OsmAnd_Maps-Swift.h"

static int MAX_DISTANCE_BETWEEN_AMENITY_AND_LOCAL_STOPS = 30;

typedef NS_ENUM(NSUInteger, EOAObjectCompleteness) {
    EOAObjectCompletenessEmpty,
    EOAObjectCompletenessCombined,
    EOAObjectCompletenessFull,
};


@implementation OABaseDetailsObject
{
    OAPOI *_syntheticAmenity;
    EOAObjectCompleteness _objectCompleteness;
    EOASearchResultResource _searchResultResource;
    NSString *_obfResourceName;
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        _lang = @"en";
        _osmIds = [NSMutableSet new];
        _wikidataIds = [NSMutableSet new];
        _objects = [NSMutableArray new];
        _syntheticAmenity = [[OAPOI alloc] init];
    }
    return self;
}

- (instancetype) initWithLang:(NSString *)lang
{
    self = [self init];
    if (self)
    {
        _lang = lang;
    }
    return self;
}

- (instancetype) initWithObject:(id)object lang:(NSString *)lang
{
    self = [self initWithLang:lang ?: @"en"];
    if (self)
    {
        _lang = lang ?: @"en";
        [self addObject:object];
    }
    return self;
}

- (instancetype) initWithAmenities:(NSArray<OAPOI *> *)amenities lang:(NSString *)lang
{
    self = [self initWithLang:lang ?: @"en"];
    if (self)
    {
        _lang = lang ?: @"en";
        for (OAPOI *amenity in amenities)
        {
            [self addObject:amenity];
        }
        
        _objectCompleteness = EOAObjectCompletenessFull;
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

- (NSMutableArray<id> *) getObjects
{
    return _objects;
}

- (BOOL) isObjectFull
{
    return _objectCompleteness == EOAObjectCompletenessFull || _objectCompleteness == EOAObjectCompletenessCombined;
}

- (BOOL) isObjectEmpty
{
    return _objectCompleteness == EOAObjectCompletenessEmpty;
}


- (BOOL) addObject:(id)object
{
    if (![self isSupportedObjectType:object])
        return NO;
    
    if ([object isKindOfClass:OABaseDetailsObject.class])
    {
        OABaseDetailsObject *detailsObject = object;
        for (id obj in [detailsObject getObjects])
        {
            [self addObject:obj];
        }
    }
    else
    {
        [_objects addObject:object];
        int64_t osmId = [self getOsmId:object];
        NSString *wikidata = [self getWikidata:object];
        
        if (osmId != -1)
            [_osmIds addObject:@(osmId)];
        if (!NSStringIsEmpty(wikidata))
            [_wikidataIds addObject:wikidata];
    }
    [self combineData];
    return YES;
}

- (NSString *) getWikidata:(id)object
{
    if ([object isKindOfClass:OAPOI.class])
    {
        return [((OAPOI *)object) getWikidata];
    }
    else if ([object isKindOfClass:OATransportStop.class])
    {
        OAPOI *amenity = ((OATransportStop *)object).poi;
        return [amenity getWikidata];
    }
    else if ([object isKindOfClass:OARenderedObject.class])
    {
        return ((OARenderedObject *)object).tags[WIKIDATA_TAG];
    }
    return nil;
}

- (int64_t) getOsmId:(id)object
{
    if ([object isKindOfClass:OAPOI.class])
    {
        return [((OAPOI *)object) getOsmId];
    }
    else if ([object isKindOfClass:OAMapObject.class])
    {
        return [ObfConstants getOsmObjectId:(OAMapObject *)object];
    }
    return -1;
}

- (BOOL) overlapsWith:(id)object
{
    int64_t osmId = [self getOsmId:object];
    NSString *wikidata = [self getWikidata:object];
    
    BOOL osmIdEqual = osmId != -1 && [_osmIds containsObject:@(osmId)];
    BOOL wikidataEqual = !NSStringIsEmpty(wikidata) && [_wikidataIds containsObject:wikidata];
    
    if (osmIdEqual || wikidataEqual)
        return YES;
    
    if ([object isKindOfClass:OARenderedObject.class])
    {
        OARenderedObject *renderedObject = object;
        NSArray<OATransportStop *> *stops = [self getTransportStops];
        return [self overlapPublicTransport:@[renderedObject] stops:stops];
    }
    if ([object isKindOfClass:OATransportStop.class])
    {
        OATransportStop *transportStop = object;
        NSArray<OARenderedObject *> *renderedObjects = [self getRenderedObjects];
        return [self overlapPublicTransport:renderedObjects stops:@[transportStop]];
    }
    return NO;
}


- (BOOL) overlapPublicTransport:(NSArray<OARenderedObject *> *)renderedObjects stops:(NSArray<OATransportStop *> *)stops
{
    for (OARenderedObject *renderedObject in renderedObjects)
    {
        if ([self overlapPublicTransportWithRenderedObject:renderedObject stops:stops])
            return YES;
    }
    return NO;
}

- (BOOL) overlapPublicTransportWithRenderedObject:(OARenderedObject *)renderedObject stops:(NSArray<OATransportStop *> *)stops
{
    NSArray<NSString *> *transportTypes = [OAPOIHelper.sharedInstance getPublicTransportTypes];
    if (NSArrayIsEmpty(stops) || NSArrayIsEmpty(transportTypes))
        return NO;
    
    MutableOrderedDictionary<NSString *,NSString *> * tags = renderedObject.tags;
    NSString *name = renderedObject.name;
    
    if (!NSStringIsEmpty(name))
    {
        BOOL namesEqual = NO;
        for (OATransportStop *stop in stops)
        {
            if ([stop.name containsString:name] || [name containsString:stop.name])
            {
                namesEqual = YES;
                break;
            }
        }
        if (!namesEqual)
            return NO;
    }
    
    BOOL isStop = NO;
    for (NSString *key in tags)
    {
        NSString *value = tags[key];
        NSString *keyValueString = [NSString stringWithFormat:@"%@_%@", key, value];
        if ([transportTypes containsObject:value] || [transportTypes containsObject:keyValueString])
        {
            isStop = YES;
            break;
        }
    }
    if (isStop)
    {
        for (OATransportStop *stop in stops)
        {
            double distance = [OAMapUtils getDistance:stop.location second:renderedObject.getLocation.coordinate];
            if (distance < MAX_DISTANCE_BETWEEN_AMENITY_AND_LOCAL_STOPS)
                return YES;
        }
    }

    return NO;
}

- (void) merge:(id)object
{
    if ([object isKindOfClass:OABaseDetailsObject.class])
        [self mergeBaseDetailsObject:((OABaseDetailsObject *)object)];
    if ([object isKindOfClass:OATransportStop.class])
        [self mergeTransportStop:((OATransportStop *)object)];
    if ([object isKindOfClass:OARenderedObject.class])
        [self mergeRenderedObject:((OARenderedObject *)object)];
}

- (void) mergeBaseDetailsObject:(OABaseDetailsObject*)other
{
    [_osmIds addObjectsFromArray:other.osmIds.allObjects];
    [_wikidataIds addObjectsFromArray:other.wikidataIds.allObjects];
    [_objects addObjectsFromArray:other.objects];
}

- (void) mergeTransportStop:(OATransportStop *)transportStop
{
    int64_t osmId = [ObfConstants getOsmObjectId:transportStop.poi];
    [_osmIds addObject:@(osmId)];
    
    OAPOI *amenity = transportStop.poi;
    if (amenity)
    {
        NSString *wikidata = [amenity getWikidata];
        if (wikidata)
            [_wikidataIds addObject:wikidata];
    }
    [_objects addObject:transportStop];
}

- (void) mergeRenderedObject:(OARenderedObject *)renderedObject
{
    int64_t osmId = [ObfConstants getOsmObjectId:renderedObject];
    [_osmIds addObject:@(osmId)];
    
    NSString *wikidata = renderedObject.tags[WIKIDATA_TAG];
    if (wikidata)
        [_wikidataIds addObject:wikidata];
    
    [_objects addObject:renderedObject];
}

- (void) combineData
{
    _syntheticAmenity = [[OAPOI alloc] init];
    [self sortObjects];
    
    NSMutableSet<NSString *> *contentLocales = [NSMutableSet new];
    for (id object in _objects)
    {
        if ([object isKindOfClass:OAPOI.class])
        {
            [self processAmenity:object contentLocales:contentLocales];
        }
        else if ([object isKindOfClass:OATransportStop.class])
        {
            OATransportStop *transportStop = object;
            if (transportStop.poi)
            {
                [self processAmenity:transportStop.poi contentLocales:contentLocales];
            }
            else
            {
                // TODO: refactor OATransportStop to OAMapObject
                // TODO: replace transportStop.poi -> transportStop
                
                [self processId:transportStop.poi];
                [_syntheticAmenity copyNames:transportStop.poi];
                if (![_syntheticAmenity getLocation])
                {
                    _syntheticAmenity.latitude = transportStop.location.latitude;
                    _syntheticAmenity.longitude = transportStop.location.longitude;
                }
            }
        }
        else if ([object isKindOfClass:OARenderedObject.class])
        {
            OARenderedObject *renderedObject = object;
            NSString *type = [ObfConstants getOsmEntityType:renderedObject];
            if (type)
            {
                int64_t osmId = [ObfConstants getOsmObjectId:renderedObject];
                int64_t objectId = [ObfConstants createMapObjectIdFromOsmId:osmId type:type];
                
                if (_syntheticAmenity.obfId == -1 && objectId > 0)
                    _syntheticAmenity.obfId = objectId;
            }
            
            if (!_syntheticAmenity.type)
            {
                [_syntheticAmenity copyAdditionalInfoWithMap:renderedObject.tags  overwrite:NO];
            }
            
            [_syntheticAmenity copyNames:renderedObject];
            if (![_syntheticAmenity getLocation])
            {
                _syntheticAmenity.latitude = renderedObject.latitude;
                _syntheticAmenity.longitude = renderedObject.longitude;
            }
            [self processPolygonCoordinates:renderedObject.x y:renderedObject.y];
        }
    }
    
    if (contentLocales.count > 0)
    {
        [_syntheticAmenity updateContentLocales:contentLocales];
    }
    if (_objectCompleteness != EOAObjectCompletenessFull)
    {
        _objectCompleteness = _syntheticAmenity.type ? EOAObjectCompletenessCombined : EOAObjectCompletenessEmpty;
    }
    if (!_syntheticAmenity.type)
    {
        [_syntheticAmenity setType:[OAPOIHelper.sharedInstance getDefaultOtherCategoryType]];
        [_syntheticAmenity setSubType:@""];
        _objectCompleteness = EOAObjectCompletenessEmpty;
    }
}

- (void) processId:(OAMapObject *)objcet
{
    if (_syntheticAmenity.obfId == -1 && [ObfConstants isOsmUrlAvailable:objcet])
    {
        _syntheticAmenity.obfId = objcet.obfId;
    }
}

- (void) processAmenity:(OAPOI *)amenity contentLocales:(NSMutableSet<NSString *> *)contentLocales
{
    [self processId:amenity];
    
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
    
    [_syntheticAmenity copyNames:amenity];
    [_syntheticAmenity copyAdditionalInfo:amenity overwrite:NO];
    [self processPolygonCoordinates:amenity.x y:amenity.y];
    
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

- (void) processPolygonCoordinates:(NSMutableArray<NSNumber *> *)x y:(NSMutableArray<NSNumber *> *)y
{
    if (NSArrayIsEmpty(_syntheticAmenity.x) && !NSArrayIsEmpty(x))
        [_syntheticAmenity.x addObjectsFromArray:x];
    if (NSArrayIsEmpty(_syntheticAmenity.y) && !NSArrayIsEmpty(y))
        [_syntheticAmenity.y addObjectsFromArray:y];
}

- (void) processPolygonCoordinates:(id)object
{
    if ([object isKindOfClass:OAPOI.class])
    {
        OAPOI *amenity = object;
        [self processPolygonCoordinates:amenity.x y:amenity.y];
    }
    if ([object isKindOfClass:OARenderedObject.class])
    {
        OARenderedObject *renderedObject = object;
        [self processPolygonCoordinates:renderedObject.x y:renderedObject.y];
    }
}

- (void) sortObjects
{
    [self sortObjectsByLang];
    [self sortObjectsByResourceType];
    [self sortObjectsByClass];
}

- (void) sortObjectsByLang
{
    _objects = [_objects sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSString *lang1 = [self.class getLangForTravel:obj1];
        NSString *lang2 = [self.class getLangForTravel:obj2];
        
        BOOL preferred1 = [lang1 isEqualToString:_lang];
        BOOL preferred2 = [lang2 isEqualToString:_lang];
        
        if (preferred1 == preferred2)
            return NSOrderedSame;
        
        return preferred1 ? NSOrderedAscending : NSOrderedDescending;
    }];
}

- (void) sortObjectsByResourceType
{
    _objects = [_objects sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        
        EOASearchResultResource ord1 = [self.class getResourceType:obj1];
        EOASearchResultResource ord2 = [self.class getResourceType:obj2];
        
        if (ord1 != ord2)
            return ord2 > ord1 ? NSOrderedAscending : NSOrderedDescending;
        
        return NSOrderedSame;
    }];
}

- (void) sortObjectsByClass
{
    _objects = [_objects sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
 
        int ord1 = [self.class getClassOrder:obj1];
        int ord2 = [self.class getClassOrder:obj2];
        
        if (ord1 != ord2)
            return ord2 > ord1 ? NSOrderedAscending : NSOrderedDescending;
        
        return NSOrderedSame;
    }];
}

- (BOOL) isSupportedObjectType:(id)object
{
    return [object isKindOfClass:OAPOI.class] ||
        [object isKindOfClass:OATransportStop.class] ||
        [object isKindOfClass:OARenderedObject.class] ||
        [object isKindOfClass:OABaseDetailsObject.class];
}

- (NSArray<OAPOI *> *) getAmenities
{
    NSMutableArray<OAPOI *> *amenities = [NSMutableArray new];
    for (id object in _objects)
    {
        if ([object isKindOfClass:OAPOI.class])
            [amenities addObject:object];
    }
    return amenities;
}

- (NSArray<OATransportStop *> *) getTransportStops
{
    NSMutableArray<OATransportStop *> *stops = [NSMutableArray new];
    for (id object in _objects)
    {
        if ([object isKindOfClass:OATransportStop.class])
            [stops addObject:object];
    }
    return stops;
}

- (NSArray<OARenderedObject *> *) getRenderedObjects
{
    NSMutableArray<OARenderedObject *> *renderedObjects = [NSMutableArray new];
    for (id object in _objects)
    {
        if ([object isKindOfClass:OARenderedObject.class])
            [renderedObjects addObject:object];
    }
    return renderedObjects;
}

+ (EOASearchResultResource) findObfType:(NSString *)obfResourceName amenity:(OAPOI *)amenity
{
    if (obfResourceName && [obfResourceName containsString:@"basemap"])
    {
        return EOASearchResultResourceBasemap;
    }
    if (obfResourceName && ([obfResourceName containsString:@"travel"] || [obfResourceName containsString:@"wikivoyage"]))
    {
        return EOASearchResultResourceTravel;
    }
    if ([amenity.type.category isWiki])
    {
        return EOASearchResultResourceWikipedia;
    }
    return EOASearchResultResourceDetailed;
}

- (void) setObfResourceName:(NSString *)obfName
{
    _obfResourceName = obfName;
}

- (EOASearchResultResource) getResourceType
{
    _searchResultResource = [self.class findObfType:_obfResourceName amenity:_syntheticAmenity];
    return _searchResultResource;
}

+ (EOASearchResultResource) getResourceType:(id)object
{
    if ([object isKindOfClass:OABaseDetailsObject.class])
    {
        OABaseDetailsObject *detailsObject = object;
        return [detailsObject getResourceType];
    }
    if ([object isKindOfClass:OAPOI.class])
    {
        OAPOI *amenity = object;
        return [self findObfType:amenity.regionName amenity:amenity];
    }
    return EOASearchResultResourceDetailed;
}

- (void) setX:(NSMutableArray<NSNumber *> *)x
{
    _syntheticAmenity.x = x;
}

- (void) setY:(NSMutableArray<NSNumber *> *)y
{
    _syntheticAmenity.y = y;
}

- (void) addX:(NSNumber *)x
{
    [_syntheticAmenity.x addObject:x];
}

- (void) addY:(NSNumber *)y
{
    [_syntheticAmenity.y addObject:y];
}

+ (NSString *) getLangForTravel:(id)object
{
    OAPOI *ameninty;
    if ([object isKindOfClass:OAPOI.class])
    {
        ameninty = object;
    }
    if ([object isKindOfClass:OABaseDetailsObject.class])
    {
        ameninty = [((OABaseDetailsObject *)object) getSyntheticAmenity];
    }
    
    if (ameninty && [self getResourceType:object] == EOASearchResultResourceTravel)
    {
        NSString *lang = [ameninty getTagSuffix:[NSString stringWithFormat:@"%@:", LANG_YES]];
        if (lang)
            return lang;
    }
    
    return @"en";
}

+ (int) getClassOrder:(id)object
{
    if ([object isKindOfClass:OABaseDetailsObject.class])
        return 1;
    if ([object isKindOfClass:OAPOI.class])
        return 2;
    if ([object isKindOfClass:OATransportStop.class])
        return 3;
    if ([object isKindOfClass:OARenderedObject.class])
        return 4;
    return 5;
}

@end
