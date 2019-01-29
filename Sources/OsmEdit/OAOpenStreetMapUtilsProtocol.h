//
//  OAOpenStreetMapUtilsProtocol.h
//  OsmAnd
//
//  Created by Paul on 1/26/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAOsmPoint.h"
#include <OsmAndCore/Data/ObfMapObject.h>

@class OAEntityInfo;
@class OAEntity;

@protocol OAOpenStreetMapUtilsProtocol <NSObject>

-(OAEntityInfo *)getEntityInfo:(long)identifier;

-(OAEntity *)commitEntityImpl:(EOAAction) action entity:(OAEntity *)entity entityInfo:(OAEntityInfo *)info comment:(NSString *)comment
               closeChangeSet:(BOOL)closeChangeSet changedTags:(NSSet<NSString *> *) changedTags;

-(void)closeChangeSet;

-(OAEntity *)loadEntity:(const shared_ptr<const OsmAnd::ObfMapObject>) mapObject;

@end
