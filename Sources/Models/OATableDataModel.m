//
//  OATableDataModel.m
//  OsmAnd Maps
//
//  Created by Paul on 20.09.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OATableDataModel.h"
#import "OATableSectionData.h"
#import "OATableRowData.h"

@implementation OATableDataModel
{
    NSMutableArray<OATableSectionData *> *_sectionData;
}

+ (instancetype) model
{
    return [[self.class alloc] init];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _sectionData = [NSMutableArray array];
    }
    return self;
}

- (OATableSectionData *) createNewSection
{
    OATableSectionData *sectionData = [OATableSectionData sectionData];
    [self addSection:sectionData];
    return sectionData;
}

- (void)addSection:(OATableSectionData *)sectionData
{
    [_sectionData addObject:sectionData];
}

- (void)addSection:(OATableSectionData *)sectionData atIndex:(NSInteger)index
{
    if (index < _sectionData.count)
        [_sectionData insertObject:sectionData atIndex:index];
}

- (void)removeSection:(NSUInteger)section
{
    [_sectionData removeObjectAtIndex:section];
}

- (void)removeItemsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths
{
    for (NSIndexPath *indexPath in indexPaths)
    {
        [_sectionData[indexPath.section] removeRowAtIndex:indexPath.row];
    }

    NSMutableArray<NSNumber *> *emptySections = [NSMutableArray array];
    for (NSIndexPath *indexPath in indexPaths)
    {
        NSNumber *section = @(indexPath.section);
        if (![emptySections containsObject:section] && [_sectionData[indexPath.section] rowCount] == 0)
            [emptySections addObject:section];
    }
    if (emptySections.count > 0)
    {
        for (NSNumber *section in [emptySections sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:nil ascending:NO]]])
        {
            [self removeSection:section.intValue];
        }
    }
}

- (OATableSectionData *)sectionDataForIndex:(NSUInteger)index
{
    return _sectionData[index];
}

- (OATableRowData *)itemForIndexPath:(NSIndexPath *)indexPath
{
    OATableSectionData *section = _sectionData[indexPath.section];
    return [section getRow:indexPath.row];
}

- (NSUInteger)sectionCount
{
    return _sectionData.count;
}

- (NSUInteger)rowCount:(NSUInteger)section
{
    return _sectionData[section].rowCount;
}

- (void) clearAllData
{
    _sectionData.removeAllObjects;
}

@end
