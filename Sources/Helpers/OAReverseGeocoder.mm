//
//  OAGeocoder.m
//  OsmAnd
//
//  Created by Alexey Kulish on 18/01/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAReverseGeocoder.h"
#import "OsmAndApp.h"
#import "OAAppSettings.h"
#import "OAAutoObserverProxy.h"
#import "OASharedSearchObjects.h"
#import "OsmAndSharedWrapper.h"
#import "OsmAnd_Maps-Swift.h"

#include <OsmAndCore/Search/ReverseGeocoder.h>
#include <OsmAndCore/RoadLocator.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/CommonTypes.h>
#include <OsmAndCore/Data/DataCommonTypes.h>
#include <OsmAndCore/Data/ObfMapSectionInfo.h>
#include <OsmAndCore/Data/ObfPoiSectionInfo.h>
#include <OsmAndCore/Data/Building.h>
#include <OsmAndCore/Data/Street.h>
#include <OsmAndCore/Data/StreetGroup.h>
#include <OsmAndCore/Data/Road.h>
#include <OsmAndCore/Search/AddressesByNameSearch.h>
#include <OsmAndCore/FunctorQueryController.h>

#include <atomic>

@interface OAReverseGeocodingRequest : NSObject
@property (nonatomic) double latitude;
@property (nonatomic) double longitude;
@property (nonatomic, copy) NSString *language;
@property (nonatomic) BOOL transliterate;
@property (nonatomic) BOOL useShared;
@property (nonatomic, copy) NSString *cacheKey;
@end

@implementation OAReverseGeocodingRequest
@end

@interface OAReverseGeocoder ()

@property (nonatomic, strong) NSCache<NSString *, NSString *> *addressCache;
@property (nonatomic, strong) NSOperationQueue *lookupQueue;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableArray *> *pendingLookups;

@end

@implementation OAReverseGeocoder
{
    std::atomic<bool> _stopping;
    NSUInteger _cacheGeneration;
    OAAutoObserverProxy *_resourcesObserver;
}

+ (OAReverseGeocoder *)instance
{
    static dispatch_once_t once;
    static OAReverseGeocoder * sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _addressCache = [[NSCache alloc] init];
        _addressCache.countLimit = 100;
        _pendingLookups = [NSMutableDictionary dictionary];
        _stopping = false;

        _lookupQueue = [[NSOperationQueue alloc] init];
        _lookupQueue.name = @"net.osmand.reverse-geocoder";
        _lookupQueue.maxConcurrentOperationCount = 5;
        _lookupQueue.qualityOfService = NSQualityOfServiceUserInitiated;

        _resourcesObserver = [[OAAutoObserverProxy alloc] initWith:self withHandler:@selector(clearCache)
            andObserve:OsmAndApp.instance.localResourcesChangedObservable];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(clearCache)
                                                     name:UIApplicationDidReceiveMemoryWarningNotification
                                                   object:nil];
    }
    return self;
}

- (void)clearCache
{
    @synchronized (self)
    {
        _cacheGeneration++;
        [self.addressCache removeAllObjects];
    }
}

- (OAReverseGeocodingRequest *)requestAtLat:(double)lat lon:(double)lon objectId:(uint64_t)objectId
{
    OAAppSettings *settings = [OAAppSettings sharedManager];
    OAReverseGeocodingRequest *request = [[OAReverseGeocodingRequest alloc] init];
    request.latitude = lat;
    request.longitude = lon;
    request.language = settings.settingPrefMapLanguage.get ?: @"";
    request.transliterate = settings.settingMapLanguageTranslit.get;
    request.useShared = settings.useSharedSearch.get;
    uint64_t sharedGeneration = request.useShared ? OASharedObfResources.shared.currentGeneration : 0;
    NSString *point = objectId != 0 ? [NSString stringWithFormat:@"id:%llu", objectId]
        : [NSString stringWithFormat:@"ll:%.7f:%.7f", lat, lon];
    @synchronized (self)
    {
        request.cacheKey = [NSString stringWithFormat:@"%@:%@:%d:%d:%lu:%llu", point, request.language,
            request.transliterate, request.useShared, (unsigned long)_cacheGeneration, sharedGeneration];
    }
    return request;
}

- (NSString *)cachedAddressForKey:(NSString *)cacheKey
{
    return [self.addressCache objectForKey:cacheKey];
}

- (void)cacheAddress:(NSString *)address forKey:(NSString *)cacheKey
{
    if (address.length > 0)
        [self.addressCache setObject:address forKey:cacheKey];
}

- (void)lookupAddressAtLat:(double)lat
                       lon:(double)lon
                  objectId:(uint64_t)objectId
                completion:(void (^)(NSString *address))completion
{
    OAReverseGeocodingRequest *request = [self requestAtLat:lat lon:lon objectId:objectId];
    NSString *lookupKey = request.cacheKey;
    NSString *cachedAddress = nil;

    BOOL shouldStartLookup = NO;
    @synchronized (self)
    {
        cachedAddress = [self cachedAddressForKey:lookupKey];
        if (!cachedAddress)
        {
            NSMutableArray *pendingCompletions = self.pendingLookups[lookupKey];
            if (pendingCompletions)
            {
                if (completion)
                    [pendingCompletions addObject:[completion copy]];
            }
            else
            {
                pendingCompletions = [NSMutableArray array];
                if (completion)
                    [pendingCompletions addObject:[completion copy]];
                self.pendingLookups[lookupKey] = pendingCompletions;
                shouldStartLookup = YES;
            }
        }
    }

    if (cachedAddress)
    {
        [NSOperationQueue.mainQueue addOperationWithBlock:^{
            if (completion)
                completion(cachedAddress);
        }];
        return;
    }

    if (!shouldStartLookup)
        return;

    [self.lookupQueue addOperationWithBlock:^{
        @autoreleasepool
        {
            NSString *address = [self performLookup:request];
            NSArray *completions;
            @synchronized (self)
            {
                completions = [self.pendingLookups[lookupKey] copy];
                [self.pendingLookups removeObjectForKey:lookupKey];
            }

            [NSOperationQueue.mainQueue addOperationWithBlock:^{
                for (void (^pendingCompletion)(NSString *) in completions)
                    pendingCompletion(address);
            }];
        }
    }];
}

- (void)stop
{
    _stopping = true;
    [_lookupQueue cancelAllOperations];
}

- (NSString *)performLookupAddressAtLat:(double)lat
                                    lon:(double)lon
                               objectId:(uint64_t)objectId
{
    return [self performLookup:[self requestAtLat:lat lon:lon objectId:objectId]];
}

- (NSString *)performLookup:(OAReverseGeocodingRequest *)request
{
    NSString *cacheKey = request.cacheKey;
    NSString *cachedAddress = [self cachedAddressForKey:cacheKey];
    if (cachedAddress)
        return cachedAddress;

    NSString *address = _stopping ? @"" : [self geocodeRequest:request];

    [self cacheAddress:address forKey:cacheKey];

    return address;
}

- (NSString *)geocodeAddressAtLat:(double)lat lon:(double)lon
{
    return [self geocodeRequest:[self requestAtLat:lat lon:lon objectId:0]];
}

- (NSString *)geocodeRequest:(OAReverseGeocodingRequest *)request
{
    if (request.useShared)
        return [self geocodeSharedRequest:request];

    NSString *prefLang = request.language;

    OsmAndAppInstance app = [OsmAndApp instance];
    const auto& obfsCollection = app.resourcesManager->obfsCollection;

    const auto geocoder = std::make_shared<OsmAnd::ReverseGeocoder>(
        obfsCollection,
        std::make_shared<OsmAnd::RoadLocator>(obfsCollection));
    
    const auto geoCriteria = std::make_shared<OsmAnd::ReverseGeocoder::Criteria>();
    geoCriteria->position31 = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(request.latitude, request.longitude));
    const auto queryController = std::make_shared<OsmAnd::FunctorQueryController>(
        [self]
        (const OsmAnd::FunctorQueryController* const) -> bool
        {
            return self->_stopping;
        });
    std::shared_ptr<const OsmAnd::ReverseGeocoder::ResultEntry> object;
    geocoder->performSearch(*geoCriteria,
        [&object]
        (const OsmAnd::ISearch::Criteria& criteria, const OsmAnd::BaseSearch::IResultEntry& resultEntry)
        {
            object = std::make_shared<const OsmAnd::ReverseGeocoder::ResultEntry>(static_cast<const OsmAnd::ReverseGeocoder::ResultEntry&>(resultEntry));
        },
        queryController);

    NSMutableString *geocodingResult = [NSMutableString string];
    if (object)
    {
        QString lang = QString::fromNSString(prefLang);
        bool transliterate = request.transliterate;
        
        if (object->building)
        {
            QString bldName;
            if (!object->buildingInterpolation.isEmpty())
                bldName = object->buildingInterpolation;
            else
                bldName = object->building->getName(lang, transliterate);

            NSString *buildingName = bldName.toNSString();
            NSString *streetName = object->street
                ? object->street->getName(lang, transliterate).toNSString()
                : nil;
            NSString *groupName = object->streetGroup
                ? object->streetGroup->getName(lang, transliterate).toNSString()
                : nil;

            NSMutableArray<NSString *> *addressParts = [NSMutableArray array];

            if (streetName.length > 0 && buildingName.length > 0)
                [addressParts addObject:[NSString stringWithFormat:@"%@ %@", streetName, buildingName]];
            else if (streetName.length > 0)
                [addressParts addObject:streetName];
            else if (buildingName.length > 0)
                [addressParts addObject:buildingName];

            if (groupName.length > 0)
                [addressParts addObject:groupName];

            [geocodingResult appendString:[addressParts componentsJoinedByString:@", "]];
        }
        else if (object->street)
        {
            NSString *streetName = object->street->getName(lang, transliterate).toNSString();
            NSString *groupName = object->streetGroup
            ? object->streetGroup->getName(lang, transliterate).toNSString()
            : nil;
            if (groupName.length > 0)
                [geocodingResult appendFormat:@"%@, %@", streetName, groupName];
            else
                [geocodingResult appendString:streetName];
        }
        else if (object->streetGroup)
        {
            [geocodingResult appendString:object->streetGroup->getName(lang, transliterate).toNSString()];
        }
        else if (object->road && object->road->hasGeocodingAccess())
        {
            QString sname = object->road->getName(lang, transliterate);
            if (!sname.isNull())
                [geocodingResult appendString:sname.toNSString()];
        }
    }

    return [geocodingResult copy];
}

- (NSString *)geocodeSharedRequest:(OAReverseGeocodingRequest *)request
{
    id<OASResultMatcher> cancel = [OASharedBlockResultMatcher matcherWithPublish:^BOOL(id object) {
        return NO;
    } cancelled:^BOOL {
        return self->_stopping;
    }];
    OASGeocodingUtilitiesGeocodingResult *result = [OASharedObfResources.shared.geocodingService
        lookupAddressLat:request.latitude lon:request.longitude
        defaultRoutingConfig:OsmAndApp.instance.sharedDefaultRoutingConfig cancel:cancel];
    return _stopping ? @"" : [self.class formatSharedAddress:result language:request.language transliterate:request.transliterate];
}

+ (NSString *)formatSharedAddress:(OASGeocodingUtilitiesGeocodingResult *)result
                        language:(NSString *)language
                   transliterate:(BOOL)transliterate
{
    if (!result)
        return @"";

    NSMutableArray<NSString *> *parts = [NSMutableArray array];
    NSString *street = [result.street getNameLang:language transliterate:transliterate];
    NSString *city = [result.city getNameLang:language transliterate:transliterate];
    if (result.building)
    {
        NSString *building = result.buildingInterpolation.length > 0 ? result.buildingInterpolation
            : [result.building getNameLang:language transliterate:transliterate];
        NSMutableArray<NSString *> *streetAndBuilding = [NSMutableArray array];
        if (street.length > 0)
            [streetAndBuilding addObject:street];
        if (building.length > 0)
            [streetAndBuilding addObject:building];
        if (streetAndBuilding.count > 0)
            [parts addObject:[streetAndBuilding componentsJoinedByString:@" "]];
        if (city.length > 0)
            [parts addObject:city];
    }
    else if (result.street || result.city)
    {
        if (street.length > 0)
            [parts addObject:street];
        if (city.length > 0)
            [parts addObject:city];
    }
    else if (result.point)
    {
        OASRouteDataObject *road = result.point.getRoad;
        NSString *name = [road getNameLang:language transliterate:transliterate];
        NSString *ref = [road getRefLang:language transliterate:transliterate direction:YES];
        if (name.length > 0)
            [parts addObject:name];
        if (ref.length > 0)
            [parts addObject:ref];
    }
    NSString *address = [parts componentsJoinedByString:@", "];
    if (address.length > 0 && result.getDistance > 100)
        address = [NSString stringWithFormat:@"%@ %@", OALocalizedString(@"shared_string_near"), address];
    return address;
}

- (void) testAddressSearch:(NSString *)query lat:(double)lat lon:(double)lon
{
    NSLog(@"\n--- Start search: %@ ---", query);
    
    OsmAndAppInstance app = [OsmAndApp instance];
    const auto& obfsCollection = app.resourcesManager->obfsCollection;
    
    OsmAnd::AreaI bbox31 = (OsmAnd::AreaI)OsmAnd::Utilities::boundingBox31FromAreaInMeters(10000, OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(lat, lon)));

    const std::shared_ptr<OsmAnd::AddressesByNameSearch::Criteria>& searchCriteria = std::shared_ptr<OsmAnd::AddressesByNameSearch::Criteria>(new OsmAnd::AddressesByNameSearch::Criteria);
    
    searchCriteria->name = QString::fromNSString(query ? query : @"");
    searchCriteria->includeStreets = true;
    //searchCriteria->streetGroupTypesMask = OsmAnd::ObfAddressStreetGroupTypesMask().set(OsmAnd::ObfAddressStreetGroupType::CityOrTown);
    searchCriteria->bbox31 = bbox31;
    searchCriteria->obfInfoAreaFilter = bbox31;
    
    const auto search = std::shared_ptr<const OsmAnd::AddressesByNameSearch>(new OsmAnd::AddressesByNameSearch(obfsCollection));
    const auto result = search->performSearch(*searchCriteria);
    
    OAAppSettings *settings = [OAAppSettings sharedManager];
    QString lang = QString::fromNSString(settings.settingPrefMapLanguage.get ? settings.settingPrefMapLanguage.get : @"");
    bool transliterate = settings.settingMapLanguageTranslit.get;

    for (auto& res : result)
    {
        NSString *name;
        if (res.address->addressType == OsmAnd::AddressType::Street)
        {
            const auto street = std::dynamic_pointer_cast<const OsmAnd::Street>(res.address);
            name = [NSString stringWithFormat:@"%@, %@", street->getName(lang, transliterate).toNSString(), street->streetGroup->getName(lang, transliterate).toNSString()];
        }
        else
        {
            name = res.address->getName(lang, transliterate).toNSString();
        }
        OsmAnd::LatLon pos = OsmAnd::Utilities::convert31ToLatLon(res.address->position31);
        NSLog(@">> %@ (%f km)", name, OsmAnd::Utilities::distance(lon, lat, pos.longitude, pos.latitude) / 1000);
    }
    
    NSLog(@"+++ Finish search +++\n");
}

@end
