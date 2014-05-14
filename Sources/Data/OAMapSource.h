//
//  OAMapSource.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 4/24/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OAMapSource : NSObject <NSCopying, NSCoding>

- (instancetype)initWithResource:(NSString*)resourceId;
- (instancetype)initWithResource:(NSString*)resourceId
        andVariant:(NSString*)variant;

// "OnlineTileSources" or "MapStyle" resource
@property(readonly) NSString* resourceId;

// For "OnlineTileSources": name of source
// For "MapStyle": name of preset or nil
@property(readonly) NSString* variant;

@end
