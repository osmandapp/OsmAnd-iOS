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
    EOABaseButtonColorSchemeRed
};

@interface OABaseButtonsViewController : OABaseNavbarViewController

@property (weak, nonatomic) IBOutlet UIView *separatorBottomView;
@property (weak, nonatomic) IBOutlet UIButton *topButton;
@property (weak, nonatomic) IBOutlet UIButton *bottomButton;

- (void)setupBottomButtons;

- (EOABaseBottomColorScheme)getBottomColorScheme;
- (CGFloat)getSpaceBetweenButtons;
- (NSString *)getTopButtonTitle;
- (NSString *)getBottomButtonTitle;
- (EOABaseButtonColorScheme)getTopButtonColorScheme;
- (EOABaseButtonColorScheme)getBottomButtonColorScheme;
- (BOOL)isBottomSeparatorVisible;

- (void)onTopButtonPressed;
- (void)onBottomButtonPressed;

@end
