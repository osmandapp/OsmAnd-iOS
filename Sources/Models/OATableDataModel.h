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

+ (instancetype _Nonnull ) model;

@property (nonatomic) NSString * _Nullable tableHeaderText;
@property (nonatomic) NSString * _Nullable tableFooterText;
@property (nonatomic, readonly) BOOL hasChanged;

- (OATableSectionData * _Nonnull) createNewSection;
- (void) addSection:(OATableSectionData *_Nonnull)sectionData;
- (void) addSection:(OATableSectionData *_Nonnull)sectionData atIndex:(NSInteger)index;
- (void) addRowAtIndexPath:(NSIndexPath *_Nonnull)indexPath row:(OATableRowData *_Nonnull)row;
- (void) removeRowAt:(NSIndexPath *_Nonnull)indexPath;
- (void) removeSection:(NSUInteger)section;
- (void) removeItemsAtIndexPaths:(NSArray<NSIndexPath *> *_Nonnull)indexPaths;

- (OATableSectionData *_Nonnull)sectionDataForIndex:(NSUInteger)index;
- (OATableRowData *_Nonnull) itemForIndexPath:(NSIndexPath *_Nonnull)indexPath;

- (NSUInteger) sectionCount;
- (NSUInteger) rowCount:(NSUInteger)section;

- (void) clearAllData;
- (void) resetChanges;

@end
