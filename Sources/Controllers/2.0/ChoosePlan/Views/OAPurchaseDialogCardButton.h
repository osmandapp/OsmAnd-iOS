//
//  OAPurchaseDialogCardButtonEx.h
//  OsmAnd
//
//  Created by Alexey on 17/12/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OAPurchaseDialogItemView.h"

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    EOAPurchaseDialogCardButtonTypeRegular = 0,
    EOAPurchaseDialogCardButtonTypeExtended,
    EOAPurchaseDialogCardButtonTypeDisabled
} EOAPurchaseDialogCardButtonType;

typedef void (^OAPurchaseDialogCardButtonClickHandler)(void);

@interface OAPurchaseDialogCardButton : OAPurchaseDialogItemView

@property (weak, nonatomic) IBOutlet UILabel *lbTitle;
@property (weak, nonatomic) IBOutlet UILabel *lbDescription;
@property (weak, nonatomic) IBOutlet UILabel *lbSaveLess;
@property (weak, nonatomic) IBOutlet UILabel *lbSaveMore;
@property (weak, nonatomic) IBOutlet UIButton *btnRegular;
@property (weak, nonatomic) IBOutlet UIButton *btnExtended;
@property (weak, nonatomic) IBOutlet UIButton *btnDisabled;

@property (nonatomic) NSString *discountStr;

- (void) setupButton:(BOOL)purchased active:(BOOL)active cancel:(BOOL)cancel title:(NSAttributedString *)title description:(NSAttributedString *)description discountDescr:(NSString *)discountDescr showDiscount:(BOOL)showDiscount highDiscount:(BOOL)highDiscount buttonClickHandler:(nullable OAPurchaseDialogCardButtonClickHandler)buttonClickHandler;

- (UIButton *) getActiveButton;

@end

NS_ASSUME_NONNULL_END
