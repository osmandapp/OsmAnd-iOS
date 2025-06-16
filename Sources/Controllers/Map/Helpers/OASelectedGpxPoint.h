//
//  OASelectedGpxPoint.h
//  OsmAnd
//
//  Created by Max Kojin on 02/06/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN


@class OASGpxFile, OASWptPt, OASelectedGpxFile;

@interface OASelectedGpxPoint: NSObject

- (instancetype)initWith:(OASGpxFile *)selectedGpxFile selectedPoint:(OASWptPt *)selectedPoint;

//- (instancetype)initWith:(OASelectedGpxFile *)selectedGpxFile selectedPoint:(OASWptPt *)selectedPoint;
//- (instancetype)initWith:(OASelectedGpxFile *)selectedGpxFile selectedPoint:(OASWptPt *)selectedPoint prevPoint:(OASWptPt *)prevPoint nextPoint:(OASWptPt *)nextPoint braring:(double)bearing  showTrackPointMenu:(BOOL)showTrackPointMenu;

- (OASGpxFile *)getSelectedGpxFile;
//- (OASelectedGpxFile *)getSelectedGpxFile;
- (OASWptPt *)getSelectedPoint;

@end


NS_ASSUME_NONNULL_END
