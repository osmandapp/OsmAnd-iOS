//
//  OATitleRightIconCell.h
//  OsmAnd
//
//  Created by Paul on 31.07.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OABaseCell.h"

@interface OATitleRightIconCell : OABaseCell

@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIImageView *iconView;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *textTrailingMarginNoIcon;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *textTrailingMasrginWithIcon;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *textBottomMargin;

- (void) setIconVisibility:(BOOL)visible;
- (void) setBottomOffset:(CGFloat)offset;

@end
