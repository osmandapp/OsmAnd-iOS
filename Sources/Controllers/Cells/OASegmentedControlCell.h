//
//  OASegmentedControlCell.h
//  OsmAnd
//
//  Created by Paul on 24/11/2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OASegmentedControlCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *segmentedControlPrimaryHeight;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *segmentedControlSecondaryHeight;

- (void)changeHeight:(BOOL)higher;

@end
