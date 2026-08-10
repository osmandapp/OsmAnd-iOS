//
//  CYDataInputSource.h
//  BRCybertron
//
//  Created by Matt on 5/03/16.
//  Copyright © 2016 Blue Rocket, Inc. Distributable under the terms of the MIT License.
//

#import "CYInputSourceSupport.h"

NS_ASSUME_NONNULL_BEGIN

/**
 An input source to read from a @c NSData instance.
 */
@interface CYDataInputSource : CYInputSourceSupport

/** The base path to treat this input source as, to support relative xsl:import and xsl:include constructs. */
@property (nonatomic, strong) NSString *basePath;

/**
 Initialize from a NSData instance.
 
 @param data    The XML resource.
 @param options The parsing options.
 
 @return The initialized instance.
 */
- (instancetype)initWithData:(NSData *)data options:(CYParsingOptions)options NS_DESIGNATED_INITIALIZER;

/**
 Initialize from a NSData instance with a specific base path.
 
 @param data     The XML resource.
 @param basePath The base path to support relative imports.
 @param options  The parsing options.
 
 @return The initialized instance.
 */
- (instancetype)initWithData:(NSData *)data
					basePath:(NSString *)basePath
					 options:(CYParsingOptions)options;

@end

NS_ASSUME_NONNULL_END
