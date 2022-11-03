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

- (OATableRowData *) getRow:(NSUInteger)index;

- (void)addRow:(OATableRowData *)rowData;
- (OATableRowData *) addRowFromDictionary:(NSDictionary *)dictionary;

- (NSUInteger) rowCount;

@end

NS_ASSUME_NONNULL_END
