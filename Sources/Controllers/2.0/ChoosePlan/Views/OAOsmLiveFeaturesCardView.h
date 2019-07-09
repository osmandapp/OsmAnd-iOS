//
//  OAOsmLiveFeaturesCardView.h
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

@interface OAOsmLiveFeaturesCardView : OAPurchaseDialogItemView

- (OAPurchaseDialogCardRow *) addInfoRowWithText:(NSString *)text textColor:(UIColor *)color image:(UIImage *)image selected:(BOOL)selected showDivider:(BOOL)showDivider;
- (OAPurchaseDialogCardRow *) addInfoRowWithText:(NSString *)text image:(UIImage *)image selected:(BOOL)selected showDivider:(BOOL)showDivider;

@end

NS_ASSUME_NONNULL_END
