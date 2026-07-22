//
//  CYUtilities.m
//  BRCybertron
//
//  Created by Matt on 6/03/16.
//  Copyright © 2016 Blue Rocket, Inc. Distributable under the terms of the MIT License.
//

#import "CYUtilities.h"

#import <libxml/parser.h>
#import <libxml/SAX2.h>
#import "CYConstants.h"
#import "CYSimpleEntityResolver.h"
#import "CYInputSource.h"

static NSString * const kParsingContextThreadKey = @"CYUtilities.ParsingContext";

static void xmlStructuredErrorHandler(void *context, xmlErrorPtr error);
static xmlEntityPtr xmlGetEntity(void *ctx,  const xmlChar *name);

@implementation CYUtilities

+ (void)handlePrasing:(id<CYInputSource>)input
			inContext:(xmlParserCtxtPtr)parserContext
				block:(void (^)(CYParsingContext *context))block
			 finished:(void (^)(NSArray<NSError *> * _Nullable errors))callback {
	CYParsingContext *context = [[CYParsingContext alloc] initWithInputSource:input];
	
	// could provide custom entity resolver via property in CYInputSource, for now set to default
	context.entityResolver = [CYSimpleEntityResolver sharedResolver];
	
	// set up entity hook, unless one already provided
	context.getEntityFn = parserContext->sax->getEntity;
	parserContext->sax->getEntity = &xmlGetEntity;
	
	[NSThread currentThread].threadDictionary[kParsingContextThreadKey] = context;
	xmlSetStructuredErrorFunc(NULL, &xmlStructuredErrorHandler);
	@try {
		if ( block ) {
			block(context);
		}
	}
	@finally {
		CYParsingContext *context = [NSThread currentThread].threadDictionary[kParsingContextThreadKey];
		if ( callback ) {
			callback(context.errors);
		}
		[[NSThread currentThread].threadDictionary removeObjectForKey:kParsingContextThreadKey];
	}
}

@end

static void xmlStructuredErrorHandler(void *context, xmlErrorPtr error) {
	NSMutableDictionary *info = [[NSMutableDictionary alloc] initWithCapacity:8];
	NSString *msg = nil;
	if ( strlen(error->message) > 0 ) {
		msg = [[NSString alloc] initWithCString:error->message encoding:NSUTF8StringEncoding];
	}
	int xmlDomain = error->domain;
	int xmlCode = error->code;
	int line = error->line;
	int col = error->int2;
	if ( strlen(error->message) > 0 ) {
		msg = [[NSString alloc] initWithCString:error->message encoding:NSUTF8StringEncoding];
	}
	if ( msg ) {
		info[NSLocalizedDescriptionKey] = msg;
	}
	if ( line ) {
		info[@"line"] = @(line);
	}
	if ( col ) {
		info[@"column"] = @(col);
	}
	if ( xmlDomain ) {
		info[@"libxmlDomain"] = @(xmlDomain);
	}
	if ( xmlCode ) {
		info[@"libxmlCode"] = @(xmlCode);
	}
	NSError *finalError = [NSError errorWithDomain:CYErrorDomain code:CYParsingErrorParsingFailed userInfo:info];
	CYParsingContext *ctx = [NSThread currentThread].threadDictionary[kParsingContextThreadKey];
	NSArray *errors = ctx.errors;
	if ( errors ) {
		errors = [errors arrayByAddingObject:finalError];
	} else {
		errors = [[NSArray alloc] initWithObjects:finalError, nil];
	}
	ctx.errors = errors;
}

static xmlEntityPtr xmlGetEntity(void *ctx,  const xmlChar *name) {
	xmlEntityPtr result = NULL;

	CYParsingContext *context = [NSThread currentThread].threadDictionary[kParsingContextThreadKey];
	if ( !context ) {
		return NULL;
	}
	
	// try internal first
	if ( context.getEntityFn ) {
		result = context.getEntityFn(ctx, name);
		if ( result ) {
			return result;
		}
	}
	
	NSString *entName = [[NSString alloc] initWithUTF8String:(const char *)name];
	id<CYEntity> entity = [context.entityResolver resolveEntity:entName context:context];
	result = [entity getEntity:nil];
	
	return result;
}
