//
//  OAPurchaseDialogCardButtonEx.h
//  OsmAnd
//
//  Created by Alexey on 17/12/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface OAPurchaseDialogCardButtonEx : UIView

@property (weak, nonatomic) IBOutlet UILabel *lbTitle;
@property (weak, nonatomic) IBOutlet UILabel *lbDescription;
@property (weak, nonatomic) IBOutlet UILabel *lbSaveLess;
@property (weak, nonatomic) IBOutlet UILabel *lbSaveMore;
@property (weak, nonatomic) IBOutlet UIButton *btnRegular;
@property (weak, nonatomic) IBOutlet UIButton *btnExtended;

- (void) setupButton:(BOOL)purchased title:(NSString *)title description:(NSString *)description discountDescr:(NSString *)discountDescr showDiscount:(BOOL)showDiscount highDiscount:(BOOL)highDiscount;

- (void) updateFrame;

@end

NS_ASSUME_NONNULL_END
