//
//  OAGPXEditWptListViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 18/08/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol OAGPXEditWptListViewControllerDelegate <NSObject>

@optional
- (void) callGpxEditMode;
- (void) callFullScreenMode;
- (void) refreshGpxDocWithPoints:(NSArray *)points;

@end

@interface OAGPXEditWptListViewController : UITableViewController

- (void)doViewAppear;
- (void)doViewDisappear;

- (void)generateData;
- (void)resetData;

- (NSArray *)getSelectedItems;

@property CGFloat azimuthDirection;
@property (weak, nonatomic) id<OAGPXEditWptListViewControllerDelegate> delegate;

@property NSTimeInterval lastUpdate;

- (id)initWithPoints:(NSArray *)points;
- (void)setPoints:(NSArray *)points;
- (void)setLocalEditing:(BOOL)localEditing;

@end
