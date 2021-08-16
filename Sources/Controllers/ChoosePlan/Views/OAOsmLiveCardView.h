//
//  OAOsmLiveCardView.h
//  OsmAnd
//
//  Created by Alexey on 17/12/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OAPurchaseDialogItemView.h"
#import "OAPurchaseDialogCardRow.h"
#import "OAPurchaseDialogCardButton.h"

NS_ASSUME_NONNULL_BEGIN

@interface OAOsmLiveCardView : OAPurchaseDialogItemView

@property (weak, nonatomic) IBOutlet UILabel *lbTitle;
@property (weak, nonatomic) IBOutlet UILabel *lbDescription;
@property (weak, nonatomic) IBOutlet UIView *rowsContainer;
@property (weak, nonatomic) IBOutlet UIView *buttonsContainer;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *progressView;
@property (weak, nonatomic) IBOutlet UIButton *plansPricesButton;


- (OAPurchaseDialogCardRow *) addInfoRowWithText:(NSString *)text image:(UIImage *)image selected:(BOOL)selected showDivider:(BOOL)showDivider;
- (OAPurchaseDialogCardButton *) addCardButtonWithTitle:(NSAttributedString *)title description:(NSAttributedString *)description buttonText:(NSAttributedString *)buttonText buttonType:(EOAPurchaseDialogCardButtonType)buttonType active:(BOOL)active showTopDiv:(BOOL)showTopDiv showBottomDiv:(BOOL)showBottomDiv onButtonClick:(nullable OAPurchaseDialogCardButtonClickHandler)onButtonClick;

- (void) setProgressVisibile:(BOOL)visible;

@end

NS_ASSUME_NONNULL_END
