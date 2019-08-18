//
//  OAQuickActionRegistry.h
//  OsmAnd
//
//  Created by Paul on 8/15/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAObservable.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class OAQuickAction;

@interface OAQuickActionRegistry : NSObject

@property (readonly) OAObservable* quickActionListChangedObservable;

+ (OAQuickActionRegistry *)sharedInstance;

-(NSArray<OAQuickAction *> *) getQuickActions;
-(NSArray<OAQuickAction *> *) getFilteredQuickActions;

-(void) addQuickAction:(OAQuickAction *) action;
-(void) updateQuickAction:(OAQuickAction *) action;
-(void) updateQuickActions:(NSArray<OAQuickAction *> *) quickActions;
-(OAQuickAction *) getQuickAction:(long) identifier;

// Unused in Android
//-(void) deleteQuickAction:(OAQuickAction *) action;
//-(void) deleteQuickActionById:(long) identifier;

-(BOOL) isNameUnique:(OAQuickAction *) action;

-(OAQuickAction *) generateUniqueName:(OAQuickAction *) action;

@end

NS_ASSUME_NONNULL_END
