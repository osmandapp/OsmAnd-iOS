//
//  OAGpxData.h
//  OsmAnd
//
//  Created by Paul on 22.10.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//
// OsmAnd/src/net/osmand/plus/measurementtool/GpxData.java
// git revision b1d714a62c513b96bdc616ec5531cff8231c6f43

#import <Foundation/Foundation.h>
#import "OACommonTypes.h"

@class OAGPXMutableDocument;

@interface OAGpxData : NSObject

@property (nonatomic, readonly) OAGPXMutableDocument *gpxFile;
@property (nonatomic, readonly) OAGpxBounds rect;

- (instancetype) initWithFile:(OAGPXMutableDocument *)gpxFile;

@end
