//
//  OAActionAddCategoryViewController.h
//  OsmAnd
//
//  Created by Paul on 8/15/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OABaseNavbarViewController.h"

@class OAQuickSearchListItem;

@protocol OAAddCategoryDelegate <NSObject>

@required

- (void) onCategoriesSelected:(NSArray *)items;

@end

@interface OAActionAddCategoryViewController : OABaseNavbarViewController

-(instancetype)initWithNames:(NSMutableArray<NSString *> *)names;

@property (nonatomic) id<OAAddCategoryDelegate> delegate;

@end
