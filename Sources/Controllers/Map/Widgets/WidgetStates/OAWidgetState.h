//
//  OAWidgetState.h
//  OsmAnd
//
//  Created by Alexey Kulish on 30/09/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class OAApplicationMode;

@interface OAWidgetState : NSObject

- (nullable NSString *) getMenuTitle;
- (nullable NSString *) getWidgetTitle;
- (nullable NSString *) getMenuDescription;
- (nullable NSString *) getMenuIconId;
- (nullable NSString *) getMenuItemId;
- (nullable NSArray<NSString *> *) getMenuTitles;
- (nullable NSArray<NSString *> *) getMenuDescriptions;
- (nullable NSArray<NSString *> *) getMenuIconIds;
- (nullable NSArray<NSString *> *) getMenuItemIds;
- (void) changeState:(NSString *)stateId;
- (nullable NSString *) getSettingsIconId:(BOOL)nightMode;
- (void) changeToNextState;
- (void) copyPrefs:(OAApplicationMode *)appMode customId:(nullable NSString *)customId;

@end

NS_ASSUME_NONNULL_END
