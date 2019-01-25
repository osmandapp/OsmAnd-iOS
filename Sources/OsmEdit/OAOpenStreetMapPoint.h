//
//  OAOpenStreetMapPoint.h
//  OsmAnd
//
//  Created by Paul on 1/24/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAOsmPoint.h"

NS_ASSUME_NONNULL_BEGIN

@class OAEntity;

@interface OAOpenStreetMapPoint : OAOsmPoint <OAOsmPointProtocol>

-(NSString *)getName;

-(NSString *) getType;
-(NSString *) getSubType;

-(OAEntity *) getEntity;
-(NSString *) getComment;

-(void) setEntity:(OAEntity *)entity;
-(void) setComment:(NSString *)comment;

-(NSString *) toNSString;

@end

NS_ASSUME_NONNULL_END
