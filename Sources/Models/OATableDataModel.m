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
    BOOL _hasChanged;
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
        _hasChanged = NO;
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
    _hasChanged = YES;
}

- (void)addSection:(OATableSectionData *)sectionData atIndex:(NSInteger)index
{
    if (index < _sectionData.count)
        [_sectionData insertObject:sectionData atIndex:index];
}

- (void)removeSectionAt:(NSUInteger)index
{
    [_sectionData removeObjectAtIndex:index];
    _hasChanged = YES;
}

- (void)removeSection:(OATableSectionData *)section
{
    [_sectionData removeObject:section];
    _hasChanged = YES;
}

- (void)removeRowAt:(NSIndexPath *)indexPath
{
    [_sectionData[indexPath.section] removeRowAtIndex:indexPath.row];
}

- (void)removeItemsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths
{
    indexPaths = [indexPaths sortedArrayUsingComparator:^NSComparisonResult(NSIndexPath * _Nonnull indexPath1, NSIndexPath *  _Nonnull indexPath2) {
        return [self compareDescendingNSIndexPath:indexPath1 indexPath2:indexPath2];
    }];
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
            [self removeSectionAt:section.intValue];
        }
    }
}

- (void) addRowAtIndexPath:(NSIndexPath *)indexPath row:(OATableRowData *)row
{
    [_sectionData[indexPath.section] addRow:row position:indexPath.row];
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

- (BOOL) hasChanged
{
    if (_hasChanged)
        return YES;

    for (OATableSectionData *data in _sectionData)
		if (data.hasChanged)
            return YES;

    return NO;
}

- (void) resetChanges
{
    _hasChanged = NO;
    for (OATableSectionData *data in _sectionData)
        [data resetChanges];
}

- (NSComparisonResult)compareDescendingNSIndexPath:(NSIndexPath *)indexPath1 indexPath2:(NSIndexPath *)indexPath2
{
    if (indexPath1.section > indexPath2.section)
    {
        return NSOrderedAscending;
    }
    else if (indexPath1.section < indexPath2.section)
    {
        return NSOrderedDescending;
    }
    else
    {
        if (indexPath1.row > indexPath2.row)
            return NSOrderedAscending;
        else if (indexPath1.row < indexPath2.row)
            return NSOrderedDescending;
        else
            return NSOrderedSame;
    }
}

@end
