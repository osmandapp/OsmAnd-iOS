//
//  OATravelObfHelperBridge.m
//  OsmAnd Maps
//
//  Created by nnngrach on 08.08.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OATravelObfHelperBridge.h"
#import "OAPOIHelper.h"
#import "OsmAndApp.h"

#include <OsmAndCore/Utilities.h>

@implementation OATravelObfHelperBridge


+ (void) foo:(double)lat lon:(double)lon
{
    OsmAndAppInstance _app = [OsmAndApp instance];
    
    const auto& obfsCollection = _app.resourcesManager->obfsCollection;
    OsmAnd::PointI locI = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(lat, lon));
    NSArray<OAPOI *> *points1 = [OAPOIHelper findTravelGuides:@"route_article" location:locI radius:100000];
    //NSArray<OAPOI *> *points2 = [OAPOIHelper findTravelGuides:@"route_track" location:locI radius:100000];
    int a = 0;
}

@end
