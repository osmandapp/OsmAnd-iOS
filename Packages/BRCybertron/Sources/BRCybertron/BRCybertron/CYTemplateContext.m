//
//  CYTemplateContext.m
//  BRCybertron
//
//  Created by Matt on 10/03/16.
//  Copyright © 2016 Blue Rocket, Inc. Distributable under the terms of the MIT License.
//

#import "CYTemplateContext.h"

@implementation CYTemplateContext {
	__weak CYTemplate *xslt;
}

@synthesize xslt;

- (instancetype)init {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
	return [self initWithTemplate:nil];
#pragma clang diagnostic pop
}

- (instancetype)initWithTemplate:(CYTemplate *)theTemplate {
	if ( (self = [super init]) ) {
		xslt = theTemplate;
	}
	return self;
}

@end
