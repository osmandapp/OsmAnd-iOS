//
//  OAActionAddCategoryViewController.h
//  OsmAnd
//
//  Created by Paul on 8/15/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OACompoundViewController.h"

@class OAQuickSearchListItem;

@protocol OAAddCategoryDelegate <NSObject>

@required

- (void) onCategoriesSelected:(NSArray *)items;

@end

@interface OAActionAddCategoryViewController : OACompoundViewController

-(instancetype)initWithNames:(NSMutableArray<NSString *> *)names;

@property (nonatomic) id<OAAddCategoryDelegate> delegate;

@end
