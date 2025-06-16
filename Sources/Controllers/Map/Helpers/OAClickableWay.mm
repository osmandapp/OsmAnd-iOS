//
//  OAClickableWay.mm
//  OsmAnd
//
//  Created by Max Kojin on 07/05/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

#import "OAClickableWay.h"
#import "OASelectedGpxPoint.h"
#import "OAUtilities.h"
#import "OsmAnd_Maps-Swift.h"

@implementation OAClickableWay
{
    uint64_t _osmId;
    NSString *_name;
    OASKQuadRect *_bbox;
    OASGpxFile *_gpxfile;
    OASelectedGpxPoint *_selectedGpxPoint; //TODO: implement?
}

- (instancetype)initWithGpxFile:(OASGpxFile *)gpxFile osmId:(uint64_t)osmId name:(NSString *)name selectedLatLon:(CLLocation *)selectedLatLon bbox:(OASKQuadRect *)bbox
{
    self = [super init];
    if (self) {
        _gpxfile = gpxFile;
        _osmId = osmId;
        _name = name;
        _bbox = bbox;
        
        OASWptPt *wpt = [[OASWptPt alloc] init];
        wpt.lat = selectedLatLon.coordinate.latitude;
        wpt.lon = selectedLatLon.coordinate.longitude;
        _selectedGpxPoint = [[OASelectedGpxPoint alloc] initWith:nil selectedPoint:wpt];
    }
    return self;
}

- (uint64_t) getOsmId
{
    return _osmId;
}

- (OASKQuadRect *) getBbox
{
    return _bbox;
}

- (OASGpxFile *) getGpxFile
{
    return _gpxfile;
}

- (OASelectedGpxPoint *) getSelectedGpxPoint
{
    return _selectedGpxPoint;
}

- (NSString *) getGpxFileName
{
    return [[self getWayName] sanitizeFileName];
}

- (NSString *) getWayName
{
    if (!NSStringIsEmpty(_name))
    {
        return _name;
    }
    else
    {
        NSString *altName = [_gpxfile getExtensionsToRead][@"ref"];
        return altName ?: [NSString stringWithFormat:@"%d", _osmId];
    }
}

- (NSString *) toString
{
    return [self getWayName];
}


@end
