//
//  OATextViewResizingCell.h
//  OsmAnd
//
//  Created by Paul on 14/02/2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OABaseCell.h"

@interface OATextViewResizingCell : OABaseCell

@property (weak, nonatomic) IBOutlet UITextView *inputField;
@property (weak, nonatomic) IBOutlet UIButton *clearButton;

@end
