//
//  OARouteInfoAltitudeCell.h
//  OsmAnd
//
//  Created by Paul on 17.12.2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class LineChartView;

@interface OARouteInfoAltitudeCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *avgAltitudeTitle;
@property (weak, nonatomic) IBOutlet UILabel *avgAltitudeValue;
@property (weak, nonatomic) IBOutlet UILabel *ascentTitle;
@property (weak, nonatomic) IBOutlet UILabel *ascentValue;
@property (weak, nonatomic) IBOutlet UILabel *altRangeTitle;
@property (weak, nonatomic) IBOutlet UILabel *altRangeValue;
@property (weak, nonatomic) IBOutlet UILabel *descentTitle;
@property (weak, nonatomic) IBOutlet UILabel *descentValue;
@property (weak, nonatomic) IBOutlet UIImageView *ascentIcon;
@property (weak, nonatomic) IBOutlet UIImageView *descentIcon;

@end

NS_ASSUME_NONNULL_END
