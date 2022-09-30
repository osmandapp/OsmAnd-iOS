//
//  OATableViewSectionData.h
//  OsmAnd Maps
//
//  Created by Paul on 20.09.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class OATableViewRowData;

@interface OATableViewSectionData : NSObject

+ (instancetype) sectionData;

@property (nonatomic) NSString *headerText;
@property (nonatomic) NSString *footerText;

- (OATableViewRowData *) getRow:(NSUInteger)index;

- (void)addRow:(OATableViewRowData *)rowData;
- (OATableViewRowData *) addRowFromDictionary:(NSDictionary *)dictionary;

- (NSUInteger) rowCount;

@end

NS_ASSUME_NONNULL_END
