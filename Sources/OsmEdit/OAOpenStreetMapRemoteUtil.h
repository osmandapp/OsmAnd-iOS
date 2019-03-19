//
//  OAOpenStreetMapRemoteUtil.h
//  OsmAnd
//
//  Created by Paul on 2/1/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//
//  OsmAnd/src/net/osmand/plus/osmedit/OpenstreetmapRemoteUtil.java
//  git revision df3397eb406aa7c8703e22a6ec1cab75e921c5f9

#import <Foundation/Foundation.h>
#import "OAOpenStreetMapUtilsProtocol.h"

NS_ASSUME_NONNULL_BEGIN
@class OAGPXDocument;

@interface OAOpenStreetMapRemoteUtil : NSObject <OAOpenStreetMapUtilsProtocol>

-(OAEntityInfo *)loadEntityFromEntity:(OAEntity *)entity;
-(long) openChangeSet:(NSString *)comment;
-(NSString *)uploadGPXFile:(NSString *)tagstring description:(NSString *)description visibility:(NSString *)visibility gpxDoc:(OAGPXDocument *)document;

@end

NS_ASSUME_NONNULL_END
