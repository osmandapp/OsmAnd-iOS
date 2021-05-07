//
//  OAButtonRightIconCell.h
//  OsmAnd
//
// Created by Skalii Dmitrii on 22.04.2021.
// Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OABaseCell.h"

@interface OAButtonRightIconCell : OABaseCell

@property (weak, nonatomic) IBOutlet UIView *view;
@property (weak, nonatomic) IBOutlet UIButton *button;
@property (weak, nonatomic) IBOutlet UIImageView *iconView;

@end
