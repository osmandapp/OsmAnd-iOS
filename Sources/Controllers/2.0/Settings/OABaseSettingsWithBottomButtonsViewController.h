//
//  OABaseSettingsWithBottomButtonsViewController.h
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 15.10.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OABaseBigTitleSettingsViewController.h"

@class OAApplicationMode;

@interface OABaseSettingsWithBottomButtonsViewController : OABaseBigTitleSettingsViewController

@property (strong, nonatomic) IBOutlet UIButton *additionalNavBarButton;
@property (strong, nonatomic) IBOutlet UIView *bottomBarView;
@property (strong, nonatomic) IBOutlet UIButton *primaryBottomButton;
@property (strong, nonatomic) IBOutlet UIButton *secondaryBottomButton;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *cancelButtonLeftMarginWithIcon;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *cancelButtonLeftMarginNoIcon;


@end
