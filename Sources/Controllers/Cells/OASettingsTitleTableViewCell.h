//
//  OASettingsTitleTableViewCell.h
//  OsmAnd
//
//  Created by Alexey Kulish on 26/09/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OABaseCell.h"

@interface OASettingsTitleTableViewCell : OABaseCell

@property (weak, nonatomic) IBOutlet UILabel *textView;
@property (weak, nonatomic) IBOutlet UIImageView *iconView;

@end
