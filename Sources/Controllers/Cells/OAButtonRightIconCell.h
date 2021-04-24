//
//  OAButtonRightIconCell.h
//  OsmAnd
//
// Created by Skalii Dmitrii on 22.04.2021.
// Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OAQuickSearchButtonListItem.h"

@interface OAButtonRightIconCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIView *view;
@property (weak, nonatomic) IBOutlet UIButton *button;
@property (weak, nonatomic) IBOutlet UIImageView *iconView;
@property (nonatomic) OACustomSearchButtonOnClick onClickFunction;

- (void)onClick:(UITapGestureRecognizer *)sender;

@end
