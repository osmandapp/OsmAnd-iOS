//
//  OAOsmEditingPlugin.h
//  OsmAnd
//
//  Created by Paul on 1/18/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAPlugin.h"

NS_ASSUME_NONNULL_BEGIN
@class OAOpenStreetMapLocalUtil;
@class OAOsmBugsLocalUtil;

@interface OAOsmEditingPlugin : OAPlugin

@property (nonatomic, readonly) OAOpenStreetMapLocalUtil *localOsmUtil;
@property (nonatomic, readonly) OAOsmBugsLocalUtil *localBugsUtil;

@end

NS_ASSUME_NONNULL_END
