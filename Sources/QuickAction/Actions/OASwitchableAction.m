//
//  OASwitchableAction.m
//  OsmAnd
//
//  Created by Paul on 8/10/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OASwitchableAction.h"

@implementation OASwitchableAction

- (instancetype)initWithAction:(OAQuickAction *)action
{
    return [super initWithAction:action];
}

- (void)executeWithParams:(NSArray<NSString *> *)params
{
}

- (NSString *)getTranslatedItemName:(NSString *)item
{
    return nil;
}

- (NSString *)getItemName:(id)item
{
    return nil;
}

- (NSString *)getAddBtnText
{
    return nil;
}

- (NSString *)getDescrHint
{
    return nil;
}

- (NSString *) getDescrTitle
{
    return nil;
}

- (NSString *)getListKey
{
    return nil;
}

- (NSArray *)loadListFromParams
{
    return nil;
}

- (void)saveListToParams:(NSArray *)list
{
}

- (BOOL)fillParams:(NSDictionary *)model
{
    NSMutableArray *sources = [NSMutableArray new];
    for (NSArray *arr in model.allValues)
    {
        for (NSDictionary *item in arr)
        {
            if ([item[@"type"] isEqualToString:@"OATitleDescrDraggableCell"])
            {
                NSString *value = item[@"value"] ? item[@"value"] : @"";
                [sources addObject:@{@"first":value, @"second":item[@"title"]}];
            }
        }
    }
    [self saveListToParams:sources];
    return sources.count > 0;
}

@end
