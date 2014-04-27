//
//  OsmAndApp.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 8/22/13.
//  Copyright (c) 2013 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OsmAndAppProtocol.h"
#if defined(__cplusplus)
#   import "OsmAndAppCppProtocol.h"
#else
    @protocol OsmAndAppCppProtocol;
#endif

@interface OsmAndApp : NSObject

+ (id<OsmAndAppProtocol, OsmAndAppCppProtocol>)instance;

@end
