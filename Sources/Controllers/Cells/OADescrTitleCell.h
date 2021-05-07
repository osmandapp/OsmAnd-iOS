//
//  OADescrTitleCell.h
//  OsmAnd
//
//  Created by Paul on 19/09/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OABaseCell.h"

@interface OADescrTitleCell : OABaseCell

@property (weak, nonatomic) IBOutlet UILabel *textView;
@property (weak, nonatomic) IBOutlet UILabel *descriptionView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *textViewZeroHeightConstraint;

@end
