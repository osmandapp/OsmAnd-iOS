//
//  OATableViewDataModel.h
//  OsmAnd Maps
//
//  Created by Paul on 20.09.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OATableViewSectionData, OATableViewRowData;

@interface OATableViewDataModel : NSObject

@property (nonatomic) NSString *tableHeaderText;
@property (nonatomic) NSString *tableFooterText;

- (void) addSection:(OATableViewSectionData *)sectionData;
- (void) addSection:(OATableViewSectionData *)sectionData atIndex:(NSInteger)index;

- (OATableViewSectionData *)sectionDataForIndex:(NSUInteger)index;
- (OATableViewRowData *) itemForIndexPath:(NSIndexPath *)indexPath;

- (NSUInteger) sectionCount;
- (NSUInteger) rowCount:(NSUInteger)section;

@end
