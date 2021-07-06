//
//  OATitleSliderRoundCell.h
//  OsmAnd
//
//  Created by Skalii on 02.06.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OATitleSliderRoundCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIView *contentContainer;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *valueLabel;
@property (weak, nonatomic) IBOutlet UISlider *sliderView;

- (void)roundCorners:(BOOL)topCorners bottomCorners:(BOOL)bottomCorners;

@end