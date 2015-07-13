//
//  OADirectionCardHeaderView.h
//  OsmAnd
//
//  Created by Alexey Kulish on 11/07/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OADestinationCardHeaderView : UIView

@property (nonatomic) UIView *containerView;
@property (nonatomic) UILabel *title;
@property (nonatomic) UIButton *rightButton;

- (void)setRightButtonTitle:(NSString *)title;

@end
