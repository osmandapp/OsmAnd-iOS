//
//  OATrackIntervalDialogView.h
//  OsmAnd
//
//  Created by Alexey Kulish on 04/05/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OATrackIntervalDialogView : UIView

@property (nonatomic, strong) IBOutlet UILabel *lbInterval;
@property (nonatomic, strong) IBOutlet UISlider *slInterval;
@property (nonatomic, strong) IBOutlet UILabel *lbRemember;
@property (nonatomic, strong) IBOutlet UISwitch *swRemember;

- (int)getInterval;

@end
