//
//  CYInputSourceSupport.m
//  BRCybertron
//
//  Created by Matt on 7/03/16.
//  Copyright © 2016 Blue Rocket, Inc. Distributable under the terms of the MIT License.
//

#import "CYInputSourceSupport.h"

#import <libxml/tree.h>

@implementation CYInputSourceSupport {
	CYParsingOptions options;
}

@synthesize options;

- (instancetype)init {
	self = [self initWithOptions:CYParsingDefaultOptions];
	return self;
}

- (instancetype)initWithOptions:(CYParsingOptions)theOptions {
	if ( (self = [super init]) ) {
		options = theOptions;
	}
	return self;
}

- (nullable xmlDocPtr)getDocument:(NSError **)error {
	NSAssert(NO, @"Must be implemented by extending class.");
	return NULL;
}

- (nullable xmlDocPtr)newDocument:(NSError **)error {
	NSAssert(NO, @"Must be implemented by extending class.");
	return NULL;
}

- (nullable NSString *)asString:(BOOL)format error:(NSError **)error {
	// we are taking the easiest (coding) route here if loading the xmlDoc, followed by dumping that as a string
	xmlDocPtr xmlDoc = [self getDocument:error];
	if ( xmlDoc == NULL ) {
		return nil;
	}
	
	NSString *result = nil;
	xmlChar *output;
	int outputLength;
	xmlDocDumpFormatMemoryEnc(xmlDoc, &output, &outputLength, "UTF-8", (format ? 1 : 0));
	if ( outputLength > 0 ) {
		result = [NSString stringWithUTF8String:(char *)output];
	}
	xmlFree(output);
	return result;
}

@end
