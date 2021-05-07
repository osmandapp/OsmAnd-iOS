//
//  OAIconTextDescCell.h
//  OsmAnd
//
//  Created by Alexey Kulish on 20/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OABaseCell.h"

@interface OAIconTextDescCell : OABaseCell

@property (weak, nonatomic) IBOutlet UIImageView *iconView;
@property (weak, nonatomic) IBOutlet UILabel *textView;
@property (weak, nonatomic) IBOutlet UILabel *descView;
@property (weak, nonatomic) IBOutlet UIImageView *arrowIconView;

@property (nonatomic) IBOutlet NSLayoutConstraint *textLeftMargin;
@property (nonatomic) IBOutlet NSLayoutConstraint *textLeftMarginNoImage;
@property (nonatomic) IBOutlet NSLayoutConstraint *descrLeftMargin;
@property (nonatomic) IBOutlet NSLayoutConstraint *descrLeftMarginNoImage;

@property (nonatomic) IBOutlet NSLayoutConstraint *descrTopMargin;
@property (nonatomic) IBOutlet NSLayoutConstraint *textBottomMargin;
@property (nonatomic) IBOutlet NSLayoutConstraint *textHeightPrimary;
@property (nonatomic) IBOutlet NSLayoutConstraint *textHeightSecondary;

@end
