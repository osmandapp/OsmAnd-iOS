//
//  OAOpenStreetMapUtilsProtocol.h
//  OsmAnd
//
//  Created by Paul on 1/26/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAOsmPoint.h"

@class OAEntityInfo;
@class OAEntity;
@class OATargetPoint;

@protocol OAOpenStreetMapUtilsProtocol <NSObject>

-(OAEntityInfo *)getEntityInfo:(long)identifier;

-(OAEntity *)commitEntityImpl:(EOAAction) action entity:(OAEntity *)entity entityInfo:(OAEntityInfo *)info comment:(NSString *)comment
               closeChangeSet:(BOOL)closeChangeSet changedTags:(NSSet<NSString *> *) changedTags;

-(void)closeChangeSet;

-(OAEntity *)loadEntity:(OATargetPoint *)targetPoint;

@end
