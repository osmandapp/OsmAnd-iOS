//
//  OATravelGuidesHelper.m
//  OsmAnd Maps
//
//  Created by nnngrach on 08.08.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OATravelGuidesHelper.h"
#import "OAGPXDocumentPrimitives.h"
#import "OAPOIHelper.h"
#import "OsmAndApp.h"
#import "OAPOI.h"
#import "OAUtilities.h"
#import "OAQuickSearchHelper.h"
#import "OASearchUICore.h"
#import "OASearchSettings.h"
#import "OASearchPhrase.h"
#import "OANameStringMatcher.h"
#import "OAResourcesUIHelper.h"

#import "OsmAnd_Maps-Swift.h"

#include <OsmAndCore/Utilities.h>

@implementation OATravelGuidesHelper


+ (NSArray<OAPOIAdapter *> *) searchAmenity:(double)lat lon:(double)lon reader:(NSString *)reader radius:(int)radius searchFilter:(NSString *)searchFilter
{
    OsmAnd::PointI locI = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(lat, lon));
    NSArray<OAPOI *> *foundPoints = [OAPOIHelper findTravelGuides:searchFilter location:locI radius:radius reader:reader];
    
    NSMutableArray<OAPOIAdapter *> *result = [NSMutableArray array];
    for (OAPOI *point in foundPoints)
    {
        OAPOIAdapter *poiAdapter = [[OAPOIAdapter alloc] initWithPOI:point];
        [result addObject:poiAdapter];
    }
    return result;
}

+ (NSArray<OAPOIAdapter *> *) searchAmenity:(NSString *)searchQuerry reader:(NSString *)reader
{
    [OAPOIHelper.sharedInstance findTravelGuidessByKeyword:searchQuerry categoryName:nil poiTypeName:nil reader:reader];
    
    //TODO: add result filling callback
    
    return [NSArray array];
}


//+ (void) foo:(double)lat lon:(double)lon
//{
//    OsmAndAppInstance _app = [OsmAndApp instance];
//
//    //const auto& obfsCollection = _app.resourcesManager->obfsCollection;
//    OsmAnd::PointI locI = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(lat, lon));
//    NSArray<OAPOI *> *points1 = [OAPOIHelper findTravelGuides:@"route_article" location:locI radius:100000];
//    //NSArray<OAPOI *> *points2 = [OAPOIHelper findTravelGuides:@"route_track" location:locI radius:100000];
//    int a = 0;
//}

+ (OAWptPtAdapter *) createWptPt:(OAPOIAdapter *)amenity lang:(NSString *)lang
{
    OAPOI *poi;
    if (amenity && [amenity.object isKindOfClass:OAPOI.class])
        poi = (OAPOI *) amenity.object;
        
    OAWptPt *wptPt = [[OAWptPt alloc] init];
    wptPt.name = poi.name;
    wptPt.position = CLLocationCoordinate2DMake(poi.latitude, poi.longitude);
    wptPt.desc = poi.desc;
    
    if ([poi getSite])
        wptPt.links = @[ [poi getSite] ];
    
    NSString *color = [poi getColor];
    OAGPXColor *gpxColor = [OAGPXColor getColorFromName:color];
    if (gpxColor)
        [wptPt setColor:gpxColor.color];
    
    if (poi.iconName)
        [wptPt setIcon:poi.iconName];

    NSString *category = [poi getTagSuffix:@"category_"];
    if (category)
        wptPt.category = [OAUtilities capitalizeFirstLetter:category];
    
    OAWptPtAdapter *wptAdapter = [[OAWptPtAdapter alloc] initWithWpt:wptPt];
    return wptAdapter;
}

+ (NSArray<OAWikivoyageSearchResult *> *) search:(NSString *)searchQuery
{
    NSMutableArray<OAWikivoyageSearchResult *> *res = [NSMutableArray array];
    NSMutableDictionary<NSString *, NSArray<OAPOIAdapter *> *> *amenityMap = [NSMutableDictionary dictionary];
    NSString *appLang = [OAUtilities currentLang];
    OASearchUICore *searchUICore = [OAQuickSearchHelper.instance getCore];
    OASearchSettings *settings = [searchUICore getSearchSettings];
    OASearchPhrase *phrase = [[searchUICore getPhrase] generateNewPhrase:searchQuery settings:settings];
    OANameStringMatcher *matcher = [phrase getFirstUnknownNameStringMatcher];
    
    //TODO: check this part. Differ from android?
    for (NSString *reader in [self.class getObfList])
    {
        [self searchAmenity:searchQuery reader:reader];
    }

    return [NSArray array];
}

+ (NSArray<NSString *> *) getTravelGuidesObfList
{
    OsmAndAppInstance app = OsmAndApp.instance;
    NSMutableArray<NSString *> *obfFilenames = [NSMutableArray array];
    for (const auto& resource : app.resourcesManager->getLocalResources())
    {
        if (resource->type == OsmAnd::ResourcesManager::ResourceType::Travel)
        {
            [obfFilenames addObject:resource->id.toNSString()];
        }
    }
    return obfFilenames;
}

@end
