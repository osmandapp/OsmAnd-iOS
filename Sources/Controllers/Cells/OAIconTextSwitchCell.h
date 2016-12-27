//
//  OAIconTextSwitchCell.h
//  OsmAnd
//
//  Created by Alexey Kulish on 27/12/2016.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OAIconTextSwitchCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *iconView;
@property (weak, nonatomic) IBOutlet UILabel *textView;
@property (weak, nonatomic) IBOutlet UILabel *descView;
@property (weak, nonatomic) IBOutlet UIImageView *detailsIconView;
@property (weak, nonatomic) IBOutlet UISwitch *switchView;

- (CGFloat) getCellHeight;

@end
