//
//  OAEntityInfo.h
//  OsmAnd
//
//  Created by Paul on 1/23/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//
//  OsmAnd-java/src/net/osmand/osm/edit/EntityInfo.java
//  git revision db3b280a26eaf721222ec918e8c0baf4dca9b1fd

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OAEntityInfo : NSObject

-(NSString *) getAction;
-(void) setAction:(NSString *) action;
-(NSString *) getTimestamp;
-(void) setTimestamp:(NSString*) timestamp;
-(NSString *) getUid;
-(void) setUid:(NSString *) uid;
-(NSString *) getUser;
-(void) setUser:(NSString *)user;
-(NSString *) getVisible;
-(void) setVisible:(NSString *)visible;
-(NSString *) getVersion;
-(void) setVersion:(NSString *)version;
-(NSString *) getChangeset;
-(void) setChangeset:(NSString *)changeset;

@end

NS_ASSUME_NONNULL_END
