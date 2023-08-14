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

#include <OsmAndCore/Utilities.h>

@implementation OATravelGuidesHelper


+ (NSArray<OAPOIAdapter *> *) searchAmenity:(double)lat lon:(double)lon radius:(int)radius searchFilter:(NSString *)searchFilter
{
    OsmAnd::PointI locI = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(lat, lon));
    NSArray<OAPOI *> *foundPoints = [OAPOIHelper findTravelGuides:searchFilter location:locI radius:radius];
    
    NSMutableArray<OAPOIAdapter *> *result = [NSMutableArray array];
    for (OAPOI *point in foundPoints)
    {
        OAPOIAdapter *poiAdapter = [[OAPOIAdapter alloc] initWithPOI:point];
        [result addObject:poiAdapter];
    }
    return result;
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

@end
