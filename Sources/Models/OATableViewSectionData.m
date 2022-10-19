//
//  OATableViewSectionData.m
//  OsmAnd Maps
//
//  Created by Paul on 20.09.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OATableViewSectionData.h"
#import "OATableViewRowData.h"

@implementation OATableViewSectionData
{
    NSMutableArray<OATableViewRowData *> *_rowData;
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

- (OATableViewRowData *) getRow:(NSUInteger)index
{
    if (index < _rowData.count)
        return _rowData[index];
    return nil;
}

- (void)addRow:(OATableViewRowData *)rowData
{
    [_rowData addObject:rowData];
}

- (OATableViewRowData *) addRowFromDictionary:(NSDictionary *)dictionary
{
    OATableViewRowData *row = [[OATableViewRowData alloc] initWithData:dictionary];
    [_rowData addObject:row];
    return row;
}

- (NSUInteger)rowCount
{
    return _rowData.count;
}

@end
