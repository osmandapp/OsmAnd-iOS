//
//  OAOpenStreetMapPoint.h
//  OsmAnd
//
//  Created by Paul on 1/24/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//
//  OsmAnd/src/net/osmand/plus/osmedit/OpenstreetmapPoint.java
//  git revision 30681c6f6485fc2314ea4b4e0841942db16ade43

#import "OAOsmPoint.h"

NS_ASSUME_NONNULL_BEGIN

@class OAEntity;

@interface OAOpenStreetMapPoint : OAOsmPoint <OAOsmPointProtocol>

-(NSString *) getType;
-(NSString *) getSubType;

-(OAEntity *) getEntity;
-(NSString *) getComment;

-(void) setEntity:(OAEntity *)entity;
-(void) setComment:(NSString *)comment;

-(NSString *) toNSString;

@end

NS_ASSUME_NONNULL_END
