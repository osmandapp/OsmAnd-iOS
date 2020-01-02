//
//  OAMultiIconTextDescCell.h
//  OsmAnd
//
//  Created by Paul on 18/04/19.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OAMultiIconTextDescCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *iconView;
@property (weak, nonatomic) IBOutlet UILabel *textView;
@property (weak, nonatomic) IBOutlet UILabel *descView;
@property (weak, nonatomic) IBOutlet UIButton *overflowButton;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *textLeftMarginNoIcon;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *textLeftMargin;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *textHeightPrimary;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *textHeightSecondary;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *descHeightPrimary;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *descHeightSecondary;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *textRightMargin;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *textRightMarginNoButton;

-(void)setOverflowVisibility:(BOOL)hidden;

@end
