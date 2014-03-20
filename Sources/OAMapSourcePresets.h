//
//  OAMapSourcePresets.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 3/20/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OAMapSourcePreset.h"

@interface OAMapSourcePresets : NSObject

- (id)initEmpty;
- (id)initWithPresets:(NSDictionary*)presets andOrder:(NSArray*)order;

@property(readonly) NSDictionary* presets;
@property(readonly) NSArray* order;

@end
