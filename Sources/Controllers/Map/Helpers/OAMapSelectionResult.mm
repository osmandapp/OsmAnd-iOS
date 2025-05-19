//
//  OAMapSelectionResult.mm
//  OsmAnd
//
//  Created by Max Kojin on 02/05/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

#import "OAMapSelectionResult.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapViewController.h"
#import "OAMapLayers.h"
#import "OAPlaceDetailsObject.h"
#import "OAContextMenuProvider.h"

@implementation OASelectedMapObject
{
    id _object;
    id<OAContextMenuProvider> _provider;
}

- (instancetype) initWithMapObject:(id)object provider:(id<OAContextMenuProvider>)provider
{
    self = [super init];
    if (self)
    {
        _object = object;
        _provider = provider;
    }
    return self;
}

- (id) object
{
    return _object;
}

- (id<OAContextMenuProvider>) provider
{
    return _provider;
}

@end


@implementation OASelectedGpxPoint
{
    
    
    //TODO: implement
    
}
@end



@implementation OAMapSelectionResult
{
    CGPoint _point;
    CLLocation *_pointLatLon;
    
    id _provider;
    
    NSMutableArray<OASelectedMapObject *> *_allObjects;
    NSMutableArray<OASelectedMapObject *> *_processedObjects;
}

- (instancetype) initWithPoint:(CGPoint)point
{
    self = [super init];
    if (self)
    {
        _point = point;
        _allObjects = [NSMutableArray new];
        _processedObjects = [NSMutableArray new];
        
        OAMapViewController *mapVc = OARootViewController.instance.mapPanel.mapViewController;
        CLLocation *loc = [mapVc getLatLonFromElevatedPixel:point.x y:point.y];
        _pointLatLon = loc;
        
        _provider = mapVc.mapLayers.poiLayer;
    }
    return self;
}

- (CGPoint) getPoint
{
    return _point;
}

- (CLLocation *) getPointLatLon
{
    return _pointLatLon;
}

- (NSMutableArray<OASelectedMapObject *> *) getAllObjects
{
    return _allObjects;
}

- (NSMutableArray<OASelectedMapObject *> *) getProcessedObjects
{
    return _processedObjects;
}

- (void) collect:(id)object provider:(id)provider
{
    [_allObjects addObject:[[OASelectedMapObject alloc] initWithMapObject:object provider:provider]];
}

- (void) groupByOsmIdAndWikidataId
{
    NSMutableArray<OAPlaceDetailsObject *> *detailsObjects = [NSMutableArray new];
    for (OASelectedMapObject *selectedObject in _allObjects)
    {
        id object = selectedObject.object;
        if ([OAPlaceDetailsObject shouldSkip:object])
        {
            [_processedObjects addObject:selectedObject];
            continue;
        }
        NSMutableArray<OAPlaceDetailsObject *> *overlapped = [NSMutableArray new];
        for (OAPlaceDetailsObject *detailsObject in detailsObjects)
        {
            if ([detailsObject overlapsWith:object])
                [overlapped addObject:detailsObject];
        }
        OAPlaceDetailsObject *detailsObject;
        if ([overlapped isEmpty])
        {
            detailsObject = [[OAPlaceDetailsObject alloc] init];
        }
        else
        {
            detailsObject = overlapped[0];
            for (int i = 1; i < overlapped.count; i++)
            {
                [detailsObject merge:overlapped[i]];
            }
            
            // TODO: Test this line detailsObjects.removeAll(overlapped);
            [detailsObjects removeObjectsInArray:overlapped];
        }
        [detailsObject addObject:object provider:selectedObject.provider];
        [detailsObjects addObject:detailsObject];
    }
    for (OAPlaceDetailsObject *object in detailsObjects)
    {
        [object combineData];
        OASelectedMapObject *selectedObject = [[OASelectedMapObject alloc] initWithMapObject:object provider:_provider];
        [_processedObjects addObject:selectedObject];
    }
}

- (BOOL) isEmpty
{
    return [_allObjects isEmpty];
}

@end

