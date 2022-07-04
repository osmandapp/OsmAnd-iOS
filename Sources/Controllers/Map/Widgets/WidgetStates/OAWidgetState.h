//
//  OAWidgetState.h
//  OsmAnd
//
//  Created by Alexey Kulish on 30/09/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OAWidgetState : NSObject

- (NSString *) getMenuTitle;

- (NSString *) getMenuDescription;

- (NSString *) getMenuIconId;

- (NSString *) getMenuItemId;

- (NSArray<NSString *> *) getMenuTitles;

- (NSArray<NSString *> *) getMenuDescriptions;

- (NSArray<NSString *> *) getMenuIconIds;

- (NSArray<NSString *> *) getMenuItemIds;

- (void) changeState:(NSString *)stateId;

@end
