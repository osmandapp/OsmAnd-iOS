//
//  CYSimpleEntityResolver.m
//  BRCybertron
//
//  Created by Matt on 8/03/16.
//  Copyright © 2016 Blue Rocket, Inc. Distributable under the terms of the MIT License.
//

#import "CYSimpleEntityResolver.h"

#import <libxml/entities.h>
#import <libxml/parser.h>
#import "CYSimpleEntity.h"

static CYSimpleEntityResolver *SharedResolver;

@implementation CYSimpleEntityResolver {
	NSDictionary<NSString *, CYSimpleEntity *> *registeredEntities;
}

+ (void)initialize {
	SharedResolver = [[CYSimpleEntityResolver alloc] init];
}

+ (instancetype)sharedResolver {
	return SharedResolver;
}

- (void)addInternalEntities:(NSDictionary<NSString *, NSString *> *)entities {
	NSMutableDictionary<NSString *, CYSimpleEntity *> *cache = [registeredEntities mutableCopy];
	if ( !cache ) {
		cache = [[NSMutableDictionary alloc] initWithCapacity:entities.count];
	}
	[entities enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
		CYSimpleEntity *ent = [[CYSimpleEntity alloc] initWithName:key content:obj];
		cache[key] = ent;
	}];
	registeredEntities = [cache copy];
}

- (void)setInternalEntities:(NSDictionary<NSString *,NSString *> *)entities {
	registeredEntities = nil;
	[self addInternalEntities:entities];
}

- (id<CYEntity>)resolveEntity:(NSString *)name context:(CYParsingContext *)context {
	return registeredEntities[name];
}

@end
