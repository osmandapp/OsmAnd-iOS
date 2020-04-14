//
//  OAIconTextDescButtonTableViewCell.h
//  OsmAnd
//
//  Created by igor on 18.02.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OATableViewCell.h"

@protocol OAIconTextDescButtonCellDelegate <NSObject>

- (void) onButtonPressed:(NSInteger) tag;

@end

@interface OAIconTextDescButtonCell : OATableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *leftIconView;
@property (weak, nonatomic) IBOutlet UIButton *checkButton;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *descLabel;
@property (weak, nonatomic) IBOutlet UIImageView *dividerIcon;
@property (strong, nonatomic) IBOutlet UIView *additionalView;

@property (weak, nonatomic) id<OAIconTextDescButtonCellDelegate> delegate;

@end

