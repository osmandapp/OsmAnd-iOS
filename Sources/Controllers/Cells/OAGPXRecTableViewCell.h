//
//  OAGPXRecTableViewCell.h
//  OsmAnd
//
//  Created by Alexey Kulish on 28/04/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OABaseCell.h"

@interface OAGPXRecTableViewCell : OABaseCell

@property (weak, nonatomic) IBOutlet UILabel *textView;
@property (weak, nonatomic) IBOutlet UIImageView *distIconView;
@property (weak, nonatomic) IBOutlet UILabel *descriptionDistanceView;
@property (weak, nonatomic) IBOutlet UIImageView *pointsIconView;
@property (weak, nonatomic) IBOutlet UILabel *descriptionPointsView;

@property (weak, nonatomic) IBOutlet UIButton *btnStartStopRec;
@property (weak, nonatomic) IBOutlet UIButton *btnSaveGpx;

@end
