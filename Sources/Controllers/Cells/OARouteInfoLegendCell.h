//
//  OARouteInfoLegendCell.h
//  OsmAnd
//
//  Created by Paul on 17.12.2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OABaseCell.h"

NS_ASSUME_NONNULL_BEGIN

@class HorizontalBarChartView;

@interface OARouteInfoLegendCell : OABaseCell

@property (weak, nonatomic) IBOutlet UIStackView *legendStackView;

@end

NS_ASSUME_NONNULL_END
