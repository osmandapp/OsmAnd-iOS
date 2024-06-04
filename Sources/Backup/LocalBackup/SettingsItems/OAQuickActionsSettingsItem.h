//
//  OAQuickActionsSettingsItem.h
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 19.11.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OACollectionSettingsItem.h"

@class OAQuickActionButtonState;

@interface OAQuickActionsSettingsItem : OASettingsItem

- (instancetype)initWithBaseItem:(OASettingsItem *)baseItem buttonState:(OAQuickActionButtonState *)buttonState;

- (OAQuickActionButtonState *)getButtonState;

@end
