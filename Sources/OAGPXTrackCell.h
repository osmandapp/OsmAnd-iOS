//
//  OAGPXTrackCell.h
//  OsmAnd
//
//  Created by Anna Bibyk on 15.01.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OABaseCell.h"

@interface OAGPXTrackCell : OABaseCell

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIImageView *leftIconImageView;
@property (weak, nonatomic) IBOutlet UIImageView *distanceImageView;
@property (weak, nonatomic) IBOutlet UILabel *distanceLabel;
@property (weak, nonatomic) IBOutlet UIImageView *timeImageView;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UIImageView *wptImageView;
@property (weak, nonatomic) IBOutlet UILabel *wptLabel;
@property (weak, nonatomic) IBOutlet UIView *separatorView;
@property (weak, nonatomic) IBOutlet UIButton *editButton;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *buttonHiddenWidthConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *buttonFullWidthConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *titleRelativeToButtonConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *titleRelativeToMarginConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *separatorHeightConstraint;


- (void) setRightButtonVisibility:(BOOL)visible;

@end
