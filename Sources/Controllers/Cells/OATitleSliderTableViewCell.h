//
//  OATitleSliderTableViewCell.h
//  OsmAnd Maps
//
//  Created by igor on 17.02.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OATableViewCell.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^OAUpdateValueCallback)(float value);

@interface OATitleSliderTableViewCell : OATableViewCell

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *valueLabel;
@property (weak, nonatomic) IBOutlet UISlider *sliderView;
@property (nonatomic, copy, nullable) OAUpdateValueCallback updateValueCallback;

@end

NS_ASSUME_NONNULL_END
