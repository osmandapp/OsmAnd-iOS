//
//  OAPluginSettingsItem.h
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 19.11.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OASettingsItem.h"

@class OACustomPlugin;

@interface OAPluginSettingsItem : OASettingsItem

@property (nonatomic, readonly) OACustomPlugin *plugin;

@property (nonatomic) NSArray<OASettingsItem *> *pluginDependentItems;

@end
