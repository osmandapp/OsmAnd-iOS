//
//  CYParsingContext.m
//  BRCybertron
//
//  Created by Matt on 8/03/16.
//  Copyright © 2016 Blue Rocket, Inc. Distributable under the terms of the MIT License.
//

#import "CYParsingContext.h"

@implementation CYParsingContext {
	__weak id<CYInputSource> inputSource;
}

@synthesize inputSource;

- (instancetype)init {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
	return [self initWithInputSource:nil];
#pragma clang diagnostic pop
}

- (instancetype)initWithInputSource:(id<CYInputSource>)input {
	if ( (self = [super init]) ) {
		inputSource = input;
	}
	return self;
}

@end
