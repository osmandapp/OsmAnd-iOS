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

@interface OAOsmEditingPlugin : OAPlugin

@property (nonatomic, readonly) OAOpenStreetMapLocalUtil *localUtil;

@end

NS_ASSUME_NONNULL_END
