//
//  OAGridFormatMappingBridge.h
//  OsmAnd Maps
//
//  Copyright © 2026 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OAGridFormatMappingBridge : NSObject

+ (int32_t)projectionRawForGridFormatRaw:(int32_t)gridFormatRaw;
+ (int32_t)formatRawForGridFormatRaw:(int32_t)gridFormatRaw;
+ (int32_t)decimalFormatRaw;
+ (nullable NSNumber *)projectionRawForEpsgMethodCode:(int32_t)methodCode;
+ (nullable NSNumber *)granularityForProjectionRaw:(int32_t)projectionRaw;
+ (nullable NSNumber *)maxZoomForProjectionRaw:(int32_t)projectionRaw;

@end

NS_ASSUME_NONNULL_END
