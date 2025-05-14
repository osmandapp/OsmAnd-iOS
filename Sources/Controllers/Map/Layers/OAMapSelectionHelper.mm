//
//  OAMapSelectionHelper.mm
//  OsmAnd
//
//  Created by Max Kojin on 02/05/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

#import "OAMapSelectionHelper.h"
#import "OAMapSelectionResult.h"

@implementation OAMapSelectionHelper

static int AMENITY_SEARCH_RADIUS = 50;
static int AMENITY_SEARCH_RADIUS_FOR_RELATION = 500;
static int TILE_SIZE = 256;

static NSString *TAG_POI_LAT_LON = @"osmand_poi_lat_lon";

- (OAMapSelectionResult *) collectObjectsFromMap:(CGPoint)point showUnknownLocation:(BOOL)showUnknownLocation
{
    OAMapSelectionResult *result = [[OAMapSelectionResult alloc] initWithPoint:point];
    [self collectObjectsFromLayers:result unknownLocation:showUnknownLocation secondaryObjects:NO];
    [self collectObjectsFromMap:result point:point];
    
    [self processTransportStops:[result getAllObjects]];
    if ([result isEmpty])
        [self collectObjectsFromLayers:result unknownLocation:showUnknownLocation secondaryObjects:YES];
    
    [result groupByOsmIdAndWikidataId];
    return result;
}

- (void) collectObjectsFromMap:(OAMapSelectionResult *)result point:(CGPoint)point
{
    [self selectObjectsFromOpenGl:result point:point];
}

- (void) collectObjectsFromLayers
{
    //TODO: implement
}

- (void) selectObjectsFromOpenGl:(OAMapSelectionResult *)result point:(CGPoint)point
{
    //TODO: implement
}



//TODO: implement all another functions



@end

