//
//  OAPluginSettingsItem.h
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 19.11.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OASettingsItem.h"

@interface OAPluginSettingsItem : OASettingsItem

@property (nonatomic) NSArray<OASettingsItem *> *pluginDependentItems;

@end
