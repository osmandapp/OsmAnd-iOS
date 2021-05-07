//
//  OARouteInfoCell.h
//  OsmAnd
//
//  Created by Paul on 17.12.2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OABaseCell.h"

NS_ASSUME_NONNULL_BEGIN

@class HorizontalBarChartView;

@interface OARouteInfoCell : OABaseCell

@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIButton *detailsButton;
@property (weak, nonatomic) IBOutlet UIImageView *expandImageView;
@property (weak, nonatomic) IBOutlet HorizontalBarChartView *barChartView;

- (void) onDetailsPressed;

@end

NS_ASSUME_NONNULL_END
