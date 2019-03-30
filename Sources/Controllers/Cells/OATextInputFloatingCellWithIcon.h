//
//  OATextInputFloatingCellWithIcon.h
//  OsmAnd
//
//  Created by Paul on 27/03/2019.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MaterialTextFields.h"

@interface OATextInputFloatingCellWithIcon : UITableViewCell

@property (weak, nonatomic) IBOutlet UIButton *buttonView;
@property (weak, nonatomic) IBOutlet MDCMultilineTextField *textField;
@property (weak, nonatomic) IBOutlet UILabel *fieldLabel;

+ (CGFloat) getHeight:(NSString *)text desc:(NSString *)desc cellWidth:(CGFloat)cellWidth;

@end
