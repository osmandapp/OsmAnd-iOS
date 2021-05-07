//
//  OAIconTextFieldCell.h
//  OsmAnd
//
//  Created by Alexey Kulish on 04/01/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OABaseCell.h"

@interface OAIconTextFieldCell : OABaseCell

@property (weak, nonatomic) IBOutlet UIImageView *iconView;
@property (weak, nonatomic) IBOutlet UITextField *textField;

@end
