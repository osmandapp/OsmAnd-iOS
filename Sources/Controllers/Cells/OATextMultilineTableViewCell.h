//
//  OATextMultilineTableViewCell.h
//  OsmAnd
//
//  Created by Skalii on 22.12.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OASimpleTableViewCell.h"

@interface OATextMultilineTableViewCell : OASimpleTableViewCell

@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UIButton *clearButton;
@property (weak, nonatomic) IBOutlet UIButton *clearButtonArea;

- (void)clearButtonVisibility:(BOOL)show;
- (void)textViewVisibility:(BOOL)show;

@end
