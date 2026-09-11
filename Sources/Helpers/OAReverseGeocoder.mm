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

@interface OAReverseGeocoder ()

@property (nonatomic, strong) NSCache<NSString *, NSString *> *addressCache;
@property (nonatomic, strong) NSOperationQueue *lookupQueue;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableArray *> *pendingLookups;

@end

@implementation OAReverseGeocoder

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

        _lookupQueue = [[NSOperationQueue alloc] init];
        _lookupQueue.name = @"net.osmand.reverse-geocoder";
        _lookupQueue.maxConcurrentOperationCount = 5;
        _lookupQueue.qualityOfService = NSQualityOfServiceUserInitiated;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(clearCache)
                                                     name:UIApplicationDidReceiveMemoryWarningNotification
                                                   object:nil];
    }
    return self;
}

- (void)clearCache
{
    [self.addressCache removeAllObjects];
}

- (NSString *)lookupKeyAtLat:(double)lat lon:(double)lon objectId:(uint64_t)objectId
{
    OAAppSettings *settings = [OAAppSettings sharedManager];
    NSString *prefLang = settings.settingPrefMapLanguage.get ?: @"";
    BOOL transliterate = settings.settingMapLanguageTranslit.get;

    if (objectId != 0)
        return [NSString stringWithFormat:@"id:%llu:%@:%d", objectId, prefLang, transliterate];

    return [NSString stringWithFormat:@"ll:%.7f:%.7f:%@:%d", lat, lon, prefLang, transliterate];
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
    NSString *lookupKey = [self lookupKeyAtLat:lat lon:lon objectId:objectId];
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
            NSString *address = [self performLookupAddressAtLat:lat lon:lon objectId:objectId];
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

- (NSString *)performLookupAddressAtLat:(double)lat
                                    lon:(double)lon
                               objectId:(uint64_t)objectId
{
    OAAppSettings *settings = [OAAppSettings sharedManager];
    NSString *prefLang = settings.settingPrefMapLanguage.get ?: @"";
    
    NSString *cacheKey = [self lookupKeyAtLat:lat lon:lon objectId:objectId];
    NSString *cachedAddress = [self cachedAddressForKey:cacheKey];
    if (cachedAddress)
        return cachedAddress;

    OsmAndAppInstance app = [OsmAndApp instance];
    const auto& obfsCollection = app.resourcesManager->obfsCollection;

    const auto geocoder = std::make_shared<OsmAnd::ReverseGeocoder>(
        obfsCollection,
        std::make_shared<OsmAnd::RoadLocator>(obfsCollection));
    
    const auto geoCriteria = std::make_shared<OsmAnd::ReverseGeocoder::Criteria>();
    geoCriteria->position31 = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(lat, lon));
    const auto object = geocoder->performSearch(*geoCriteria);
    
    NSMutableString *geocodingResult = [NSMutableString string];
    if (object)
    {
        QString lang = QString::fromNSString(prefLang);
        bool transliterate = settings.settingMapLanguageTranslit.get;
        
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
    
    NSString *finalAddress = [geocodingResult copy];
    
    [self cacheAddress:finalAddress forKey:cacheKey];
    
    return finalAddress;
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
