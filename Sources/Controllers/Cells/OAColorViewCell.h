//
//  OAColorViewCell.h
//  OsmAnd
//
//  Created by Alexey Kulish on 01/06/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OABaseCell.h"

@interface OAColorViewCell : OABaseCell

@property (weak, nonatomic) IBOutlet UILabel *textView;
@property (weak, nonatomic) IBOutlet UILabel *descriptionView;
@property (weak, nonatomic) IBOutlet UIImageView *colorIconView;
@property (weak, nonatomic) IBOutlet UIImageView *iconView;

@end
