//
//  CYInputSourceResolver.h
//  BRCybertron
//
//  Created by Matt on 10/03/16.
//  Copyright © 2016 Blue Rocket, Inc. Distributable under the terms of the MIT License.
//

#import <Foundation/Foundation.h>

#import "CYConstants.h"
#import "CYInputSource.h"

NS_ASSUME_NONNULL_BEGIN

/**
 API for an object that can resolve input sources at runtime, for example from XSLT @c xsl:import 
 or @c document() constructs.
 */
@protocol CYInputSourceResolver <NSObject>

/**
 Resolve a URI into an input source.
 
 @param uri     The URI of the resource to resolve.
 @param options The XML parsing options to use.
 
 @return The resolved input source, or @c nil if the resource could not be resolved.
 */
- (nullable id<CYInputSource>)resolveInputSourceFromURI:(NSString *)uri options:(CYParsingOptions)options;

@end

NS_ASSUME_NONNULL_END
