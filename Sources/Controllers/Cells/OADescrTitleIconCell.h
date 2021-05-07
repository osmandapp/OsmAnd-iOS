//
//  OADescrTitleIconCell.h
//  OsmAnd
//
//  Created by Paul on 18/04/19.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OABaseCell.h"

@interface OADescrTitleIconCell : OABaseCell

@property (weak, nonatomic) IBOutlet UIImageView *iconView;
@property (weak, nonatomic) IBOutlet UILabel *textView;
@property (weak, nonatomic) IBOutlet UILabel *descView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *textHeightSecondary;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *textHeightPrimary;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *descHeightPrimary;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *descHeightSecondary;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *textTopConstraint;

@end
