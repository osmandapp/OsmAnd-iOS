//
//  OAPasswordInputFieldCell.h
//  OsmAnd
//
//  Created by Paul on 26/12/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MaterialTextFields.h"

@interface OAPasswordInputFieldCell : UITableViewCell

@property (weak, nonatomic) IBOutlet MDCTextField *inputField;
@property (weak, nonatomic) IBOutlet UIButton *togglePasswordButton;

+ (CGFloat) getHeight:(NSString *)text desc:(NSString *)desc cellWidth:(CGFloat)cellWidth;

- (void) setupPasswordButton;

@end
