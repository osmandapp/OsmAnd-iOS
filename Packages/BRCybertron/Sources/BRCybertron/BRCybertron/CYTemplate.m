//
//  CYTemplate.m
//  BRCybertron
//
//  Created by Matt on 4/03/16.
//  Copyright © 2016 Blue Rocket, Inc. Distributable under the terms of the MIT License.
//

#import "CYTemplate.h"

#import <libxml/parser.h>
#import <libxslt/documents.h>
#import <libxslt/transform.h>
#import <libxslt/xsltInternals.h>
#import <libxslt/xsltutils.h>
#import "CYDataInputSource.h"
#import "CYFileInputSource.h"
#import "CYInputSourceResolver.h"
#import "CYTemplateContext.h"

static xmlDocPtr xsltLoaderFunc(const xmlChar * URI, xmlDictPtr dict, int options, void *ctxt, xsltLoadType type);
static void xsltGenericErrorFunc(void *ctx, const char *msg, ...);
static xsltDocLoaderFunc xsltDocBuiltInLoader;


static NSString * const kTemplateContextThreadKey = @"CYTemplate.Context";

@implementation CYTemplate {
	id<CYInputSource> xsltInputSource;
	xsltStylesheetPtr xslt;
	NSError *parsingError;
}

+ (void)initialize {
	xsltDocBuiltInLoader = xsltDocDefaultLoader;
	xsltSetLoaderFunc(&xsltLoaderFunc);
}

- (instancetype)init {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
	return [self initWithInputSource:nil];
#pragma clang diagnostic pop
}

- (instancetype)initWithInputSource:(id<CYInputSource>)theXsltInputSource {
	if ( (self = [super init]) ) {
		xsltInputSource = theXsltInputSource;
	}
	return self;
}

- (void)dealloc {
	if ( xslt != NULL ) {
		xsltFreeStylesheet(xslt);
	}
}

+ (instancetype)templateWithContentsOfFile:(NSString *)filePath {
	CYFileInputSource *input = [[CYFileInputSource alloc] initWithContentsOfFile:filePath options:CYParsingDefaultOptions];
	return [[self alloc] initWithInputSource:input];
}

+ (instancetype)templateWithData:(NSData *)data {
	CYDataInputSource *input = [[CYDataInputSource alloc] initWithData:data options:CYParsingDefaultOptions];
	return [[self alloc] initWithInputSource:input];
}

- (nullable xsltStylesheetPtr)newStylesheetFromInputSource:(id<CYInputSource>)inputSource error:(NSError **)error {
	xmlDocPtr doc = NULL;
	xsltStylesheetPtr result = NULL;
	
	doc = [inputSource newDocument:error];
	
	if ( doc != NULL ) {
		// NOTE: xsltParseStylesheetDoc takes ownership of the passed in doc, so we do NOT free it here!
		result = xsltParseStylesheetDoc(doc);
		if ( result == NULL ) {
			// TODO: error result
		}
	}
	
	return result;
}

- (xsltStylesheetPtr)xsltStylesheet {
	if ( xslt ) {
		return xslt;
	}
	NSError *error = nil;
	xslt = [self newStylesheetFromInputSource:xsltInputSource error:&error];
	parsingError = error;
	return xslt;
}

/**
 Convert plain number and string objects into a form suitable for passing into libxslt as input parameters.
 Note the returned array of strings must be freed by the called, however the individual strings within the
 array will be freed when the @c xpathParameters values are released (i.e. don't free them manually!).
 
 @param parameters      The parameters to convert.
 @param xpathParameters A mutable array to hold the converted string values.
 
 @return A newly allocated array of strings.
 */
- (const char **)convertParameters:(nullable NSDictionary<NSString *, id> *)parameters toXSLTForm:(nullable NSMutableDictionary<NSString *, NSString *> *)xpathParameters {
	const char **params = NULL;
	if ( parameters.count > 0 ) {
		// construct parameters as array of string keys and values, with NULL terminating element
		params = malloc((parameters.count * 2 + 1) * sizeof(char *));
		__block NSUInteger idx = 0;
		[parameters enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
			params[idx++] = [key UTF8String];
			
			// convert value into XPath, which means escaping strings or turning numbers into strings
			NSString *xpath;
			if ( [obj isKindOfClass:[NSNumber class]] ) {
				xpath = [(NSNumber *)obj descriptionWithLocale:nil];
			} else {
				xpath = [NSString stringWithFormat:@"'%@'", [[obj description] stringByReplacingOccurrencesOfString:@"'" withString:@"&apos;"]];
			}
			if ( xpathParameters ) {
				xpathParameters[key] = xpath;
			}
			params[idx++] = [xpath UTF8String];
		}];
		params[idx] = NULL;
	}
	return params;
}

- (NSString *)transformToString:(id<CYInputSource>)input parameters:(nullable NSDictionary<NSString *, id> *)parameters error:(NSError **)error {
	__block NSString *result = nil;
	
	[self handleExecution:input parameters:parameters finished:^(xmlDocPtr outputDocument, NSArray<NSError *> * _Nullable errors) {
		if ( outputDocument ) {
			xmlChar *output = NULL;
			int outputLength = 0;
			xsltSaveResultToString(&output, &outputLength, outputDocument, [self xsltStylesheet]);
			if ( output != NULL ) {
				result = [NSString stringWithUTF8String:(char *)output];
				xmlFree(output);
			}
		} else if ( error ) {
			*error = [errors firstObject];
		}
	}];

	return result;
}

- (void)transform:(id<CYInputSource>)input
	   parameters:(NSDictionary<NSString *,id> *)parameters
		   toFile:(NSString *)filePath
			error:(NSError * _Nullable __autoreleasing *)error {
	[self handleExecution:input parameters:parameters finished:^(xmlDocPtr outputDocument, NSArray<NSError *> * _Nullable errors) {
		if ( outputDocument ) {
			xsltSaveResultToFilename([filePath UTF8String], outputDocument, [self xsltStylesheet], 0);
		} else if ( error ) {
			*error = [errors firstObject];
		}
	}];
}

- (void)handleExecution:(id<CYInputSource>)input
			 parameters:(NSDictionary<NSString *,id> *)parameters
			   finished:(void (^)(xmlDocPtr outputDocument, NSArray<NSError *> * _Nullable errors))callback {
	NSError *error = nil;
	xmlDocPtr inputDocument = [input getDocument:&error];
	if ( inputDocument == NULL ) {
		callback(NULL, @[error]);
		return;
	}
	
	NSMutableDictionary *xpathParameters = [parameters mutableCopy]; // to keep XPath converted values in memory during transform
	const char **params = [self convertParameters:parameters toXSLTForm:xpathParameters];
	
	CYTemplateContext *context = [[CYTemplateContext alloc] initWithTemplate:self];
	context.inputSourceResolver = self.inputSourceResolver;
	[NSThread currentThread].threadDictionary[kTemplateContextThreadKey] = context;

	xmlDocPtr outputDocument = NULL;
	xsltTransformContextPtr ctxt = NULL;
	xsltStylesheetPtr xform = [self xsltStylesheet];
	if ( xform == NULL ) {
		if ( parsingError ) {
			error = parsingError;
		}
	} else {
		ctxt = xsltNewTransformContext(xform, inputDocument);
		ctxt->error = &xsltGenericErrorFunc;
		// TODO: xsltSetCtxtParseOptions(ctxt, options);
		outputDocument = xsltApplyStylesheetUser(xform, inputDocument, params, NULL, NULL, ctxt);
	}
	
	callback(outputDocument, context.errors);
	
	[[NSThread currentThread].threadDictionary removeObjectForKey:kTemplateContextThreadKey];
	
	if ( params != NULL ) {
		free(params);
	}
	xpathParameters = nil;
	
	if ( outputDocument != NULL ) {
		xmlFreeDoc(outputDocument);
	}
	if ( ctxt != NULL ) {
		xsltFreeTransformContext(ctxt);
	}
}

@end

static xmlDocPtr xsltLoaderFunc(const xmlChar * URI, xmlDictPtr dict, int options, void *ctxt, xsltLoadType type) {
	xmlDocPtr result = NULL;
	
	// try default loader first
	if ( xsltDocBuiltInLoader ) {
		result = xsltDocBuiltInLoader(URI, dict, options, ctxt, type);		
		if ( result != NULL ) {
			return result;
		}
	}
	
	// look for resolver in threat dict
	id<CYInputSourceResolver> resolver = nil;
	id context = [NSThread currentThread].threadDictionary[kTemplateContextThreadKey];
	if ( [context isKindOfClass:[CYTemplateContext class]] ) {
		resolver = ((CYTemplateContext *)context).inputSourceResolver;
	}
	if ( resolver ) {
		NSString *uri = [NSString stringWithUTF8String:(const char *)URI];
		id<CYInputSource> input = [resolver resolveInputSourceFromURI:uri options:(CYParsingOptions)options];
		NSError *error = nil;
		result = [input newDocument:&error];
	}
	
	return result;
}

static void xsltGenericErrorFunc(void *ctxt, const char *msg, ...) {
	id obj = [NSThread currentThread].threadDictionary[kTemplateContextThreadKey];
	CYTemplateContext *ctx = nil;
	if ( [obj isKindOfClass:[CYTemplateContext class]] ) {
		ctx = obj;
	}
	NSString *message = [NSString stringWithUTF8String:msg];
	NSError *error = [NSError errorWithDomain:CYErrorDomain code:CYTemplateErrorExecutionFailure userInfo:@{NSLocalizedDescriptionKey : message}];
	NSArray *errors = ctx.errors;
	if ( errors ) {
		errors = [errors arrayByAddingObject:error];
	} else {
		errors = [[NSArray alloc] initWithObjects:error, nil];
	}
	ctx.errors = errors;
}
