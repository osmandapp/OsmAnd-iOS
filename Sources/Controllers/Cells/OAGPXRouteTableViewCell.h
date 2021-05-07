//
//  OAGPXRouteTableViewCell.h
//  OsmAnd
//
//  Created by Alexey Kulish on 08/07/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OABaseCell.h"

@interface OAGPXRouteTableViewCell : OABaseCell

@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UILabel *detailsView;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;

- (void) setDistance:(double)distance wptCount:(NSInteger)wptCount tripDuration:(NSTimeInterval)tripDuration;

@end
