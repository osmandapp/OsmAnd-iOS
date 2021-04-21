//
//  OAImpassableRoadViewController.h
//  OsmAnd
//
//  Created by Paul on 17/12/2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OATargetMenuViewController.h"

@class OATargetPoint;

@interface OAChangePositionViewController : OATargetMenuViewController

@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIView *bottomToolBarDividerView;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;
@property (weak, nonatomic) IBOutlet UIView *mainTitleContainerView;
@property (weak, nonatomic) IBOutlet UILabel *mainTitleView;
@property (weak, nonatomic) IBOutlet UILabel *itemTitleView;
@property (weak, nonatomic) IBOutlet UIImageView *iconView;
@property (weak, nonatomic) IBOutlet UILabel *typeView;
@property (weak, nonatomic) IBOutlet UILabel *coordinatesView;

-(instancetype) initWithTargetPoint:(OATargetPoint *)targetPoint;

@end
