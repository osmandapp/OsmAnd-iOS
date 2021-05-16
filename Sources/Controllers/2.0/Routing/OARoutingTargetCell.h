//
//  OARoutingTargetCell.h
//  OsmAnd
//
//  Created by Alexey Kulish on 11/08/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OABaseCell.h"

@interface OARoutingTargetCell : OABaseCell

@property (weak, nonatomic) IBOutlet UIImageView *imgView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *addressLabel;
@property (weak, nonatomic) IBOutlet UIButton *routingCellButton;

@property (nonatomic, assign) BOOL finishPoint;

- (void) setDividerVisibility:(BOOL)hidden;

@end
