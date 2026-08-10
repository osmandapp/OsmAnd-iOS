//
//  CYBundleInputSourceResolver.h
//  BRCybertron
//
//  Created by Matt on 10/03/16.
//  Copyright © 2016 Blue Rocket, Inc. Distributable under the terms of the MIT License.
//

#import "CYInputSourceResolver.h"

NS_ASSUME_NONNULL_BEGIN

/**
 A simple @c CYInputSourceResolver that can resolve file-based resources relative to a bundle location.
 */
@interface CYBundleInputSourceResolver : NSObject <CYInputSourceResolver>

/**
 Initialize with a bundle.
 
 @param bundleOrNil The bundle from which to resolve resources from, or @c nil to use the main bundle.
 
 @return The initialized instance.
 */
- (instancetype)initWithBundle:(nullable NSBundle *)bundleOrNil NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
