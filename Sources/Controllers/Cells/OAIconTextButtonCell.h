//
//  OAIconTextButtonCell.h
//  OsmAnd
//
//  Created by Alexey Kulish on 04/01/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OAIconTextButtonCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *iconView;
@property (weak, nonatomic) IBOutlet UILabel *textView;
@property (weak, nonatomic) IBOutlet UILabel *descView;
@property (weak, nonatomic) IBOutlet UIImageView *detailsIconView;
@property (weak, nonatomic) IBOutlet UIButton *buttonView;

+ (CGFloat) getHeight:(NSString *)text descHidden:(BOOL)descHidden detailsIconHidden:(BOOL)detailsIconHidden cellWidth:(CGFloat)cellWidth;

@end
