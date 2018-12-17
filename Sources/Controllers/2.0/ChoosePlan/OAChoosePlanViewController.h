//
//  OAChoosePlanViewController.h
//  OsmAnd
//
//  Created by Alexey on 17/12/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OASuperViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface OAChoosePlanViewController : OASuperViewController

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIView *navBarView;
@property (weak, nonatomic) IBOutlet UIButton *btnBack;
@property (weak, nonatomic) IBOutlet UILabel *lbTitle;
@property (weak, nonatomic) IBOutlet UILabel *lbDescription;
@property (weak, nonatomic) IBOutlet UIView *cardsContainer;
@property (weak, nonatomic) IBOutlet UIButton *btnLater;

@end

NS_ASSUME_NONNULL_END
