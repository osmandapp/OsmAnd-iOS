//
//  CYInputSourceSupport.h
//  BRCybertron
//
//  Created by Matt on 7/03/16.
//  Copyright © 2016 Blue Rocket, Inc. Distributable under the terms of the MIT License.
//

#import "CYInputSource.h"

NS_ASSUME_NONNULL_BEGIN

/**
 A base class for other @c CYInputSource implementations to extend.
 */
@interface CYInputSourceSupport : NSObject <CYInputSource>

/** The options to use during XML parsing. */
@property (nonatomic, readonly) CYParsingOptions options;

/**
 Initialize with options.
 
 @param options The options to use during XML parsing.
 
 @return The initialized instance.
 */
- (instancetype)initWithOptions:(CYParsingOptions)options NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
