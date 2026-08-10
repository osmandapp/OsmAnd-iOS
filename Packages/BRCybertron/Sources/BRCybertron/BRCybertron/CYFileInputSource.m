//
//  CYFileInputSource.m
//  BRCybertron
//
//  Created by Matt on 5/03/16.
//  Copyright © 2016 Blue Rocket, Inc. Distributable under the terms of the MIT License.
//

#import "CYFileInputSource.h"

#import <libxml/encoding.h>
#import <libxml/parser.h>
#import <libxml/xmlstring.h>
#import <libxml/HTMLparser.h>
#import "CYConstants.h"
#import "CYUtilities.h"

@implementation CYFileInputSource {
	NSString *filePath;
	xmlDocPtr document;
	NSArray<NSError *> *parseErrors;
}

- (instancetype)initWithOptions:(CYParsingOptions)options {
	self = [self initWithContentsOfFile:nil options:0];
	return self;
}

- (instancetype)initWithContentsOfFile:(NSString *)theFilePath options:(CYParsingOptions)options {
	if ( (self = [super initWithOptions:options]) ) {
		filePath = theFilePath;
	}
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
	document = [self newDocumentFromFile:filePath options:self.options error:error];
	return document;
}

- (nullable xmlDocPtr)newDocument:(NSError **)error {
	if ( document ) {
		// already parsed, so just return a copy
		return xmlCopyDoc(document, 1);
	}
	return [self newDocumentFromFile:filePath options:self.options error:error];
}

- (nullable xmlDocPtr)newDocumentFromFile:(NSString *)path options:(CYParsingOptions)parsingOptions error:(NSError **)error {
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
	
	[CYUtilities handlePrasing:self inContext:ctxt block:^(CYParsingContext *context) {
		if ( asHTML ) {
			doc = htmlCtxtReadFile(ctxt, [path UTF8String], NULL, xmlOptions);
		} else {
			doc = xmlCtxtReadFile(ctxt, [path UTF8String], NULL, xmlOptions);
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
