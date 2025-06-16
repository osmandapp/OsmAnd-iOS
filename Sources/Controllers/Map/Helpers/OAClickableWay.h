//
//  OAClickableWay.h
//  OsmAnd
//
//  Created by Max Kojin on 07/05/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

@class OASKQuadRect, OASGpxFile, OASelectedGpxPoint;

@interface OAClickableWay : NSObject

- (instancetype)initWithGpxFile:(OASGpxFile * _Nonnull)gpxFile osmId:(uint64_t)osmId name:(NSString * _Nullable)name selectedLatLon:(CLLocation * _Nonnull)selectedLatLon bbox:(OASKQuadRect * _Nonnull)bbox;

- (uint64_t) getOsmId;
- (OASKQuadRect *) getBbox;
- (OASGpxFile *) getGpxFile;
- (OASelectedGpxPoint *) getSelectedGpxPoint;
- (NSString *) getGpxFileName;
- (NSString *) getWayName;
- (NSString *) toString;

@end


NS_ASSUME_NONNULL_END
