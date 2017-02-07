//
//  OADiscountToolbarViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 07/02/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAToolbarViewController.h"

@protocol OADiscountToolbarViewControllerProtocol
@required

- (void)discountToolbarPress;
- (void)discountToolbarClose;

@end

@interface OADiscountToolbarViewController : OAToolbarViewController

@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;
@property (weak, nonatomic) IBOutlet UIButton *shadowButton;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;

@property (weak, nonatomic) id<OADiscountToolbarViewControllerProtocol> discountDelegate;

- (void) setTitle:(NSString *)title description:(NSString *)description icon:(UIImage *)icon;

@end
