//
//  OASelectedGpxPoint.mm
//  OsmAnd
//
//  Created by Max Kojin on 02/06/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

#import "OASelectedGpxPoint.h"
#import "OASelectedGpxFile.h"

@implementation OASelectedGpxPoint
{
    OASGpxFile *_selectedGpxFile;
//    OASelectedGpxFile *_selectedGpxFile;
    
    OASWptPt *_selectedPoint;
    OASWptPt *_prevPoint;
    OASWptPt *_nextPoint;
    double _bearing;
    BOOL _showTrackPointMenu;
}

- (instancetype)initWith:(OASGpxFile *)selectedGpxFile selectedPoint:(OASWptPt *)selectedPoint
{
    return [self initWith:selectedGpxFile selectedPoint:selectedPoint prevPoint:nil nextPoint:nil braring:NAN showTrackPointMenu:NO];
}

- (instancetype)initWith:(OASGpxFile *)selectedGpxFile selectedPoint:(OASWptPt *)selectedPoint prevPoint:(OASWptPt *)prevPoint nextPoint:(OASWptPt *)nextPoint braring:(double)bearing  showTrackPointMenu:(BOOL)showTrackPointMenu
{
    self = [super init];
    if (self) {
        _selectedGpxFile = selectedGpxFile;
        _selectedPoint = selectedPoint;
        _prevPoint = prevPoint;
        _nextPoint = nextPoint;
        _bearing = bearing;
        _showTrackPointMenu = showTrackPointMenu;
    }
    return self;
}

//- (instancetype)initWith:(OASelectedGpxFile *)selectedGpxFile selectedPoint:(OASWptPt *)selectedPoint
//{
//    return [self initWith:selectedGpxFile selectedPoint:selectedPoint prevPoint:nil nextPoint:nil braring:NAN showTrackPointMenu:NO];
//}
//
//- (instancetype)initWith:(OASelectedGpxFile *)selectedGpxFile selectedPoint:(OASWptPt *)selectedPoint prevPoint:(OASWptPt *)prevPoint nextPoint:(OASWptPt *)nextPoint braring:(double)bearing  showTrackPointMenu:(BOOL)showTrackPointMenu
//{
//    self = [super init];
//    if (self) {
//        _selectedGpxFile = selectedGpxFile;
//        _selectedPoint = selectedPoint;
//        _prevPoint = prevPoint;
//        _nextPoint = nextPoint;
//        _bearing = bearing;
//        _showTrackPointMenu = showTrackPointMenu;
//    }
//    return self;
//}

//- (OASelectedGpxFile *) getSelectedGpxFile
//{
//    return _selectedGpxFile;
//}
    
- (OASGpxFile *) getSelectedGpxFile
{
    return _selectedGpxFile;
}

- (OASWptPt *) getSelectedPoint
{
    return _selectedPoint;
}

//TODO: implement
    

@end
