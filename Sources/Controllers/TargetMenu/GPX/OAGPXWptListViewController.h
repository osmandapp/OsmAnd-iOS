//
//  OAGPXWptListViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 21/06/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum
{
    EPointsSortingTypeGrouped = 0,
    EPointsSortingTypeDistance
    
} EPointsSortingType;

@protocol OAGPXWptListViewControllerDelegate <NSObject>

@optional
- (void) callGpxEditMode;

@end


@interface OAGPXWptListViewController : UITableViewController

@property (assign, nonatomic) EPointsSortingType sortingType;
@property (nonatomic) NSArray *allGroups;

- (void)doViewAppear;
- (void)doViewDisappear;

- (void)generateData;
- (void)resetData;
- (void)doSortClick:(UIButton *)button;
- (void)updateSortButton:(UIButton *)button;

- (NSArray *)getSelectedItems;

@property CGFloat azimuthDirection;

@property NSTimeInterval lastUpdate;

@property (weak, nonatomic) id<OAGPXWptListViewControllerDelegate> delegate;

- (id)initWithPoints:(NSArray *)points;
- (void)setPoints:(NSArray *)points;

@end
