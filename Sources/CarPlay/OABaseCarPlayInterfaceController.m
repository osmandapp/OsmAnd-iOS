//
//  OABaseCarPlayInterfaceController.m
//  OsmAnd Maps
//
//  Created by Paul on 12.02.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OABaseCarPlayInterfaceController.h"
#import <CarPlay/CarPlay.h>

@implementation OABaseCarPlayInterfaceController

- (instancetype) initWithInterfaceController:(CPInterfaceController *)interfaceController
{
	self = [super init];
	if (self) {
		_interfaceController = interfaceController;
		[self commonInit];
	}
	return self;
}

- (void) commonInit
{
	// override
}

- (void) present
{
	// override
}

@end
