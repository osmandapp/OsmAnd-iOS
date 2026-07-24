//
//  CYSimpleEntity.m
//  BRCybertron
//
//  Created by Matt on 8/03/16.
//  Copyright © 2016 Blue Rocket, Inc. Distributable under the terms of the MIT License.
//

#import "CYSimpleEntity.h"

#import <libxml/entities.h>

@implementation CYSimpleEntity {
	NSString *name;
	NSString *content;
	NSString *externalID;
	NSString *systemID;
	
	xmlEntityPtr entity;
}

@synthesize name;
@synthesize content;
@synthesize systemID;
@synthesize externalID;

- (instancetype)init {
	return [self initWithName:@"" content:@""];
}

- (instancetype)initWithName:(NSString *)theName content:(NSString *)theContent {
	if ( (self = [super init]) ) {
		name = theName;
		content = theContent;
	}
	return self;
}

- (void)dealloc {
	if ( entity != NULL ) {
		xmlFree(entity);
	}
}

- (nullable xmlEntityPtr)getEntity:(NSError **)error NS_RETURNS_INNER_POINTER {
	if ( entity != NULL ) {
		return entity;
	}
	
	xmlEntityPtr result = NULL;
	@synchronized(self) {
		result = xmlNewEntity(NULL, (const xmlChar *)[name UTF8String],
							  XML_INTERNAL_GENERAL_ENTITY,
							  (const xmlChar *)[externalID UTF8String],
							  (const xmlChar *)[systemID UTF8String],
							  (const xmlChar *)[content UTF8String]);
		if ( result ) {
			if ( entity ) {
				xmlFree(entity);
			}
			entity = result;
		}
	}

	return result;
}

@end
