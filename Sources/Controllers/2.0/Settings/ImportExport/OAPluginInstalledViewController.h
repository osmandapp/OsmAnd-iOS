//
//  OAPluginInstalledViewController.h
//  OsmAnd Maps
//
//  Created by Paul on 22.04.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OACompoundViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface OAPluginInstalledViewController : OACompoundViewController

- (instancetype) initWithPluginId:(NSString *)pluginId;

@end

NS_ASSUME_NONNULL_END
