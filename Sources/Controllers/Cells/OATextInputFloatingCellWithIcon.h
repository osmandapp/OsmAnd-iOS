//
//  OATextInputFloatingCellWithIcon.h
//  OsmAnd
//
//  Created by Paul on 27/03/2019.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OABaseCell.h"
#import "MaterialTextFields.h"

@interface OATextInputFloatingCellWithIcon : OABaseCell

@property (weak, nonatomic) IBOutlet UIButton *buttonView;
@property (weak, nonatomic) IBOutlet MDCMultilineTextField *textField;
@property (weak, nonatomic) IBOutlet UILabel *fieldLabel;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *textFieldLeadingConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *textFieldTopConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *textFieldBottomConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *fieldLabelLeadingConstraint;

@end
