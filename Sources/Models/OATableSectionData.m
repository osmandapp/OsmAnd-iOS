//
//  OATableSectionData.m
//  OsmAnd Maps
//
//  Created by Paul on 20.09.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OATableSectionData.h"
#import "OATableRowData.h"
#import "OATableCollapsableRowData.h"

@implementation OATableSectionData
{
    NSMutableArray<OATableRowData *> *_rowData;
}

+ (instancetype) sectionData
{
    return [[self.class alloc] init];
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _rowData = [NSMutableArray array];
        _hasChanged = NO;
    }
    return self;
}

- (OATableRowData *) createNewRow
{
    OATableRowData *rowData = [OATableRowData rowData];
    [self addRow:rowData];
    return rowData;
}

- (OATableRowData *) getRow:(NSUInteger)index
{
    NSInteger realIdx = -1;
    for (NSInteger i = 0; i < _rowData.count; i++)
    {
        realIdx++;
        OATableRowData *row = _rowData[i];
        if (index == realIdx)
            return row;
        if (row.dependentRowsCount > 0 && !((OATableCollapsableRowData *) row).collapsed)
        {
            for (NSInteger idx = 0; idx < row.dependentRowsCount; idx++)
            {
                realIdx++;
                if (realIdx == index)
                {
                    return [row getDependentRow:idx];
                }
            }
        }
    }
    return nil;
}

- (void)addRow:(OATableRowData *)rowData position:(NSUInteger)position
{
    [_rowData insertObject:rowData atIndex:position];
    _hasChanged = YES;
}

- (void)addRow:(OATableRowData *)rowData
{
    [_rowData addObject:rowData];
    _hasChanged = YES;
}

- (void)addRows:(NSArray<OATableRowData *> *)rows
{
    [_rowData addObjectsFromArray:rows];
    _hasChanged = YES;
}

- (OATableRowData *) addRowFromDictionary:(NSDictionary *)dictionary
{
    OATableRowData *row = [[OATableRowData alloc] initWithData:dictionary];
    [_rowData addObject:row];
    _hasChanged = YES;
    return row;
}

- (void)removeAllRows
{
    [_rowData removeAllObjects];
    _hasChanged = YES;
}

- (void)removeRowAtIndex:(NSInteger)index
{
    [_rowData removeObjectAtIndex:index];
    _hasChanged = YES;
}

- (NSUInteger)rowCount
{
    NSUInteger res = 0;
    for (OATableRowData *row in _rowData)
    {
        res++;
        if (row.rowType == EOATableRowTypeCollapsable && !((OATableCollapsableRowData *) row).collapsed)
            res += row.dependentRowsCount;
    }
    return res;
}

- (void) resetChanges
{
    _hasChanged = NO;
}

@end
