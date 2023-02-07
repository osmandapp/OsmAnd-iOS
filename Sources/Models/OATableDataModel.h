//
//  OATableDataModel.h
//  OsmAnd Maps
//
//  Created by Paul on 20.09.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OATableSectionData, OATableRowData;

@interface OATableDataModel : NSObject

+ (instancetype) model;

@property (nonatomic) NSString *tableHeaderText;
@property (nonatomic) NSString *tableFooterText;

- (OATableSectionData *) createNewSection;
- (void) addSection:(OATableSectionData *)sectionData;
- (void) addSection:(OATableSectionData *)sectionData atIndex:(NSInteger)index;

- (OATableSectionData *)sectionDataForIndex:(NSUInteger)index;
- (OATableRowData *) itemForIndexPath:(NSIndexPath *)indexPath;

- (NSUInteger) sectionCount;
- (NSUInteger) rowCount:(NSUInteger)section;

@end
