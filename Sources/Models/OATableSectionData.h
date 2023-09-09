//
//  OATableSectionData.h
//  OsmAnd Maps
//
//  Created by Paul on 20.09.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class OATableRowData;

@interface OATableSectionData : NSObject

+ (instancetype) sectionData;

@property (nonatomic) NSString *headerText;
@property (nonatomic) NSString *footerText;
@property (nonatomic, readonly) BOOL hasChanged;

- (OATableRowData *) createNewRow;
- (OATableRowData *) getRow:(NSUInteger)index;

- (void)addRow:(OATableRowData *)rowData;
- (void)addRows:(NSArray<OATableRowData *> *)rows;
- (void)addRow:(OATableRowData *)rowData position:(NSUInteger)position;
- (OATableRowData *) addRowFromDictionary:(NSDictionary *)dictionary;
- (void)removeRowAtIndex:(NSInteger)index;
- (void)removeAllRows;

- (NSUInteger) rowCount;
- (void) resetChanges;

@end

NS_ASSUME_NONNULL_END
