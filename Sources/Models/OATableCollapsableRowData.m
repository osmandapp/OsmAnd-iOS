//
//  OATableCollapsableRowData.m
//  OsmAnd Maps
//
//  Created by Paul on 03.11.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OATableCollapsableRowData.h"

@implementation OATableCollapsableRowData
{
    NSMutableArray<OATableRowData *> *_dependentData;
}

- (EOATableRowType)rowType
{
    return EOATableRowTypeCollapsable;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _dependentData = [NSMutableArray array];
    }
    return self;
}

- (instancetype)initWithData:(NSDictionary *)data
{
    self = [super initWithData:data];
    if (self) {
        _dependentData = [NSMutableArray array];
    }
    return self;
}

- (void) addDependentRow:(OATableRowData *)rowData
{
    [_dependentData addObject:rowData];
}

- (void) removeDependentRow:(OATableRowData *)rowData
{
    [_dependentData removeObject:rowData];
}

- (NSInteger) dependentRowsCount
{
    return self.collapsed ? 0 : _dependentData.count;
}

@end
