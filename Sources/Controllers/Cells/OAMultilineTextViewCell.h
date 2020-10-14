//
//  OAMultilineTextViewCell.h
//  OsmAnd
//
//  Created by Paul on 24/08/19.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MaterialTextFields.h"

@interface OAMultilineTextViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet MDCMultilineTextField *inputField;

@end
