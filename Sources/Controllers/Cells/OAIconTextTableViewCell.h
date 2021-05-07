//
//  OAIconTextTableViewCell.h
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 08.11.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OABaseCell.h"

@interface OAIconTextTableViewCell : OABaseCell

@property (weak, nonatomic) IBOutlet UIImageView *iconView;
@property (weak, nonatomic) IBOutlet UILabel *textView;
@property (weak, nonatomic) IBOutlet UIImageView *arrowIconView;

@property (nonatomic) IBOutlet NSLayoutConstraint *textLeftMargin;
@property (nonatomic) IBOutlet NSLayoutConstraint *textLeftMarginNoImage;
@property (nonatomic) IBOutlet NSLayoutConstraint *textRightMargin;
@property (nonatomic) IBOutlet NSLayoutConstraint *textRightMarginNoImage;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *iconViewHeightConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *iconViewWidthConstraint;

- (void) showImage:(BOOL)show;

@end
