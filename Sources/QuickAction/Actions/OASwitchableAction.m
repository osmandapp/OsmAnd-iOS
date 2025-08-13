//
//  OASwitchableAction.m
//  OsmAnd
//
//  Created by Paul on 8/10/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OASwitchableAction.h"

@implementation OASwitchableAction

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

- (NSString *)getTitle:(NSArray *)filters
{
    if (filters.count == 0)
        return @"";
    
    return filters.count > 1
    ? [NSString stringWithFormat:@"%@ +%ld", filters[0], filters.count - 1]
    : filters[0];
}

@end
