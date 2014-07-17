//
//  OAWorldRegion.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 4/27/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OAWorldRegion : NSObject

// Region data:
@property(readonly) NSString* regionId;
@property(readonly) NSString* nativeName;
@property(readonly) NSString* localizedName;
@property(readonly) NSString* name;
@property(readonly) NSArray* allNames;

// Hierarchy:
@property(readonly, weak) OAWorldRegion* superregion;
@property(readonly) NSArray* subregions;
@property(readonly) NSArray* flattenedSubregions;

- (NSComparisonResult)compare:(OAWorldRegion*)other;

+ (OAWorldRegion*)loadFrom:(NSString*)ocbfFilename;

@end
