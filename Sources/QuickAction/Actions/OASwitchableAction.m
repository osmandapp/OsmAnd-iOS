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

- (nullable NSString *)getTranslatedItemName:(NSString *)item
{
    return nil;
}

- (nullable NSString *)getItemName:(id)item
{
    return nil;
}

- (nullable NSString *)getAddBtnText
{
    return nil;
}

- (nullable NSString *)getDescrHint
{
    return nil;
}

- (nullable NSString *) getDescrTitle
{
    return nil;
}

- (nullable NSString *)getListKey
{
    return nil;
}

- (nullable NSString *)disabledItem
{
    return nil;
}

- (nullable NSString *)selectedItem
{
    return nil;
}

- (nullable NSString *)nextSelectedItem
{
    return nil;
}

- (nullable NSArray *)loadListFromParams
{
    return nil;
}

- (nullable NSString *)getTitle:(NSArray *)filters
{
    if (filters.count == 0)
        return @"";
    
    return filters.count > 1
    ? [NSString stringWithFormat:@"%@ +%ld", filters[0], filters.count - 1]
    : filters[0];
}

- (NSString *)nextFromSource:(NSArray<NSArray<NSString *> *> *)sources defValue:(NSString *)defValue
{
    if (sources.count > 0)
    {
        NSString *currentSource = [self selectedItem];
        if (sources.count > 1)
        {
            NSInteger index = -1;
            for (NSInteger idx = 0; idx < sources.count; idx++)
            {
                if ([sources[idx].firstObject isEqualToString:currentSource])
                {
                    index = idx;
                    break;
                }
            }
            NSArray<NSString *> *nextSource = sources.firstObject;
            if (index >= 0 && index + 1 < sources.count)
                nextSource = sources[index + 1];
            return nextSource.firstObject;
        }
        else
        {
            NSString *source = sources.firstObject.firstObject;
            return [source isEqualToString:currentSource] ? defValue : source;
        }
    }
    return nil;
}

@end
