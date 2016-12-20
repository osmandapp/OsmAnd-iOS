//
//  OACategoriesTableViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 17/12/2016.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol OACategoryTableDelegate

@required

- (void)didSelectCategoryItem:(id)item;

@end


@interface OACategoriesTableViewController : UITableViewController

@property (nonatomic) NSArray* dataArray;
@property (nonatomic) BOOL searchNearMapCenter;

@property (weak, nonatomic) id<OACategoryTableDelegate> delegate;

- (instancetype)initWithFrame:(CGRect)frame;

@end
