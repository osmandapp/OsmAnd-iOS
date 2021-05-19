//
//  OALineChartCell.h
//  OsmAnd
//
//  Created by Paul on 17.12.2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class LineChartView;

@interface OALineChartCell : UITableViewCell

@property (weak, nonatomic) IBOutlet LineChartView *lineChartView;

@end

NS_ASSUME_NONNULL_END
