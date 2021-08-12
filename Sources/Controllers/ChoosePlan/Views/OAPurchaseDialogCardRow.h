//
//  OAPurchaseDialogCardRow.h
//  OsmAnd
//
//  Created by Alexey on 17/12/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OAPurchaseDialogItemView.h"

NS_ASSUME_NONNULL_BEGIN

@interface OAPurchaseDialogCardRow : OAPurchaseDialogItemView

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *lbTitle;

- (void) setText:(NSString *)text textColor:(UIColor *)color image:(UIImage *)image selected:(BOOL)selected showDivider:(BOOL)showDivider;

@end

NS_ASSUME_NONNULL_END
