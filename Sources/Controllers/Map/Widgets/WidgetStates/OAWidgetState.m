//
//  OAWidgetState.m
//  OsmAnd
//
//  Created by Alexey Kulish on 30/09/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAWidgetState.h"
#import "OsmAndApp.h"

@implementation OAWidgetState

- (NSString *) getMenuTitle
{
    return nil;
}

- (NSString *)getWidgetTitle
{
    return nil;
}

- (NSString *) getMenuDescription
{
    return nil;
}

- (NSString *) getMenuIconId
{
    return nil;
}

- (NSString *) getMenuItemId
{
    return nil;
}

- (NSArray<NSString *> *) getMenuTitles
{
    return nil;
}

- (NSArray<NSString *> *) getMenuDescriptions
{
    return nil;
}

- (NSArray<NSString *> *) getMenuIconIds
{
    return nil;
}

- (NSArray<NSString *> *) getMenuItemIds
{
    return nil;
}

- (void) changeState:(NSString *)stateId
{
}

- (void)changeToNextState {
}

- (void)copyPrefs:(OAApplicationMode *)appMode customId:(NSString *)customId {
}

- (NSString *)getSettingsIconId:(BOOL)nightMode {
    return nil;
}

@end
