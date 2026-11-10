//
//  OASharedSearchModelsTest.mm
//  OsmAnd MapsTests
//
//  The app's models made from the objects of the shared search are the ones made from the C++
//  objects: every amenity, city, street and building of the search fixtures is read through both
//  readers, and the two OAPOI / OACity / OAStreet / OABuilding are compared field by field. Where the
//  readers themselves read a field differently, the number of such objects is held to what it is.
//

#import <XCTest/XCTest.h>
#import <CoreLocation/CoreLocation.h>
#import "OAAmenitySearcher.h"
#import "OAAmenitySearcher+cpp.h"
#import "OAPOI.h"
#import "OAPOIType.h"
#import "OAPOICategory.h"
#import "OACity.h"
#import "OAStreet.h"
#import "OABuilding.h"
#import "OAPOIHelper.h"
#import "OAAppSettings.h"
#import "OAPOIFilter.h"
#import "OATopIndexFilter.h"
#import "OASharedSearchObjects.h"
#import "OsmAndSharedWrapper.h"

#include <OsmAndCore.h>
#include <OsmAndCore/ArchiveReader.h>
#include <OsmAndCore/Data/ObfReader.h>
#include <OsmAndCore/Data/ObfInfo.h>
#include <OsmAndCore/Data/ObfPoiSectionInfo.h>
#include <OsmAndCore/Data/ObfPoiSectionReader.h>
#include <OsmAndCore/Data/ObfAddressSectionInfo.h>
#include <OsmAndCore/Data/ObfAddressSectionReader.h>
#include <OsmAndCore/Data/Amenity.h>
#include <OsmAndCore/Data/StreetGroup.h>
#include <OsmAndCore/Data/Street.h>
#include <OsmAndCore/Data/Building.h>
#include <QFile>

static NSString * const kSearchResourcesPath = @"test-resources/search";
static const int kExamples = 3;

@interface OASharedSearchModelsTest : XCTestCase

@end

@implementation OASharedSearchModelsTest
{
    NSMutableDictionary<NSString *, NSNumber *> *_mismatches;
    NSMutableDictionary<NSString *, NSMutableArray<NSString *> *> *_examples;
    NSInteger _compared;
    NSString *_mapLanguage;
    BOOL _transliterate;
}

- (void)setUp
{
    _mismatches = [NSMutableDictionary dictionary];
    _examples = [NSMutableDictionary dictionary];
    _compared = 0;
    // the localized names of a POI follow these settings, and the known differences were counted with them
    OAAppSettings *settings = OAAppSettings.sharedManager;
    _mapLanguage = [settings.settingPrefMapLanguage get];
    _transliterate = [settings.settingMapLanguageTranslit get];
    [settings.settingPrefMapLanguage set:@"en"];
    [settings.settingMapLanguageTranslit set:NO];
}

- (void)tearDown
{
    OAAppSettings *settings = OAAppSettings.sharedManager;
    [settings.settingPrefMapLanguage set:_mapLanguage];
    [settings.settingMapLanguageTranslit set:_transliterate];
}

- (NSArray<NSString *> *)obfFiles
{
    NSString *directory = [[[NSBundle bundleForClass:self.class] bundlePath] stringByAppendingPathComponent:kSearchResourcesPath];
    NSString *tempDir = [NSTemporaryDirectory() stringByAppendingPathComponent:@"shared-search-models"];
    [NSFileManager.defaultManager createDirectoryAtPath:tempDir withIntermediateDirectories:YES attributes:nil error:nil];
    NSMutableArray<NSString *> *files = [NSMutableArray array];
    for (NSString *name in [[NSFileManager.defaultManager contentsOfDirectoryAtPath:directory error:nil] sortedArrayUsingSelector:@selector(compare:)])
    {
        if (![name hasSuffix:@".obf.gz"])
            continue;
        NSString *gz = [directory stringByAppendingPathComponent:name];
        NSString *obf = [tempDir stringByAppendingPathComponent:[name stringByReplacingOccurrencesOfString:@".gz" withString:@""]];
        NSDate *extracted = [NSFileManager.defaultManager attributesOfItemAtPath:obf error:nil].fileModificationDate;
        NSDate *packed = [NSFileManager.defaultManager attributesOfItemAtPath:gz error:nil].fileModificationDate;
        if (!extracted || [extracted compare:packed] == NSOrderedAscending)
        {
            OsmAnd::ArchiveReader archive(QString::fromNSString(gz));
            bool ok = false;
            const auto items = archive.getItems(&ok, true);
            if (!ok || items.isEmpty() || !archive.extractItemToFile(items.first().name, QString::fromNSString(obf), true))
            {
                XCTFail(@"cannot extract %@", name);
                continue;
            }
        }
        [files addObject:obf];
    }
    return files;
}

- (void)field:(NSString *)field of:(NSString *)what cpp:(id)cpp shared:(id)shared
{
    if (cpp == shared || [cpp isEqual:shared])
        return;
    _mismatches[field] = @(_mismatches[field].integerValue + 1);
    NSMutableArray<NSString *> *examples = _examples[field] ?: (_examples[field] = [NSMutableArray array]);
    if (examples.count < kExamples)
        [examples addObject:[NSString stringWithFormat:@"%@: C++ %@ | shared %@", what, cpp, shared]];
}

// What the two readers are known to read differently, with how often on the fixtures. The shared one
// reads as android does; a field that differs more often, or one not listed, fails.
static NSDictionary<NSString *, NSDictionary<NSString *, NSNumber *> *> *knownDifferences()
{
    return @{
        @"amenities": @{
            // name:short and the like are names to the shared reader, values to the C++ one
            @"localizedNames": @185, @"values": @194, @"enName": @2,
            // a long name the C++ reader decodes as U+FFFD (apple.obf)
            @"only in C++": @1, @"only in shared": @1,
        },
        @"addresses": @{
            // the shared transliteration drops the accents of Latin letters: Saint-Léonard, Saint-Leonard
            @"name en transliterated": @63226,
            // alt_name and old_name, and names of other languages of a house
            @"localizedNames": @14, @"other names": @14,
            // the C++ reader leaves the postcodes block out
            @"city count": @10, @"city only in shared": @72,
            // houses: a different position by a metre or two, interpolations and postcodes read differently
            @"latitude": @22324, @"longitude": @8, @"building count": @46, @"building only in shared": @106,
            @"building postcode": @61,
            // ids of streets the readers make up differently; the app looks cities up by id, not streets
            @"street id": @532,
        },
    };
}

- (void)reportFor:(NSString *)models
{
    NSLog(@"[shared-models] %@: %ld compared", models, (long) _compared);
    XCTAssertGreaterThan(_compared, 0, @"no %@ compared", models);
    NSDictionary<NSString *, NSNumber *> *known = knownDifferences()[models];
    for (NSString *field in [_mismatches.allKeys sortedArrayUsingSelector:@selector(compare:)])
    {
        NSString *examples = [_examples[field] componentsJoinedByString:@"\n  "];
        NSLog(@"[shared-models] %@ %@: %@ of %ld differ (known %@)\n  %@", models, field, _mismatches[field], (long) _compared, known[field] ?: @0, examples);
        if (_mismatches[field].integerValue > known[field].integerValue)
            XCTFail(@"%@ %@: %@ of %ld differ, %@ known, e.g.\n  %@", models, field, _mismatches[field], (long) _compared, known[field] ?: @0, examples);
    }
}

// The one of the same name nearest to [address]: streets and houses carry ids that differ between the readers.
static OAAddress *nearestOfName(NSDictionary<NSString *, NSArray<OAAddress *> *> *byName, NSString *name, OAAddress *address)
{
    OAAddress *nearest = nil;
    double best = DBL_MAX;
    for (OAAddress *candidate in byName[name ?: @""])
    {
        double d = fabs(candidate.latitude - address.latitude) + fabs(candidate.longitude - address.longitude);
        if (d < best)
        {
            best = d;
            nearest = candidate;
        }
    }
    return nearest;
}

static NSDictionary<NSString *, NSArray<OAAddress *> *> *byName(NSArray<OAAddress *> *addresses)
{
    NSMutableDictionary<NSString *, NSMutableArray<OAAddress *> *> *result = [NSMutableDictionary dictionary];
    for (OAAddress *address in addresses)
    {
        NSString *name = address.name ?: @"";
        NSMutableArray<OAAddress *> *list = result[name] ?: (result[name] = [NSMutableArray array]);
        [list addObject:address];
    }
    return result;
}

static NSString *placeKey(double lat, double lon, NSString *subType, NSString *name)
{
    return [NSString stringWithFormat:@"%.5f %.5f %@ %@", lat, lon, subType ?: @"", name ?: @""];
}

- (void)testAmenitiesAreTheSameThroughBothReaders
{
    NSInteger onlyCpp = 0, onlyShared = 0;
    for (NSString *path in [self obfFiles])
    {
        std::shared_ptr<QFile> file(new QFile(QString::fromNSString(path)));
        file->open(QIODevice::ReadOnly);
        const auto reader = std::make_shared<OsmAnd::ObfReader>(file);
        QList<std::shared_ptr<const OsmAnd::Amenity>> amenities;
        for (const auto& section : reader->obtainInfo()->poiSections)
            OsmAnd::ObfPoiSectionReader::loadAmenities(reader, section, &amenities);

        NSMutableDictionary<NSString *, OAPOI *> *cppPois = [NSMutableDictionary dictionary];
        for (const auto& amenity : amenities)
        {
            OAPOI *poi = [OAAmenitySearcher parsePOIByAmenity:amenity];
            if (poi)
                cppPois[placeKey(poi.latitude, poi.longitude, poi.subType, poi.name)] = poi;
        }

        OASBinaryMapIndexReader *sharedReader = [[OASBinaryMapIndexReader alloc] initWithFilePath:path];
        OASSearchRequest<OASAmenity *> *request = [OASSearchRequest.companion buildSearchPoiRequestSleft:0 sright:INT32_MAX stop:0 sbottom:INT32_MAX zoom:-1 poiTypeFilter:nil poiTopIndexAdditionalFilter:nil matcher:nil];
        NSMutableDictionary<NSString *, OAPOI *> *sharedPois = [NSMutableDictionary dictionary];
        for (OASAmenity *amenity in [sharedReader searchPoiReq:request])
        {
            OAPOI *poi = [OAAmenitySearcher parsePOIBySharedAmenity:amenity];
            if (poi)
                sharedPois[placeKey(poi.latitude, poi.longitude, poi.subType, poi.name)] = poi;
        }
        [sharedReader close];

        for (NSString *key in cppPois)
        {
            OAPOI *cpp = cppPois[key];
            OAPOI *shared = sharedPois[key];
            if (!shared)
            {
                onlyCpp++;
                [self field:@"only in C++" of:path.lastPathComponent cpp:key shared:nil];
                continue;
            }
            _compared++;
            NSString *what = [NSString stringWithFormat:@"%@ %@", path.lastPathComponent, key];
            [self field:@"obfId" of:what cpp:@(cpp.obfId) shared:@(shared.obfId)];
            [self field:@"nameLocalized" of:what cpp:cpp.nameLocalized shared:shared.nameLocalized];
            [self field:@"enName" of:what cpp:cpp.enName shared:shared.enName];
            // the C++ amenity joins the parts in the order of a QHash, which changes from one process to the next
            [self field:@"cityName" of:what cpp:[NSSet setWithArray:[cpp.cityName componentsSeparatedByString:@", "]]
                                      shared:[NSSet setWithArray:[shared.cityName componentsSeparatedByString:@", "]]];
            [self field:@"regionName" of:what cpp:cpp.regionName shared:shared.regionName];
            [self field:@"type" of:what cpp:cpp.type.name shared:shared.type.name];
            [self field:@"category" of:what cpp:cpp.type.category.name shared:shared.type.category.name];
            [self field:@"values" of:what cpp:cpp.values shared:shared.values];
            [self field:@"localizedContent" of:what cpp:cpp.localizedContent shared:shared.localizedContent];
            [self field:@"localizedNames" of:what cpp:cpp.localizedNames shared:shared.localizedNames];
        }
        for (NSString *key in sharedPois)
        {
            if (!cppPois[key])
            {
                onlyShared++;
                [self field:@"only in shared" of:path.lastPathComponent cpp:nil shared:key];
            }
        }
    }
    NSLog(@"[shared-models] amenities only in C++ %ld, only in shared %ld", (long) onlyCpp, (long) onlyShared);
    [self reportFor:@"amenities"];
}

- (void)compareAddress:(OAAddress *)cpp with:(OAAddress *)shared what:(NSString *)what
{
    _compared++;
    [self field:@"name" of:what cpp:cpp.name shared:shared.name];
    [self field:@"localizedNames" of:what cpp:cpp.localizedNames shared:shared.localizedNames];
    [self field:@"name en" of:what cpp:[cpp getName:@"en" transliterate:NO] shared:[shared getName:@"en" transliterate:NO]];
    [self field:@"name en transliterated" of:what cpp:[cpp getName:@"en" transliterate:YES] shared:[shared getName:@"en" transliterate:YES]];
    [self field:@"other names" of:what cpp:[NSSet setWithArray:[cpp getOtherNames:NO]] shared:[NSSet setWithArray:[shared getOtherNames:NO]]];
    [self field:@"latitude" of:what cpp:@(round(cpp.latitude * 1e6)) shared:@(round(shared.latitude * 1e6))];
    [self field:@"longitude" of:what cpp:@(round(cpp.longitude * 1e6)) shared:@(round(shared.longitude * 1e6))];
}

- (void)testAddressesAreTheSameThroughBothReaders
{
    // a settlement can be in more than one block (its boundary shares its id), so each block is read on its own
    NSArray<NSArray *> *blocks = @[@[OASCityBlocks.cityTownType, @((int) OsmAnd::ObfAddressStreetGroupType::CityOrTown)],
                                   @[OASCityBlocks.villagesType, @((int) OsmAnd::ObfAddressStreetGroupType::Village)],
                                   @[OASCityBlocks.postcodesType, @((int) OsmAnd::ObfAddressStreetGroupType::Postcode)],
                                   @[OASCityBlocks.boundaryType, @((int) OsmAnd::ObfAddressStreetGroupType::Boundary)]];
    for (NSString *path in [self obfFiles])
    {
        std::shared_ptr<QFile> file(new QFile(QString::fromNSString(path)));
        file->open(QIODevice::ReadOnly);
        const auto reader = std::make_shared<OsmAnd::ObfReader>(file);
        OASBinaryMapIndexReader *sharedReader = [[OASBinaryMapIndexReader alloc] initWithFilePath:path];
        for (NSArray *block in blocks)
        {
            [self compareBlock:block[0] cppType:(OsmAnd::ObfAddressStreetGroupType) [block[1] intValue]
                        reader:reader sharedReader:sharedReader file:path.lastPathComponent];
        }
        [sharedReader close];
    }
    [self reportFor:@"addresses"];
}

- (void)compareBlock:(OASCityBlocks *)sharedType
             cppType:(OsmAnd::ObfAddressStreetGroupType)cppType
              reader:(const std::shared_ptr<const OsmAnd::ObfReader> &)reader
        sharedReader:(OASBinaryMapIndexReader *)sharedReader
                file:(NSString *)fileName
{
    QList<std::shared_ptr<const OsmAnd::StreetGroup>> groups;
    const auto mask = OsmAnd::ObfAddressStreetGroupTypesMask().set(cppType);
    for (const auto& section : reader->obtainInfo()->addressSections)
        OsmAnd::ObfAddressSectionReader::loadStreetGroups(reader, section, &groups, nullptr, mask);
    NSMutableDictionary<NSNumber *, OACity *> *cppCities = [NSMutableDictionary dictionary];
    for (const auto& group : groups)
    {
        OACity *city = [[OACity alloc] initWithCity:group];
        cppCities[@(city.addrId)] = city;
    }
    NSString *blockWhat = [NSString stringWithFormat:@"%@ %@", fileName, sharedType.name];
    NSArray<OASCity *> *sharedCities = [sharedReader getCitiesResultMatcher:nil type:sharedType];
    if (groups.size() != sharedCities.count)
        [self field:@"city count" of:blockWhat cpp:@(groups.size()) shared:@(sharedCities.count)];

    for (OASCity *sharedCity in sharedCities)
    {
        OACity *city = [[OACity alloc] initWithSharedCity:sharedCity];
        OACity *cppCity = cppCities[@(city.addrId)];
        if (!cppCity)
        {
            [self field:@"city only in shared" of:blockWhat cpp:nil shared:city.name];
            continue;
        }
        NSString *what = [NSString stringWithFormat:@"%@ city %@", blockWhat, cppCity.name];
        [self compareAddress:cppCity with:city what:what];
        [self field:@"city type" of:what cpp:@(cppCity.type) shared:@(city.type)];
        [self field:@"city address type" of:what cpp:@(ADDRESS_TYPE_CITY) shared:@(city.addressType)];

        QList<std::shared_ptr<const OsmAnd::Street>> streets;
        OsmAnd::ObfAddressSectionReader::loadStreetsFromGroup(reader, cppCity.city, &streets);
        NSMutableArray<OAStreet *> *cppStreets = [NSMutableArray array];
        for (const auto& street : streets)
            [cppStreets addObject:[[OAStreet alloc] initWithStreet:street]];
        NSDictionary<NSString *, NSArray<OAAddress *> *> *cppStreetsByName = byName(cppStreets);
        [sharedReader preloadStreetsC:sharedCity resultMatcher:nil];
        if (cppStreets.count != [sharedCity getStreets].count)
            [self field:@"street count" of:what cpp:@(cppStreets.count) shared:@([sharedCity getStreets].count)];

        for (OASStreet *sharedStreet in [sharedCity getStreets])
        {
            OAStreet *street = [[OAStreet alloc] initWithSharedStreet:sharedStreet];
            // the C++ name leaves out the part of the city the shared one appends in brackets
            OAStreet *cppStreet = (OAStreet *) nearestOfName(cppStreetsByName, street.name, street);
            if (!cppStreet)
                cppStreet = (OAStreet *) nearestOfName(cppStreetsByName, [sharedStreet getNameWithoutCityPartLang:nil transliterate:NO], street);
            if (!cppStreet)
            {
                [self field:@"street only in shared" of:what cpp:nil shared:street.name];
                continue;
            }
            NSString *streetWhat = [NSString stringWithFormat:@"%@ street %@", what, cppStreet.name];
            [self compareAddress:cppStreet with:street what:streetWhat];
            [self field:@"street id" of:streetWhat cpp:@(cppStreet.addrId) shared:@(street.addrId)];
            [self field:@"street city" of:streetWhat cpp:@(cppStreet.city.addrId) shared:@(street.city.addrId)];

            QList<std::shared_ptr<const OsmAnd::Building>> buildings;
            OsmAnd::ObfAddressSectionReader::loadBuildingsFromStreet(reader, cppStreet.street, &buildings);
            NSMutableArray<OABuilding *> *cppBuildings = [NSMutableArray array];
            for (const auto& building : buildings)
                [cppBuildings addObject:[[OABuilding alloc] initWithBuilding:building]];
            NSDictionary<NSString *, NSArray<OAAddress *> *> *cppBuildingsByName = byName(cppBuildings);
            [sharedReader preloadBuildingsS:sharedStreet resultMatcher:nil];
            if (cppBuildings.count != [sharedStreet getBuildings].count)
                [self field:@"building count" of:streetWhat cpp:@(cppBuildings.count) shared:@([sharedStreet getBuildings].count)];

            for (OASBuilding *sharedBuilding in [sharedStreet getBuildings])
            {
                OABuilding *building = [[OABuilding alloc] initWithSharedBuilding:sharedBuilding];
                OABuilding *cppBuilding = (OABuilding *) nearestOfName(cppBuildingsByName, building.name, building);
                if (!cppBuilding)
                {
                    [self field:@"building only in shared" of:streetWhat cpp:nil shared:building.name];
                    continue;
                }
                NSString *buildingWhat = [NSString stringWithFormat:@"%@ building %@", streetWhat, building.name];
                [self compareAddress:cppBuilding with:building what:buildingWhat];
                // a house of the obf seldom has an id: the shared one is then 0 and the C++ one made up
                if (building.addrId != 0)
                    [self field:@"building id" of:buildingWhat cpp:@(cppBuilding.addrId) shared:@(building.addrId)];
                [self field:@"building postcode" of:buildingWhat cpp:cppBuilding.postcode shared:building.postcode];
            }
        }
    }
}

- (void)testTheObjectsOfASharedResultBecomeTheAppsOwn
{
    OASCity *sharedCity = [[OASCity alloc] initWithType:OASCityType.town];
    [sharedCity setNameName:@"Testtown"];
    [sharedCity setIdId:[OASLong numberWithLongLong:42]];
    [sharedCity setLocationLatitude:52.5 longitude:13.4];
    OACity *city = [OASharedSearchObjects appObjectFor:sharedCity];
    XCTAssertTrue([city isKindOfClass:OACity.class]);
    XCTAssertEqualObjects(city.name, @"Testtown");
    XCTAssertEqual(city.type, CITY_TYPE_TOWN);
    XCTAssertEqual(city.addrId, 42ULL);
    XCTAssertEqualWithAccuracy(city.latitude, 52.5, 1e-9);

    OASStreet *sharedStreet = [[OASStreet alloc] initWithCity:sharedCity];
    [sharedStreet setNameName:@"Hauptstraße"];
    OAStreet *street = [OASharedSearchObjects appObjectFor:sharedStreet];
    XCTAssertTrue([street isKindOfClass:OAStreet.class]);
    XCTAssertEqualObjects(street.name, @"Hauptstraße");
    XCTAssertEqualObjects(street.city.name, @"Testtown");

    OASBuilding *sharedBuilding = [[OASBuilding alloc] init];
    [sharedBuilding setNameName:@"12a"];
    [sharedBuilding setPostcodePostcode:@"10115"];
    OABuilding *building = [OASharedSearchObjects appObjectFor:sharedBuilding];
    XCTAssertTrue([building isKindOfClass:OABuilding.class]);
    XCTAssertEqualObjects(building.name, @"12a");
    XCTAssertEqualObjects(building.postcode, @"10115");
    XCTAssertEqual(building.addressType, ADDRESS_TYPE_BUILDING);

    OASMapPoiTypes *types = OAPOIHelper.sharedInstance.kPoiTypes;
    OASPoiType *cafe = [types getPoiTypeByKeyName:@"cafe"];
    OASAmenity *amenity = [[OASAmenity alloc] init];
    [amenity setTypeType:[cafe getCategory]];
    [amenity setSubTypeSubType:@"cafe"];
    [amenity setNameName:@"Café am Markt"];
    [amenity setLocationLatitude:52.5 longitude:13.4];
    OAPOI *poi = [OASharedSearchObjects appObjectFor:amenity];
    XCTAssertTrue([poi isKindOfClass:OAPOI.class]);
    XCTAssertEqualObjects(poi.name, @"Café am Markt");
    XCTAssertEqualObjects(poi.type.name, @"cafe");

    OASPoiCategory *shop = [types getPoiCategoryByNameName:@"shop"];
    OAPOIBaseType *category = [OASharedSearchObjects appObjectFor:shop];
    XCTAssertTrue([category isKindOfClass:OAPOICategory.class]);
    XCTAssertEqualObjects(category.name, @"shop");
    OASPoiFilter *sharedFilter = [shop getPoiFilters].firstObject;
    XCTAssertNotNil(sharedFilter, @"shop has filters");
    OAPOIBaseType *filter = [OASharedSearchObjects appObjectFor:sharedFilter];
    XCTAssertTrue([filter isKindOfClass:OAPOIFilter.class]);
    XCTAssertEqualObjects(filter.name, [sharedFilter getKeyName]);
    OAPOIBaseType *type = [OASharedSearchObjects appObjectFor:cafe];
    XCTAssertTrue([type isKindOfClass:OAPOIType.class]);
    XCTAssertEqualObjects(type.name, @"cafe");
    OASAbstractPoiType *sharedAdditional = [types getAnyPoiAdditionalTypeByKeyName:@"cuisine_pizza"];
    XCTAssertNotNil(sharedAdditional, @"pizza is a cuisine");
    OAPOIBaseType *additional = [OASharedSearchObjects appObjectFor:sharedAdditional];
    XCTAssertEqualObjects(additional.name, @"cuisine_pizza");

    OASPoiSubType *brand = [[OASPoiSubType alloc] init];
    brand.name = @"top_index_brand";
    OATopIndexFilter *topIndex = [OASharedSearchObjects appObjectFor:[[OASTopIndexFilter alloc] initWithPoiSubType:brand types:types value:@"Rewe"]];
    XCTAssertTrue([topIndex isKindOfClass:OATopIndexFilter.class]);
    XCTAssertEqualObjects(topIndex.poiSubType, @"top_index_brand");
    XCTAssertEqualObjects(topIndex.value, @"Rewe");

    CLLocation *location = [OASharedSearchObjects appObjectFor:[[OASKLatLon alloc] initWithLatitude:52.5 longitude:13.4]];
    XCTAssertTrue([location isKindOfClass:CLLocation.class]);
    XCTAssertEqualWithAccuracy(location.coordinate.longitude, 13.4, 1e-9);

    XCTAssertEqualObjects([OASharedSearchObjects appObjectFor:@"as it is"], @"as it is");
    XCTAssertNil([OASharedSearchObjects appObjectFor:nil]);
}

@end
