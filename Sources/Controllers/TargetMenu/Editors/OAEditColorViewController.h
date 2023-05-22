//
//  OAEditColorViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 08/06/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OABaseNavbarViewController.h"

@protocol OAEditColorViewControllerDelegate <NSObject>

@optional
- (void) colorChanged;

@end

@interface OAEditColorViewController : OABaseNavbarViewController

@property (assign, nonatomic) NSInteger colorIndex;
@property (nonatomic, readonly) BOOL saveChanges;

@property (nonatomic, weak) id<OAEditColorViewControllerDelegate> delegate;

- (instancetype)initWithColor:(UIColor *)color;

@end
