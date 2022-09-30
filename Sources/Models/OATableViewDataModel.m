//
//  OATableViewDataModel.m
//  OsmAnd Maps
//
//  Created by Paul on 20.09.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OATableViewDataModel.h"
#import "OATableViewSectionData.h"

@implementation OATableViewDataModel
{
    NSMutableArray<OATableViewSectionData *> *_sectionData;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _sectionData = [NSMutableArray array];
    }
    return self;
}

- (void)addSection:(OATableViewSectionData *)sectionData
{
    [_sectionData addObject:sectionData];
}

- (void)addSection:(OATableViewSectionData *)sectionData atIndex:(NSInteger)index
{
    if (index < _sectionData.count)
        [_sectionData insertObject:sectionData atIndex:index];
}


- (OATableViewSectionData *)sectionDataForIndex:(NSUInteger)index
{
    return _sectionData[index];
}

- (OATableViewRowData *)itemForIndexPath:(NSIndexPath *)indexPath
{
    OATableViewSectionData *section = _sectionData[indexPath.section];
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

@end
