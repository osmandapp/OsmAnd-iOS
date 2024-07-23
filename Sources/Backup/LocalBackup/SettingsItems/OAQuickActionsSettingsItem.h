//
//  OAQuickActionsSettingsItem.h
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 19.11.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OASettingsItem.h"

NS_ASSUME_NONNULL_BEGIN

@class QuickActionButtonState, OAQuickAction;

@interface OAQuickActionsSettingsItem : OASettingsItem

- (instancetype _Nonnull)initWithBaseItem:(OASettingsItem *)baseItem
                              buttonState:(QuickActionButtonState *)buttonState;

- (QuickActionButtonState *)getButtonState;
+ (void)parseParams:(NSString *)paramsString quickAction:(OAQuickAction *)quickAction;
+ (void)parseParamsWithKey:(NSString *)key params:(NSMutableDictionary *)params toString:(BOOL)toString;

@end

NS_ASSUME_NONNULL_END
