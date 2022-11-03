//
//  OATableSectionData.m
//  OsmAnd Maps
//
//  Created by Paul on 20.09.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OATableSectionData.h"
#import "OATableRowData.h"

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
    if (self) {
        _rowData = [NSMutableArray array];
    }
    return self;
}

- (OATableRowData *) getRow:(NSUInteger)index
{
    if (index < _rowData.count)
        return _rowData[index];
    return nil;
}

- (void)addRow:(OATableRowData *)rowData
{
    [_rowData addObject:rowData];
}

- (OATableRowData *) addRowFromDictionary:(NSDictionary *)dictionary
{
    OATableRowData *row = [[OATableRowData alloc] initWithData:dictionary];
    [_rowData addObject:row];
    return row;
}

- (NSUInteger)rowCount
{
    NSUInteger res = 0;
    for (OATableRowData *row in _rowData)
    {
        res++;
        res += row.dependentRowsCount;
    }
    return res;
}

@end
