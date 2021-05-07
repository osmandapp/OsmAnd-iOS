//
//  OATimeTableViewCell.h
//  OsmAnd
//
//  Created by Alexey Kulish on 06/05/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OABaseCell.h"

@interface OATimeTableViewCell : OABaseCell

@property (weak, nonatomic) IBOutlet UILabel *lbTitle;
@property (weak, nonatomic) IBOutlet UILabel *lbTime;
@property (weak, nonatomic) IBOutlet UIImageView *leftImageView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *imageWidthConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *titleToImageConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *titleToMarginConstraint;


- (void) showLeftImageView:(BOOL)show;

@end
