//
//  OATableData.mm
//  OsmAnd
//
//  Created by Skalii on 07.10.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OATableData.h"

@implementation OATableCellData

+ (instancetype)withKey:(NSString *)key
               cellType:(NSString *)cellType
                 values:(id)values
                  title:(NSString *)title
                   desc:(NSString *)desc
               leftIcon:(NSString *)leftIcon
              rightIcon:(NSString *)rightIcon
                 toggle:(BOOL)toggle
{
    OATableCellData *data = [OATableCellData new];
    if (data)
    {
        data.key = key;
        data.cellType = cellType;
        data.values = values;
        data.title = title;
        data.desc = desc;
        data.leftIcon = leftIcon;
        data.rightIcon = rightIcon;
        data.toggle = toggle;
    }
    return data;
}

+ (instancetype)withKey:(NSString *)key
               cellType:(NSString *)cellType
                 values:(NSDictionary *)values
                  title:(NSString *)title
{
    return [OATableCellData withKey:key
                           cellType:cellType
                             values:values
                              title:title
                               desc:nil
                           leftIcon:nil
                          rightIcon:nil
                             toggle:NO];
}

+ (instancetype)withKey:(NSString *)key
               cellType:(NSString *)cellType
                  title:(NSString *)title
{
    return [OATableCellData withKey:key
                           cellType:cellType
                             values:nil
                              title:title];
}

+ (instancetype)withKey:(NSString *)key
               cellType:(NSString *)cellType
                 values:(NSDictionary *)values
{
    return [OATableCellData withKey:key
                           cellType:cellType
                             values:values
                              title:nil];
}

+ (instancetype)withKey:(NSString *)key
               cellType:(NSString *)cellType
                 values:(NSDictionary *)values
                   desc:(NSString *)desc
               leftIcon:(NSString *)leftIcon
{
    return [OATableCellData withKey:key
                           cellType:cellType
                             values:values
                              title:nil
                               desc:desc
                           leftIcon:leftIcon
                          rightIcon:nil
                             toggle:NO];
}

+ (instancetype)withKey:(NSString *)key
               cellType:(NSString *)cellType
                  title:(NSString *)title
              rightIcon:(NSString *)rightIcon
                 toggle:(BOOL)toggle
{
    return [OATableCellData withKey:key
                           cellType:cellType
                             values:nil
                              title:title
                               desc:nil
                           leftIcon:nil
                          rightIcon:rightIcon
                             toggle:toggle];
}

+ (instancetype)withKey:(NSString *)key
               cellType:(NSString *)cellType
                 values:(NSDictionary *)values
                 toggle:(BOOL)toggle
{
    return [OATableCellData withKey:key
                           cellType:cellType
                             values:values
                              title:nil
                               desc:nil
                           leftIcon:nil
                          rightIcon:nil
                             toggle:toggle];
}

@end

@implementation OATableSectionData

+ (instancetype)withKey:(NSString *)key
                  cells:(NSArray<OATableCellData *> *)cells
                 header:(NSString *)header
                 footer:(NSString *)footer
{
    OATableSectionData *data = [OATableSectionData new];
    if (data)
    {
        data.key = key;
        data.cells = cells;
        data.header = header;
        data.footer = footer;
    }
    return data;
}

+ (instancetype)withKey:(NSString *)key
                  cells:(NSArray<OATableCellData *> *)cells
                 header:(NSString *)header
{
    return [OATableSectionData withKey:key
                                 cells:cells
                                header:header
                                footer:nil];
}

+ (instancetype)withKey:(NSString *)key
                  cells:(NSArray<OATableCellData *> *)cells
                 footer:(NSString *)footer
{
    return [OATableSectionData withKey:key
                                 cells:cells
                                header:nil
                                footer:footer];
}

+ (instancetype)withKey:(NSString *)key
                  cells:(NSArray<OATableCellData *> *)cells
{
    return [OATableSectionData withKey:key
                                 cells:cells
                                header:nil
                                footer:nil];
}

+ (instancetype)withKey:(NSString *)key
{
    return [OATableSectionData withKey:key
                                 cells:nil
                                header:nil
                                footer:nil];
}

- (BOOL)containsCell:(NSString *)key
{
    for (OATableCellData *cellData in self.cells)
    {
        if ([cellData.key isEqualToString:key])
            return YES;
    }
    return NO;
}

- (NSInteger)removeCell:(NSString *)key
{
    NSMutableArray<OATableCellData *> *newCellsData = [self.cells mutableCopy];
    OATableCellData *cellToDelete;
    NSInteger cellIndex = -1;
    
    for (OATableCellData *cellData in newCellsData)
    {
        if ([cellData.key isEqualToString:key])
        {
            cellIndex = [newCellsData indexOfObject:cellData];
            [newCellsData removeObject:cellData];
        }
    }
    
    self.cells = newCellsData;
    return cellIndex;
}

@end

@implementation OATableData

+ (instancetype)withSections:(NSArray<OATableSectionData *> *)sections
{
    OATableData *data = [OATableData new];
    if (data)
    {
        data.sections = sections;
    }
    return data;
}

- (void)setCells:(NSArray<OATableCellData *> *)cells inSection:(NSString *)key
{
    if (!self.sections)
        self.sections = [NSArray array];

    OATableSectionData *section = [self findSection:key];

    if (!section)
        section = [OATableSectionData withKey:key];

    section.cells = cells;

    if (![self.sections containsObject:section])
    {
        NSMutableArray<OATableSectionData *> *newSectionData = [self.sections mutableCopy];
        [newSectionData addObject:section];
        self.sections = newSectionData;
    }
}

- (void)setCell:(OATableCellData *)cell inSection:(NSString *)key
{
    if (!self.sections)
        self.sections = [NSArray array];

    OATableSectionData *section = [self findSection:key];

    if (!section)
    {
        section = [OATableSectionData withKey:key];
        section.cells = @[cell];
    }

    if ([section containsCell:cell.key])
    {
        NSInteger cellIndex = [section removeCell:cell.key];
        NSMutableArray<OATableCellData *> *newCellData = [section.cells mutableCopy];
        newCellData[cellIndex] = cell;
        section.cells = newCellData;

        NSInteger sectionIndex = [self getSectionPosition:key];
        NSMutableArray<OATableSectionData *> *newSectionData = [self.sections mutableCopy];
        newSectionData[sectionIndex] = section;
        self.sections = newSectionData;
    }
}

- (void)removeCell:(NSString *)key
{
    OATableSectionData *section;
    for (OATableSectionData *sectionData in self.sections)
    {
        if ([sectionData containsCell:key])
        {
            section = sectionData;
            break;
        }
    }

    if (section)
        [section removeCell:key];
}

- (NSInteger)getSectionPosition:(NSString *)key
{
    OATableSectionData *section = [self findSection:key];
    if (section)
        return [self.sections indexOfObject:section];

    return -1;
}

- (OATableSectionData *)findSection:(NSString *)key
{
    for (OATableSectionData *sectionData in self.sections)
    {
        if ([sectionData.key isEqualToString:key])
            return sectionData;
    }
    return nil;
}

@end
