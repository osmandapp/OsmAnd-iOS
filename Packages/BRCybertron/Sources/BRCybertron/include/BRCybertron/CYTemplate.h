//
//  CYTemplate.h
//  BRCybertron
//
//  Created by Matt on 4/03/16.
//  Copyright © 2016 Blue Rocket, Inc. Distributable under the terms of the MIT License.
//

#import <Foundation/Foundation.h>

@protocol CYInputSource;
@protocol CYInputSourceResolver;

NS_ASSUME_NONNULL_BEGIN

/**
 Error codes that occur during executing XSTL.
 */
typedef enum : NSInteger {
	
	/** An internal memory allocation failed. */
	CYTemplateErrorAllocationFailed = 200,
	
	/** A general XSTL execution error. */
	CYTemplateErrorExecutionFailure	= 201,
	
} CYTemplateError;

/**
 A parsed XSLT template object that can be used repeatably to transform XML documents.
 */
@interface CYTemplate : NSObject

/**
 A resolver to use when parsing XSLT to handle constructs like @c xsl:import.
 */
@property (nonatomic, strong) id<CYInputSourceResolver> inputSourceResolver;

/**
 Get a template from an XSTL file using all default options.
 
 @param filePath The path to the file.
 
 @return The initialized instance.
 */
+ (instancetype)templateWithContentsOfFile:(NSString *)filePath;

/**
 Get a template from XSTL data resource.
 
 @param data The XSLT data.
 
 @return The initialized instance.
 */
+ (instancetype)templateWithData:(NSData *)data;

/**
 Initialize from an input source.
 
 @param xsltInputSource The input source for the XSLT document.
 
 @return The initialized instance.
 */
- (instancetype)initWithInputSource:(id<CYInputSource>)xsltInputSource NS_DESIGNATED_INITIALIZER;

/**
 Perform a transformation of an input document and return the result as a string.
 
 @param input      The XML input document.
 @param parameters XSLT input parameters to pass to the stylesheet. Supported values are numbers and strings. Pass @nil if no parameters are needed.
 @param error      If a problem occurs parsing the input XML or executing the XSL, this will be set to an error. Pass @c nil if you don't need the error.

 @return The output of the transformation, as a string.
 */
- (NSString *)transformToString:(id<CYInputSource>)input parameters:(nullable NSDictionary<NSString *, id> *)parameters error:(NSError **)error;

/**
 Perform a transformation of an input document and save the results to a file.
 
 @param input      The XML input document.
 @param parameters XSLT input parameters to pass to the stylesheet. Supported values are numbers and strings. Pass @nil if no parameters are needed.
 @param filePath   The path of the file to write to. Any existing file at this path will be overwritten.
 @param error      If a problem occurs parsing the input XML or executing the XSL, this will be set to an error. Pass @c nil if you don't need the error.
 */
- (void)transform:(id<CYInputSource>)input
	   parameters:(nullable NSDictionary<NSString *, id> *)parameters
		   toFile:(NSString *)filePath
			error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
