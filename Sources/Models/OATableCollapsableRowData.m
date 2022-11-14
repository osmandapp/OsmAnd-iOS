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
        _collapsed = YES;
    }
    return self;
}

- (instancetype)initWithData:(NSDictionary *)data
{
    self = [super initWithData:data];
    if (self) {
        _dependentData = [NSMutableArray array];
        _collapsed = YES;
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

- (OATableRowData *) getDependentRow:(NSUInteger)index
{
    return _dependentData[index];
}

- (NSInteger) dependentRowsCount
{
    return _dependentData.count;
}

@end
