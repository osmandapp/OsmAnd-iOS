//
//  OAQuickActionRegistry.h
//  OsmAnd
//
//  Created by Paul on 8/15/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//
//  OsmAnd/src/net/osmand/plus/quickaction/QuickActionRegistry.java
//  git revision 8c4ac76b98a3ceddb0353b52b63574534c8ea4b3

#import "OAObservable.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class OAQuickAction;
@class OAQuickActionType;

@interface OAQuickActionRegistry : NSObject

@property (readonly) OAObservable* quickActionListChangedObservable;

+ (OAQuickActionRegistry *)sharedInstance;

+ (OAQuickActionType *) TYPE_ADD_ITEMS;
+ (OAQuickActionType *) TYPE_CONFIGURE_MAP;
+ (OAQuickActionType *) TYPE_NAVIGATION;

-(NSArray<OAQuickAction *> *) getQuickActions;

-(void) addQuickAction:(OAQuickAction *) action;
-(void) updateQuickAction:(OAQuickAction *) action;
-(void) updateQuickActions:(NSArray<OAQuickAction *> *) quickActions;
-(OAQuickAction *) getQuickAction:(long) identifier;
-(NSArray<OAQuickActionType *> *) produceTypeActionsListWithHeaders;
-(void) updateActionTypes;

-(BOOL) isNameUnique:(OAQuickAction *) action;

-(OAQuickAction *) generateUniqueName:(OAQuickAction *) action;

@end

NS_ASSUME_NONNULL_END
