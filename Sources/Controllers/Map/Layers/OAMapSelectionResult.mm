//
//  OAMapSelectionResult.mm
//  OsmAnd
//
//  Created by Max Kojin on 02/05/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

#import "OAMapSelectionResult.h"

@implementation OASelectedMapObject
{
    id _object;
//    id _provider; // ???
}

//- (instancetype) initWithMapObject:(id)object provider:(id)provider
- (instancetype) initWithMapObject:(id)object
{
    self = [super init];
    if (self)
    {
        _object = object;
//        _provider = provider;
    }
    return self;
}

- (id) object
{
    return _object;
}

//- (id) provider
//{
//    return _provider;
//}

@end



@implementation OAMapSelectionResult
{
    CGPoint _point;
    CLLocationCoordinate2D _pointLatLon;
    id _poiProvider; // ???
    
    NSMutableArray<OASelectedMapObject *> *_allObjects;
    NSMutableArray<OASelectedMapObject *> *_processedObjects;
    
//    CLLocationCoordinate2D *objectLatLon;
}

- (instancetype) initWithPoint:(CGPoint)point
{
    self = [super init];
    if (self)
    {
        _point = point;
        _allObjects = [NSMutableArray new];
        _processedObjects = [NSMutableArray new];
        
        /*
        this.tileBox = tileBox;
        this.poiProvider = app.getOsmandMap().getMapLayers().getPoiMapLayer();
        this.pointLatLon = NativeUtilities.getLatLonFromElevatedPixel(app.getOsmandMap().getMapView().getMapRenderer(), tileBox, point);
         */
        
    }
    return self;
}

- (CGPoint) getPoint
{
    return _point;
}

- (CLLocationCoordinate2D) getPointLatLon
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

- (void) groupByOsmIdAndWikidataId
{
    // TODO: implement
}

- (BOOL) isEmpty
{
    return _allObjects.count > 0;
}

@end

