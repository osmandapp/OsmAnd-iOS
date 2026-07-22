//
//  CYFileInputSource.h
//  BRCybertron
//
//  Created by Matt on 5/03/16.
//  Copyright © 2016 Blue Rocket, Inc. Distributable under the terms of the MIT License.
//

#import "CYInputSourceSupport.h"

/**
 An input source to read from a file.
 */
@interface CYFileInputSource : CYInputSourceSupport

/**
 Initialize from a file.
 
 @param filePath The path to the XML file to initialize from.
 @param options  The parsing options.
 
 @return The initialized instance.
 */
- (instancetype)initWithContentsOfFile:(NSString *)filePath options:(CYParsingOptions)options NS_DESIGNATED_INITIALIZER;

@end
