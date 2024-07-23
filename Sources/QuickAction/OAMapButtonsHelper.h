//
//  OAMapButtonsHelper.h
//  OsmAnd
//
//  Created by Paul on 8/15/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class OAObservable, OAApplicationMode, OAQuickAction, QuickActionType, QuickActionButtonState, MapButtonState, Map3DButtonState, CompassButtonState;

@interface OAMapButtonsHelper : NSObject

@property (readonly) OAObservable *quickActionsChangedObservable;
@property (readonly) OAObservable *quickActionButtonsChangedObservable;

+ (OAMapButtonsHelper *)sharedInstance;

+ (QuickActionType *)TYPE_ADD_ITEMS;
+ (QuickActionType *)TYPE_CONFIGURE_MAP;
+ (QuickActionType *)TYPE_NAVIGATION;
+ (QuickActionType *)TYPE_CONFIGURE_SCREEN;
+ (QuickActionType *)TYPE_SETTINGS;
+ (QuickActionType *)TYPE_OPEN;

- (Map3DButtonState *)getMap3DButtonState;
- (CompassButtonState *)getCompassButtonState;
- (NSArray<QuickActionButtonState *> *)getButtonsStates;
- (NSArray<QuickActionButtonState *> *)getEnabledButtonsStates;

- (void)addQuickAction:(QuickActionButtonState *)buttonState action:(OAQuickAction *)action;
- (void)deleteQuickAction:(QuickActionButtonState *)buttonState action:(OAQuickAction *)action;
- (void)updateQuickAction:(QuickActionButtonState *)buttonState action:(OAQuickAction *)action;
- (void)updateQuickActions:(QuickActionButtonState *)buttonState actions:(NSArray<OAQuickAction *> *)actions;
- (void)onQuickActionsChanged:(QuickActionButtonState *)buttonState;

- (BOOL)isActionNameUnique:(NSArray<OAQuickAction *> *)actions quickAction:(OAQuickAction *)quickAction;
- (OAQuickAction *)generateUniqueActionName:(NSArray<OAQuickAction *> *)actions action:(OAQuickAction *)action;
- (NSString *)generateUniqueButtonName:(NSString *)name;

- (void)updateActionTypes;
- (void)updateActiveActions;
- (void)resetQuickActionsForMode:(OAApplicationMode *)appMode;
- (void)copyQuickActionsFromMode:(OAApplicationMode *)toAppMode fromAppMode:(OAApplicationMode *)fromAppMode;
- (NSArray<QuickActionType *> *)produceTypeActionsListWithHeaders:(QuickActionButtonState *)buttonState;
- (nullable OAQuickAction *)newActionByStringType:(NSString *)actionType;
- (nullable OAQuickAction *)newActionByType:(NSInteger)type;

- (BOOL)isActionButtonNameUnique:(NSString *)name;
- (nullable QuickActionButtonState *)getButtonStateByName:(NSString *)name;
- (nullable QuickActionButtonState *)getButtonStateById:(NSString *)id;
- (QuickActionButtonState *)createNewButtonState;
- (void)addQuickActionButtonState:(QuickActionButtonState *)buttonState;
- (void)removeQuickActionButtonState:(QuickActionButtonState *)buttonState;

+ (OAQuickAction *)produceAction:(OAQuickAction *)action;

@end

NS_ASSUME_NONNULL_END
