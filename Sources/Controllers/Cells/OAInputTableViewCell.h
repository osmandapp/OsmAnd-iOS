//
//  OAInputTableViewCell.h
//  OsmAnd
//
//  Created by Skalii on 20.12.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OASimpleTableViewCell.h"

@interface OAInputTableViewCell : OASimpleTableViewCell

@property (weak, nonatomic) IBOutlet UITextField *inputField;
@property (weak, nonatomic) IBOutlet UIButton *clearButton;
@property (weak, nonatomic) IBOutlet UIButton *clearButtonArea;

- (void)clearButtonVisibility:(BOOL)show;
- (void)inputFieldVisibility:(BOOL)show;

@end
