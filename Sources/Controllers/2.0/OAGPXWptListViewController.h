//
//  OAGPXWptListViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 21/06/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OAObservable.h"
#import "OAAutoObserverProxy.h"

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

@property (strong, nonatomic) OAAutoObserverProxy* locationServicesUpdateObserver;
@property CGFloat azimuthDirection;

@property NSTimeInterval lastUpdate;

@property (weak, nonatomic) id<OAGPXWptListViewControllerDelegate> delegate;

- (id)initWithLocationMarks:(NSArray *)locationMarks;
- (void)setPoints:(NSArray *)locationMarks;

@end
