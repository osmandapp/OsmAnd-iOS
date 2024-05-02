//
//  OAHeightsResolverTask.m
//  OsmAnd Maps
//
//  Created by Skalii on 01.05.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#import "OAHeightsResolverTask.h"
#import "OARootViewController.h"
#import "OAMapRendererView.h"
#import "OAGeoTiffCollectionEnvironment.h"

#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/IGeoTiffCollection.h>

@implementation OAHeightsResolverTask
{
    NSArray<CLLocation *> *_points;
    HeightsResolverTaskCallback _callback;
}

- (instancetype)initWithPoints:(NSArray<CLLocation *> *)points
                      callback:(HeightsResolverTaskCallback)callback
{
    self = [super init];
    if (self)
    {
        _points = points;
        _callback = callback;
    }
    return self;
}

- (void)execute
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray<NSNumber *> *heights = [self doInBackground];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self onPostExecute:heights];
        });
    });
}

- (NSArray<NSNumber *> * _Nonnull)doInBackground
{
    OAMapViewController *mapViewController = [OARootViewController instance].mapPanel.mapViewController;
    QList<OsmAnd::PointI> qPoints;
    for (CLLocation *point in _points)
    {
        qPoints.append(OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(point.coordinate.latitude, point.coordinate.longitude)));
    }

    QList<float> qHeights;
    [mapViewController geoTiffCollectionEnvironment].geoTiffCollection->calculateHeights(OsmAnd::ZoomLevel14, mapViewController.mapView.elevationDataTileSize, qPoints, qHeights);
    NSMutableArray<NSNumber *> *heights = [NSMutableArray array];
    for (float qHeight : qHeights)
    {
        [heights addObject:@(qHeight)];
    }
    return heights;
}

- (void)onPostExecute:(NSArray<NSNumber *> * _Nonnull)heights
{
    if (_callback)
        _callback(heights);
}

@end
