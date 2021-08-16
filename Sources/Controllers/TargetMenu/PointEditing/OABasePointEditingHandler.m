//
//  OABasePointEditingHandler.m
//  OsmAnd Maps
//
//  Created by Paul on 01.06.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OABasePointEditingHandler.h"

@implementation OAPointEditingData

@end

@implementation OABasePointEditingHandler

- (UIColor *)getColor
{
    return nil; // override
}

- (NSString *)getGroupTitle
{
    return nil; // override
}

- (NSString *)getIcon
{
    return nil; //override
}

- (NSString *)getBackgroundIcon
{
    return nil; //override
}

- (NSString *)getName
{
    return nil; //override
}

- (BOOL)isSpecialPoint
{
    return NO;
}

- (void)deleteItem
{
    //override
}

- (NSDictionary *)checkDuplicates:(NSString *)name group:(NSString *)group
{
    return nil; //override
}

- (void)savePoint:(OAPointEditingData *)data newPoint:(BOOL)newPoint
{
    // override
}

@end
