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


+ (NSArray<OAPOI *> *) searchAmenity:(double)lat lon:(double)lon radius:(double)radius searchFilter:(NSString *)searchFilter
{
    OsmAnd::PointI locI = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(lat, lon));
    return [OAPOIHelper findTravelGuides:searchFilter location:locI radius:radius];
}


+ (void) foo:(double)lat lon:(double)lon
{
    OsmAndAppInstance _app = [OsmAndApp instance];
    
    //const auto& obfsCollection = _app.resourcesManager->obfsCollection;
    OsmAnd::PointI locI = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(lat, lon));
    NSArray<OAPOI *> *points1 = [OAPOIHelper findTravelGuides:@"route_article" location:locI radius:100000];
    //NSArray<OAPOI *> *points2 = [OAPOIHelper findTravelGuides:@"route_track" location:locI radius:100000];
    int a = 0;
}

+ (OAWptPt *) createWptPt:(OAPOI *)amenity lang:(NSString *)lang
{
    OAWptPt *wptPt = [[OAWptPt alloc] init];
    wptPt.name = amenity.name;
    wptPt.position = CLLocationCoordinate2DMake(amenity.latitude, amenity.longitude);
    wptPt.desc = amenity.desc;
    
    if ([amenity getSite])
        wptPt.links = @[ [amenity getSite] ];
    
    NSString *color = [amenity getColor];
    OAGPXColor *gpxColor = [OAGPXColor getColorFromName:color];
    if (gpxColor)
        [wptPt setColor:gpxColor.color];
    
    if (amenity.iconName)
        [wptPt setIcon:amenity.iconName];

    NSString *category = [amenity getTagSuffix:@"category_"];
    if (category)
        wptPt.category = [OAUtilities capitalizeFirstLetter:category];

    return wptPt;
}

@end
