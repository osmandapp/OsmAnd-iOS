//
//  OABaseButtonsViewController.h
//  OsmAnd
//
//  Created by Skalii on 15.02.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OABaseNavbarViewController.h"

typedef NS_ENUM(NSInteger, EOABaseBottomColorScheme)
{
    EOABaseBottomColorSchemeBlurred = 0,
    EOABaseBottomColorSchemeBlank,
    EOABaseBottomColorSchemeGray,
    EOABaseBottomColorSchemeWhite
};

typedef NS_ENUM(NSInteger, EOABaseButtonColorScheme)
{
    EOABaseButtonColorSchemeInactive = 0,
    EOABaseButtonColorSchemeGraySimple,
    EOABaseButtonColorSchemeGrayAttn,
    EOABaseButtonColorSchemePurple,
    EOABaseButtonColorSchemeRed,
    EOABaseButtonColorSchemeBlank
};

@interface OABaseButtonsViewController : OABaseNavbarViewController

@property (weak, nonatomic) IBOutlet UIView *separatorBottomView;
@property (weak, nonatomic) IBOutlet UIButton *topButton;
@property (weak, nonatomic) IBOutlet UIButton *bottomButton;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *buttonsBottomOffsetConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *topTableViewConstraint;

- (instancetype) init NS_DESIGNATED_INITIALIZER;

- (void)updateBottomButtons;
- (void)setupBottomButtons;

- (UILayoutConstraintAxis)getBottomAxisMode;
- (EOABaseBottomColorScheme)getBottomColorScheme;
- (CGFloat)getSpaceBetweenButtons;
- (NSString *)getTopButtonTitle;
- (NSAttributedString *)getTopButtonTitleAttr;
- (NSString *)getBottomButtonTitle;
- (NSAttributedString *)getBottomButtonTitleAttr;
- (NSString *)getTopButtonIconName;
- (NSString *)getBottomButtonIconName;
- (EOABaseButtonColorScheme)getTopButtonColorScheme;
- (EOABaseButtonColorScheme)getBottomButtonColorScheme;
- (BOOL)isBottomSeparatorVisible;

- (void)onTopButtonPressed;
- (void)onBottomButtonPressed;

@end
