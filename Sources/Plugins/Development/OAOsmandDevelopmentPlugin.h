//
//  OAOsmandDevelopmentPlugin.h
//  OsmAnd
//
//  Created by nnngrach on 31.05.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OAPlugin.h"

NS_ASSUME_NONNULL_BEGIN

@interface OAOsmandDevelopmentPlugin : OAPlugin

- (BOOL)isHeightmapEnabled;
- (BOOL) is3DMapsEnabled;
- (BOOL)isHeightmapAllowed;

@end

NS_ASSUME_NONNULL_END
