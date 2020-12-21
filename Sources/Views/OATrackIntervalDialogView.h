//
//  OATrackIntervalDialogView.h
//  OsmAnd
//
//  Created by Alexey Kulish on 04/05/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OATrackIntervalDialogView : UIView

@property (nonatomic, weak) IBOutlet UILabel *lbInterval;
@property (nonatomic, weak) IBOutlet UISlider *slInterval;
@property (nonatomic, weak) IBOutlet UILabel *lbRemember;
@property (nonatomic, weak) IBOutlet UISwitch *swRemember;
@property (nonatomic, weak) IBOutlet UILabel *lbShowOnMap;
@property (nonatomic, weak) IBOutlet UISwitch *swShowOnMap;

- (int)getInterval;

@end
