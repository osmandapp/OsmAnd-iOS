//
//  OAQuickActionsSettingsItem.h
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 19.11.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OASettingsItem.h"

@class QuickActionButtonState, OAQuickAction;

@interface OAQuickActionsSettingsItem : OASettingsItem

- (instancetype)initWithBaseItem:(OASettingsItem *)baseItem buttonState:(QuickActionButtonState *)buttonState;

- (QuickActionButtonState *)getButtonState;
+ (void)parseParams:(NSString * _Nonnull)paramsString quickAction:(OAQuickAction * _Nonnull)quickAction;

@end
