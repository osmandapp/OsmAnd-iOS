//
//  OATextInputFloatingCell.h
//  OsmAnd
//
//  Created by Paul on 26/12/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MDCMultilineTextField;

@interface OATextInputFloatingCell : UITableViewCell

@property (weak, nonatomic) IBOutlet MDCMultilineTextField *inputField;

@end
