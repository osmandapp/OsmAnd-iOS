//
//  CYInputSource.h
//  BRCybertron
//
//  Created by Matt on 5/03/16.
//  Copyright © 2016 Blue Rocket, Inc. Distributable under the terms of the MIT License.
//

#import <Foundation/Foundation.h>
#import <libxml/tree.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Parsing options. Any value from xmlParserOption defined in @c libxml/parser.h can be used here,
 in addition to the additional options declared here.
 */
typedef NS_OPTIONS(long, CYParsingOptions) {
	CYParsingDefaultOptions		= 0,
	CYParsingAsHTML             = 1 << 32,
};

/**
 Error codes that occur during parsing XML input sources.
 */
typedef enum : NSInteger {

	/** An internal memory allocation failed. */
	CYParsingErrorAllocationFailed = 100,

	/** The XML failed to parse. */
	CYParsingErrorParsingFailed	   = 101,
	
} CYParsingError;

/**
 API for an XML input source for an XSLT transformation operation.
 */
@protocol CYInputSource <NSObject>

/**
 Get an XML document to serve as input.
 
 @return The XML document, or @c nil if
 */

/**
 Get an XML document to serve as input. The returned pointer is owned by the receiver, and should not be released manually.
 
 @param error If a problem occurs parsing the XML, this will be set to an error. Pass @c nil if you don't need the error.
 
 @return The XML document, or @c nil if unable to parse the XML.
 */
- (nullable xmlDocPtr)getDocument:(NSError **)error NS_RETURNS_INNER_POINTER;

/**
 Get an XML document to serve as input. The returned pointer is @b not owned by the receiver, and @c must be released by
 the consuming code.
 
 @param error If a problem occurs parsing the XML, this will be set to an error. Pass @c nil if you don't need the error.
 
 @return The XML document, or @c nil if unable to parse the XML.
 */
- (nullable xmlDocPtr)newDocument:(NSError **)error;

/**
 Get a string version of the XML input. This may or may not result in parsing the XML in order to then convert the input
 to a string with the desired output characteristics.
 
 @param format YES to format the XML, for example with line breaks and indentation.
 @param error If a problem occurs parsing the XML, this will be set to an error. Pass @c nil if you don't need the error.
 
 @return The XML document formatted as a string.
 */
- (nullable NSString *)asString:(BOOL)format error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
