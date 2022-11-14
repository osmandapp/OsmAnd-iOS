//
//  OATableCollapsableRowData.h
//  OsmAnd Maps
//
//  Created by Paul on 03.11.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OATableRowData.h"

NS_ASSUME_NONNULL_BEGIN

@interface OATableCollapsableRowData : OATableRowData

@property (nonatomic, assign) BOOL collapsed;

- (void) addDependentRow:(OATableRowData *)rowData;
- (void) removeDependentRow:(OATableRowData *)rowData;

@end

NS_ASSUME_NONNULL_END
