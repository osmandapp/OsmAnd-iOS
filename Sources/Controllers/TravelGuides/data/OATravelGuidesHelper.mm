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
#import "OAWikiArticleHelper.h"

#import "OsmAnd_Maps-Swift.h"

#include <OsmAndCore/Utilities.h>

@implementation OAFoundAmenity

- (instancetype) initWithFile:(NSString *)file amenity:(OAPOIAdapter *)amenity
{
    self = [super init];
    if (self)
    {
        self.file = file;
        self.amenity = amenity;
    }
    return self;
}

@end


@implementation OATravelGuidesHelper


+ (NSArray<OAFoundAmenity *> *) searchAmenity:(double)lat lon:(double)lon reader:(NSString *)reader radius:(int)radius searchFilter:(NSString *)searchFilter publish:(BOOL(^)(OAPOIAdapter *poi))publish
{
    OsmAnd::PointI locI = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(lat, lon));
    NSArray<OAPOI *> *foundPoints = [OAPOIHelper findTravelGuides:searchFilter location:locI radius:radius reader:reader publish:publish];
    
    NSMutableArray<OAFoundAmenity *> *result = [NSMutableArray array];
    for (OAPOI *point in foundPoints)
    {
        OAPOIAdapter *amenity = [[OAPOIAdapter alloc] initWithPOI:point];
        OAFoundAmenity *found = [[OAFoundAmenity alloc] initWithFile:reader amenity: amenity];
        [result addObject:found];
    }
    return result;
}

+ (void) searchAmenity:(NSString *)searchQuerry categoryName:(NSString *)categoryName radius:(int)radius lat:(double)lat lon:(double)lon reader:(NSString *)reader publish:(BOOL(^)(OAPOIAdapter *poi))publish
{
    OsmAnd::PointI locI = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(lat, lon));
    [OAPOIHelper.sharedInstance findTravelGuidessByKeyword:searchQuerry categoryName:nil poiTypeName:nil location:locI radius:0 reader:reader publish:publish];
}


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

+ (NSArray<OATravelSearchResult *> *) search:(NSString *)searchQuery
{
    NSMutableArray<OATravelSearchResult *> *res = [NSMutableArray array];
    NSMutableDictionary<NSString *, NSArray<OAPOIAdapter *> *> *amenityMap = [NSMutableDictionary dictionary];
    NSString *appLang = [OAUtilities currentLang];
    OASearchUICore *searchUICore = [OAQuickSearchHelper.instance getCore];
    OASearchSettings *settings = [searchUICore getSearchSettings];
    OASearchPhrase *phrase = [[searchUICore getPhrase] generateNewPhrase:searchQuery settings:settings];
    OANameStringMatcher *matcher = [phrase getFirstUnknownNameStringMatcher];
    
    //TODO: check this part. Differ from android?
    for (NSString *reader in [self.class getTravelGuidesObfList])
    {
        //[self searchAmenity:searchQuery categoryName:<#(NSString *)#> radius:<#(int)#> lat:<#(double)#> lon:<#(double)#> reader:reader publish:<#^BOOL(OAPOIAdapter *poi)publish#>
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

+ (CLLocation *) getMapCenter
{
    OsmAndAppInstance app = OsmAndApp.instance;
    Point31 mapCenter = app.data.mapLastViewedState.target31;
    OsmAnd::LatLon latLon = OsmAnd::Utilities::convert31ToLatLon(OsmAnd::PointI(mapCenter.x, mapCenter.y));
    return [[CLLocation alloc] initWithLatitude:latLon.latitude longitude:latLon.longitude];
}

+ (NSString *) getPatrialContent:(NSString *)content
{
    return [OAWikiArticleHelper getPartialContent:content];
}

+ (NSString *) normalizeFileUrl:(NSString *)url
{
    return [OAWikiArticleHelper normalizeFileUrl:url];
}

@end
