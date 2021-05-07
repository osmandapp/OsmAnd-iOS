//
//  OATextInputFloatingCell.h
//  OsmAnd
//
//  Created by Paul on 26/12/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OABaseCell.h"
#import "MaterialTextFields.h"

@interface OATextInputFloatingCell : OABaseCell

@property (weak, nonatomic) IBOutlet MDCMultilineTextField *inputField;

@end
