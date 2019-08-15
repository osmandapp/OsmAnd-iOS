//
//  OAQuickActionFactory.h
//  OsmAnd
//
//  Created by Paul on 8/15/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class OAQuickAction;

@interface OAQuickActionFactory : NSObject

-(NSString *) OAQuickActionListToString:(NSArray<OAQuickAction *> *) quickActions;
-(NSArray<OAQuickAction *> *)parseActiveActionsList:(NSString *) json;

+(NSArray<OAQuickAction *> *) produceTypeActionsListWithHeaders:(NSArray<OAQuickAction *> *) active;
+(OAQuickAction *) newActionByType:(NSInteger) type;

+(OAQuickAction *) produceAction:(OAQuickAction *) quickAction;

+(NSString *) getActionIcon:(NSInteger) type;
+(NSString *)getActionName:(NSInteger) type;
+(BOOL) isActionEditable:(NSInteger) type;

@end

NS_ASSUME_NONNULL_END
