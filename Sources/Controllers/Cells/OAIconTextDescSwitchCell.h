//
//  OAIconTextDescSwitchCell.h
//  OsmAnd
//
//  Created by Paul on 31.07.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OAIconTextDescSwitchCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *leftIconView;
@property (weak, nonatomic) IBOutlet UIButton *checkButton;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *descLabel;
@property (weak, nonatomic) IBOutlet UISwitch *switchView;
@property (weak, nonatomic) IBOutlet UIButton *switchAreaButton;
@property (weak, nonatomic) IBOutlet UIView *dividerView;


@end

