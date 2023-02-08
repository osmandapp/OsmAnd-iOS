//
//  OASearchHistoryTableGroup.m
//  OsmAnd Maps
//
//  Created by ДМИТРИЙ СВЕТЛИЧНЫЙ on 03.02.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OASearchHistoryTableGroup.h"

@interface OASearchHistoryTableGroup ()

@end

@implementation OASearchHistoryTableGroup

- (id)init
{
    self = [super init];
    if (self)
    {
        self.groupItems = [NSMutableArray array];
    }
    return self;
}

-(BOOL)isEqual:(id)object
{
    if (self == object)
        return YES;
    
    OASearchHistoryTableGroup *item = object;
    
    return [self.groupName isEqualToString:item.groupName];
}

-(NSUInteger)hash
{
    return [self.groupName hash];
}

@end
