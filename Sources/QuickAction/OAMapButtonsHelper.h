//
//  OAMapButtonsHelper.h
//  OsmAnd
//
//  Created by Paul on 8/15/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OAObservable, OAApplicationMode, OAQuickAction, QuickActionType, QuickActionButtonState, MapButtonState, Map3DButtonState, CompassButtonState;

@interface OAMapButtonsHelper : NSObject

@property (readonly) OAObservable * _Nonnull quickActionsChangedObservable;
@property (readonly) OAObservable * _Nonnull quickActionButtonsChangedObservable;

+ (OAMapButtonsHelper * _Nonnull)sharedInstance;

+ (QuickActionType * _Nonnull)TYPE_CREATE_CATEGORY;
+ (QuickActionType * _Nonnull)TYPE_CONFIGURE_MAP;
+ (QuickActionType * _Nonnull)TYPE_NAVIGATION;
+ (QuickActionType * _Nonnull)TYPE_CONFIGURE_SCREEN;
+ (QuickActionType * _Nonnull)TYPE_SETTINGS;
+ (QuickActionType * _Nonnull)TYPE_MAP_INTERACTIONS;
+ (QuickActionType * _Nonnull)TYPE_MY_PLACES;

- (Map3DButtonState * _Nonnull)getMap3DButtonState;
- (CompassButtonState * _Nonnull)getCompassButtonState;
- (NSArray<QuickActionButtonState *> * _Nonnull)getButtonsStates;
- (NSArray<QuickActionButtonState *> * _Nonnull)getEnabledButtonsStates;

- (void)addQuickAction:(QuickActionButtonState * _Nonnull)buttonState action:(OAQuickAction * _Nonnull)action;
- (void)deleteQuickAction:(QuickActionButtonState * _Nonnull)buttonState action:(OAQuickAction * _Nonnull)action;
- (void)updateQuickAction:(QuickActionButtonState * _Nonnull)buttonState action:(OAQuickAction * _Nonnull)action;
- (void)updateQuickActions:(QuickActionButtonState * _Nonnull)buttonState actions:(NSArray<OAQuickAction *> * _Nonnull)actions;
- (void)onQuickActionsChanged:(QuickActionButtonState * _Nonnull)buttonState;

- (BOOL)isActionNameUnique:(NSArray<OAQuickAction *> * _Nonnull)actions quickAction:(OAQuickAction * _Nonnull)quickAction;
- (OAQuickAction * _Nonnull)generateUniqueActionName:(NSArray<OAQuickAction *> * _Nonnull)actions action:(OAQuickAction * _Nonnull)action;
- (NSString * _Nonnull)generateUniqueButtonName:(NSString * _Nonnull)name;

- (void)updateActionTypes;
- (void)updateActiveActions;
- (void)resetQuickActionsForMode:(OAApplicationMode * _Nonnull)appMode;
- (void)copyQuickActionsFromMode:(OAApplicationMode * _Nonnull)toAppMode fromAppMode:(OAApplicationMode * _Nonnull)fromAppMode;
- (NSArray<QuickActionType *> * _Nonnull)produceTypeActionsListWithHeaders:(QuickActionButtonState * _Nonnull)buttonState;
- (OAQuickAction * _Nullable)newActionByStringType:(NSString * _Nonnull)actionType;
- (OAQuickAction * _Nullable)newActionByType:(NSInteger)type;

- (BOOL)isActionButtonNameUnique:(NSString * _Nonnull)name;
- (QuickActionButtonState * _Nullable)getButtonStateByName:(NSString * _Nonnull)name;
- (QuickActionButtonState * _Nullable)getButtonStateById:(NSString * _Nonnull)id;
- (QuickActionButtonState * _Nonnull)createNewButtonState;
- (void)addQuickActionButtonState:(QuickActionButtonState * _Nonnull)buttonState;
- (void)removeQuickActionButtonState:(QuickActionButtonState * _Nonnull)buttonState;

+ (OAQuickAction * _Nonnull)produceAction:(OAQuickAction * _Nonnull)action;

@end
