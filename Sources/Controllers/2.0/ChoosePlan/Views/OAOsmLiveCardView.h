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

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *lbTitle;
@property (weak, nonatomic) IBOutlet UILabel *lbDescription;
@property (weak, nonatomic) IBOutlet UIView *rowsContainer;
@property (weak, nonatomic) IBOutlet UILabel *lbButtonsDescription;
@property (weak, nonatomic) IBOutlet UIView *buttonsContainer;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *progressView;

- (OAPurchaseDialogCardRow *) addInfoRowWithText:(NSString *)text image:(UIImage *)image selected:(BOOL)selected;
- (OAPurchaseDialogCardButton *) addCardButtonWithTitle:(NSAttributedString *)title description:(NSAttributedString *)description buttonText:(NSString *)buttonText buttonType:(EOAPurchaseDialogCardButtonType)buttonType active:(BOOL)active discountDescr:(NSString *)discountDescr showDiscount:(BOOL)showDiscount highDiscount:(BOOL)highDiscount onButtonClick:(nullable OAPurchaseDialogCardButtonClickHandler)onButtonClick;

- (void) setProgressVisibile:(BOOL)visible;

@end

NS_ASSUME_NONNULL_END
