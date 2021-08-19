//
//  OAPurchaseCardView.h
//  OsmAnd
//
//  Created by Alexey on 21/12/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAPurchaseDialogItemView.h"
#import "OAPurchaseDialogCardRow.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^OAPurchaseCardButtonClickHandler)(void);

@interface OAPurchaseCardView : OAPurchaseDialogItemView

@property (weak, nonatomic) IBOutlet UILabel *lbTitle;
@property (weak, nonatomic) IBOutlet UILabel *lbDescription;
@property (weak, nonatomic) IBOutlet UIView *rowsContainer;
@property (weak, nonatomic) IBOutlet UILabel *lbButtonDescription;
@property (weak, nonatomic) IBOutlet UIButton *cardButton;
@property (weak, nonatomic) IBOutlet UIButton *cardButtonDisabled;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *progressView;
@property (weak, nonatomic) IBOutlet UILabel *lbButtonTitle;


- (void) setupCardWithTitle:(NSString *)title description:(NSString *)description buttonTitle:(NSString *)buttonTitle buttonDescription:(NSString *)buttonDescription;
- (void) setupCardButtonEnabled:(BOOL)buttonEnabled buttonText:(NSAttributedString *)buttonText buttonClickHandler:(nullable OAPurchaseCardButtonClickHandler)buttonClickHandler;

- (OAPurchaseDialogCardRow *) addInfoRowWithText:(NSString *)text image:(UIImage *)image selected:(BOOL)selected showDivider:(BOOL)showDivider;
- (void) setProgressVisibile:(BOOL)visible;

@end

NS_ASSUME_NONNULL_END
