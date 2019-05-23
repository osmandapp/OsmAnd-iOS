//
//  OAMapillaryImage.h
//  OsmAnd
//
//  Created by Alexey on 20/05/2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

#include <OsmAndCore.h>

@interface OAMapillaryImage : NSObject

// Image location
@property (nonatomic, readonly) double latitude;
@property (nonatomic, readonly) double longitude;
// Camera heading.  -1 if not found.
@property (nonatomic, readonly) double ca; // = -1;
// When the image was captured, expressed as UTC epoch time in milliseconds. Must be non-negative integer;  0 if not found.
@property (nonatomic, readonly) long capturedAt;
// Image key.
@property (nonatomic, readonly) NSString *key;
// Whether the image is panorama ( 1 ), or not ( 0 ).
@property (nonatomic, readonly) BOOL pano;
// Sequence key.
@property (nonatomic, readonly) NSString* sKey;
// User key. Empty if not found.
@property (nonatomic, readonly) NSString *userKey;

- (instancetype) initWithLatitude:(double)latitude longitude:(double)longitude;
- (instancetype) initWithDictionary:(NSDictionary *)values;

- (BOOL) setData:(QHash<QString, QString>) data;

@end
