//
//  OABottomSheetHeaderDescrButtonCell.h
//  OsmAnd
//
//  Created by Paul on 8/03/2019.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OABaseCell.h"

@interface OABottomSheetHeaderDescrButtonCell : OABaseCell

@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIView *sliderView;
@property (weak, nonatomic) IBOutlet UILabel *descrLabel;
@property (weak, nonatomic) IBOutlet UIImageView *iconView;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;

@end
