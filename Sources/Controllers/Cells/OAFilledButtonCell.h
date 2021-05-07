//
//  OAFilledButtonCell.h
//  OsmAnd
//
//  Created by Paul on 26/12/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OABaseCell.h"

@interface OAFilledButtonCell : OABaseCell

@property (weak, nonatomic) IBOutlet UIButton *button;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *topMarginConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *bottomMarginConstraint;

@end
