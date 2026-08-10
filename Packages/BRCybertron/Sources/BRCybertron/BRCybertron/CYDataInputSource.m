//
//  CYDataInputSource.m
//  BRCybertron
//
//  Created by Matt on 5/03/16.
//  Copyright © 2016 Blue Rocket, Inc. Distributable under the terms of the MIT License.
//

#import "CYDataInputSource.h"

#import <libxml/encoding.h>
#import <libxml/parser.h>
#import <libxml/xmlstring.h>
#import <libxml/HTMLparser.h>
#import "CYConstants.h"
#import "CYUtilities.h"

@implementation CYDataInputSource {
	NSData *data;
	xmlDocPtr document;
	NSArray<NSError *> *parseErrors;
}

- (instancetype)initWithOptions:(CYParsingOptions)options {
	self = [self initWithData:[NSData new] options:0];
	return self;
}

- (instancetype)initWithData:(NSData *)theData options:(CYParsingOptions)options {
	if ( (self = [super initWithOptions:options]) ) {
		data = theData;
	}
	return self;
}

- (instancetype)initWithData:(NSData *)theData basePath:(NSString *)theBasePath options:(CYParsingOptions)options {
	self = [self initWithData:theData options:options];
	self.basePath = theBasePath;
	return self;
}

- (void)dealloc {
	if ( document != NULL ) {
		xmlFreeDoc(document);
	}
}

- (nullable xmlDocPtr)getDocument:(NSError * _Nullable __autoreleasing *)error {
	if ( document != NULL ) {
		return document;
	}
	document = [self newDocumentFromData:data options:self.options error:error];
	if ( document ) {
		// free up data
		data = nil;
	}
	return document;
}

- (nullable xmlDocPtr)newDocument:(NSError **)error {
	if ( document ) {
		// already parsed, so just return a copy
		return xmlCopyDoc(document, 1);
	}
	return [self newDocumentFromData:data options:self.options error:error];
}

- (nullable xmlDocPtr)newDocumentFromData:(NSData *)xmlData options:(CYParsingOptions)parsingOptions error:(NSError **)error {
	xmlParserCtxtPtr ctxt;
	__block xmlDocPtr doc;
	const int xmlOptions = (int)parsingOptions;
	const BOOL asHTML = ((parsingOptions & CYParsingAsHTML) == CYParsingAsHTML);
	
	if ( asHTML ) {
		ctxt = htmlNewParserCtxt();
	} else {
		ctxt = xmlNewParserCtxt();
	}
	if ( ctxt == NULL ) {
		if ( error ) {
			*error = [NSError errorWithDomain:CYErrorDomain code:CYParsingErrorAllocationFailed userInfo:nil];
		}
		return NULL;
	}
	
	NSString *basePath = (self.basePath != nil ? self.basePath : @"data.xml");

	[CYUtilities handlePrasing:self inContext:ctxt block:^(CYParsingContext *context) {
		if ( asHTML ) {
			doc = htmlCtxtReadMemory(ctxt, [xmlData bytes], (int)[xmlData length], [basePath UTF8String], NULL, xmlOptions);
		} else {
			doc = xmlCtxtReadMemory(ctxt, [xmlData bytes], (int)[xmlData length], [basePath UTF8String], NULL, xmlOptions);
		}
	} finished:^(NSArray<NSError *> * _Nullable errors) {
		parseErrors = errors;
	}];
	
	xmlFreeParserCtxt(ctxt);
	
	if ( doc == NULL ) {
		if ( parseErrors.count > 0 ) {
			*error = [parseErrors firstObject];
		}
	}
	
	return doc;
}

@end
