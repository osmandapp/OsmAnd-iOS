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

@interface OAOsmLivePlansCardView : OAPurchaseDialogItemView

@property (weak, nonatomic) IBOutlet UIView *buttonsContainer;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *progressView;

- (OAPurchaseDialogCardButton *) addCardButtonWithTitle:(NSAttributedString *)title description:(NSAttributedString *)description buttonText:(NSAttributedString *)buttonText buttonType:(EOAPurchaseDialogCardButtonType)buttonType active:(BOOL)active showTopDiv:(BOOL)showTopDiv showBottomDiv:(BOOL)showBottomDiv onButtonClick:(nullable OAPurchaseDialogCardButtonClickHandler)onButtonClick;

- (void) setProgressVisibile:(BOOL)visible;

@end

NS_ASSUME_NONNULL_END
