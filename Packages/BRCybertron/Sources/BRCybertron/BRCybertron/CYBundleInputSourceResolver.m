//
//  CYBundleInputSourceResolver.m
//  BRCybertron
//
//  Created by Matt on 10/03/16.
//  Copyright © 2016 Blue Rocket, Inc. Distributable under the terms of the MIT License.
//

#import "CYBundleInputSourceResolver.h"

#import "CYFileInputSource.h"

@implementation CYBundleInputSourceResolver {
	NSBundle *bundle;
}

- (instancetype)init {
	return [self initWithBundle:nil];
}

- (instancetype)initWithBundle:(nullable NSBundle *)bundleOrNil {
	if ( (self = [super init]) ) {
		bundle = (bundleOrNil ? bundleOrNil : [NSBundle mainBundle]);
	}
	return self;
}

- (nullable id<CYInputSource>)resolveInputSourceFromURI:(NSString *)uri options:(CYParsingOptions)options {
	NSString *path = [[bundle bundlePath] stringByAppendingPathComponent:uri];
	CYFileInputSource *result = nil;
	if ( [[NSFileManager defaultManager] fileExistsAtPath:path] ) {
		result = [[CYFileInputSource alloc] initWithContentsOfFile:path options:options];
	}
	return result;
}

@end
