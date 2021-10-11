//
//  OAMapillaryImage.h
//  OsmAnd
//
//  Created by Alexey on 20/05/2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

#include <OsmAndCore.h>
#include <QVariant>
#include <OsmAndCore/MvtReader.h>

#define kCapturedAtKey "captured_at"
#define kCompassAngleKey "compass_angle"
#define kImageIdKey "id"
#define kSequenceIdKey "sequence_id"
#define kOrganizationIdKey "organization_id"
#define kIsPanoramiceKey "is_pano"

@interface OAMapillaryImage : NSObject

// Image location
@property (nonatomic, readonly) double latitude;
@property (nonatomic, readonly) double longitude;
// Camera heading.  -1 if not found.
@property (nonatomic, readonly) double compassAngle; // = -1;
// When the image was captured, expressed as UTC epoch time in milliseconds. Must be non-negative integer;  0 if not found.
@property (nonatomic, readonly) long capturedAt;
@property (nonatomic, readonly) NSString *imageId;
@property (nonatomic, readonly) BOOL panoramicImage;
@property (nonatomic, readonly) NSString* sequenceId;
// Can be absent
@property (nonatomic, readonly) NSString *organizationId;

- (instancetype) initWithLatitude:(double)latitude longitude:(double)longitude;
- (instancetype) initWithDictionary:(NSDictionary *)values;

- (BOOL) setData:(QHash<uint8_t, QVariant>)data geometryTile:(const std::shared_ptr<const OsmAnd::MvtReader::Tile>&)geometryTile;

@end
