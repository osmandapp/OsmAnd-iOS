//
//  OAConfiguration.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 3/19/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OAObservable.h"

#define kMapSourceId @"map_source_id"
#define kMapSourceId_OfflineMaps @"offline"
#define kOnlineMapSourceIdPrefix @"online:"

@interface OAConfiguration : NSObject

- (BOOL)save;
@property(readonly) OAObservable* observable;

@property(getter = getMapSourceId, setter = setMapSourceId:) NSString* mapSourceId;

@end
