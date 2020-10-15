//
//  OASettingSwitchCell.h
//  OsmAnd
//
//  Created by Alexey Kulish on 03/10/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OASettingSwitchCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *imgView;
@property (weak, nonatomic) IBOutlet UILabel *textView;
@property (weak, nonatomic) IBOutlet UILabel *descriptionView;
@property (weak, nonatomic) IBOutlet UIImageView *secondaryImgView;
@property (weak, nonatomic) IBOutlet UISwitch *switchView;

@property (nonatomic) IBOutlet NSLayoutConstraint *textLeftMargin;
@property (nonatomic) IBOutlet NSLayoutConstraint *textLeftMarginNoImage;
@property (nonatomic) IBOutlet NSLayoutConstraint *textRightMargin;
@property (nonatomic) IBOutlet NSLayoutConstraint *textRightMarginNoImage;

@property (nonatomic) IBOutlet NSLayoutConstraint *descrLeftMargin;
@property (nonatomic) IBOutlet NSLayoutConstraint *descrLeftMarginNoImage;
@property (nonatomic) IBOutlet NSLayoutConstraint *descrRightMargin;
@property (nonatomic) IBOutlet NSLayoutConstraint *descrRightMarginNoImage;
@property (nonatomic) IBOutlet NSLayoutConstraint *descrTopMargin;

@property (nonatomic) IBOutlet NSLayoutConstraint *textHeightPrimary;
@property (nonatomic) IBOutlet NSLayoutConstraint *textHeightSecondary;

- (void) setSecondaryImage:(UIImage *)image;

@end
