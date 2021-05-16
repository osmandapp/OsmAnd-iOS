//
//  OARoutingInfoCell.h
//  OsmAnd
//
//  Created by Alexey Kulish on 11/08/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OABaseCell.h"

@interface OARoutingInfoCell : OABaseCell

@property (weak, nonatomic) IBOutlet UIImageView *trackImgView;
@property (weak, nonatomic) IBOutlet UILabel *distanceTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *distanceLabel;
@property (weak, nonatomic) IBOutlet UIImageView *timeImgView;
@property (weak, nonatomic) IBOutlet UILabel *timeTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;

@property (weak, nonatomic) IBOutlet UIButton *leftArrowButton;
@property (weak, nonatomic) IBOutlet UILabel *turnInfoLabel;
@property (weak, nonatomic) IBOutlet UIButton *rightArrowButton;

@property (nonatomic) int directionInfo;

- (void) updateControls;

@end
