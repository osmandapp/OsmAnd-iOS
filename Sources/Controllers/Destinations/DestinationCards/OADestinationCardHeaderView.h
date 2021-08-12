//
//  OADirectionCardHeaderView.h
//  OsmAnd
//
//  Created by Alexey Kulish on 11/07/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

static const CGFloat DESTINATION_CARD_TOP_INSET = 9.0;
static const CGFloat DESTINATION_CARD_BORDER = 14.0;

@interface OADestinationCardHeaderView : UIView

@property (nonatomic) UIView *containerView;
@property (nonatomic) UILabel *title;
@property (nonatomic) UIButton *rightButton;

- (void)setRightButtonTitle:(NSString *)title;

@end
