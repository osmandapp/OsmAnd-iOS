//
//  OATableDataModel.h
//  OsmAnd Maps
//
//  Created by Paul on 20.09.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class OATableSectionData, OATableRowData;

@interface OATableDataModel : NSObject

+ (instancetype) model;

@property (nonatomic, nullable) NSString *tableHeaderText;
@property (nonatomic, nullable) NSString *tableFooterText;
@property (nonatomic, readonly) BOOL hasChanged;

- (OATableSectionData *) createNewSection;
- (void) addSection:(OATableSectionData *)sectionData;
- (void) addSection:(OATableSectionData *)sectionData atIndex:(NSInteger)index;
- (void) addRowAtIndexPath:(NSIndexPath *)indexPath row:(OATableRowData *)row;
- (void) removeRowAt:(NSIndexPath *)indexPath;
- (void) removeSection:(NSUInteger)section;
- (void) removeItemsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths;

- (OATableSectionData *)sectionDataForIndex:(NSUInteger)index;
- (OATableRowData *) itemForIndexPath:(NSIndexPath *)indexPath;

- (NSUInteger) sectionCount;
- (NSUInteger) rowCount:(NSUInteger)section;

- (void) clearAllData;
- (void) resetChanges;

@end

NS_ASSUME_NONNULL_END
