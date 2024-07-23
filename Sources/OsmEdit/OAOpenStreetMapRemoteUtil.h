//
//  OAOpenStreetMapRemoteUtil.h
//  OsmAnd
//
//  Created by Paul on 2/1/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//
//  OsmAnd/src/net/osmand/plus/osmedit/OpenstreetmapRemoteUtil.java
//  git revision ce7ffdab92a194402ec0dab844f4a80a6d32177e

#import <Foundation/Foundation.h>
#import "OAOpenStreetMapUtilsProtocol.h";

NS_ASSUME_NONNULL_BEGIN

@protocol OAOnUploadFileListener;

@class OAGPX, OAEntity, OAEntityInfo;

@interface OAOpenStreetMapRemoteUtil : NSObject <OAOpenStreetMapUtilsProtocol, NSURLSessionDelegate>

-(OAEntityInfo *)loadEntityFromEntity:(OAEntity *)entity;
-(long) openChangeSet:(NSString *)comment;
-(void)uploadGPXFile:(NSString *)tagstring description:(NSString *)description visibility:(NSString *)visibility gpxDoc:(OAGPX *)document listener:(id<OAOnUploadFileListener>)listener;

@end

NS_ASSUME_NONNULL_END
