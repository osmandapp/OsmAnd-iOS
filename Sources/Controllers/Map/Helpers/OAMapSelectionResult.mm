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
#import "OAContextMenuProvider.h"
#import "OASelectedMapObject.h"
#import "OsmAnd_Maps-Swift.h"

@implementation OAMapSelectionResult
{
    NSString *_lang;
    CGPoint _point;
    CLLocation *_pointLatLon;
    
    id _poiProvider;
    
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
        
        _poiProvider = mapVc.mapLayers.poiLayer;
        
        _lang = [LocaleHelper getPreferredPlacesLanguage];
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
    if (_allObjects.count == 1)
    {
        [_processedObjects addObjectsFromArray:_allObjects];
        return;
    }
    
    NSMutableArray<OASelectedMapObject *> *other = [NSMutableArray new];
    NSMutableArray<OABaseDetailsObject *> *detailsObjects = [self processObjects:_allObjects other:other];
    
    for (OABaseDetailsObject *object in detailsObjects)
    {
        if ([object getObjects].count > 1)
        {
            OASelectedMapObject *selectedObject = [[OASelectedMapObject alloc] initWithMapObject:object provider:_poiProvider];
            [_processedObjects addObject:selectedObject];
        }
        else
        {
            OASelectedMapObject *selectedObject = [[OASelectedMapObject alloc] initWithMapObject:[object getObjects][0] provider:_poiProvider];
            [_processedObjects addObject:selectedObject];
        }
    }
    [_processedObjects addObjectsFromArray:other];
}

- (NSMutableArray<OABaseDetailsObject *> *) processObjects:(NSMutableArray<OASelectedMapObject *> *)selectedObjects other:(NSMutableArray<OASelectedMapObject *> *)other
{
    NSMutableArray<OABaseDetailsObject *> *detailsObjects = [NSMutableArray new];
    for (OASelectedMapObject *selectedObject in selectedObjects)
    {
        id object = selectedObject.object;
        NSMutableArray<OABaseDetailsObject *> *overlapped = [self collectOverlappedObjects:object detailsObjects:detailsObjects];
        
        OABaseDetailsObject *detailsObject;
        if (overlapped.count == 0)
        {
            detailsObject = [[OABaseDetailsObject alloc] initWithLang:_lang];
        }
        else
        {
            detailsObject = overlapped[0];
            for (int i = 1; i < overlapped.count; i++)
            {
                [detailsObject merge:overlapped[i]];
            }
            [detailsObjects removeObjectsInArray:overlapped];
        }
        
        if ([detailsObject addObject:object])
        {
            [detailsObjects addObject:detailsObject];
        }
        else
        {
            [other addObject:selectedObject];
        }
    }
    return detailsObjects;
}

- (NSMutableArray<OABaseDetailsObject *> *) collectOverlappedObjects:(id)object detailsObjects:(NSMutableArray<OABaseDetailsObject *> *)detailsObjects
{
    NSMutableArray<OABaseDetailsObject *> *overlapped = [NSMutableArray new];
    for (OABaseDetailsObject *detailsObject in detailsObjects)
    {
        if ([detailsObject overlapsWith:object])
            [overlapped addObject:detailsObject];
    }
    return overlapped;
}

- (BOOL) isEmpty
{
    return NSArrayIsEmpty(_allObjects);
}

@end

