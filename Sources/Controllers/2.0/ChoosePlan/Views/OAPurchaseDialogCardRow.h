//
//  OAPurchaseDialogCardRow.h
//  OsmAnd
//
//  Created by Alexey on 17/12/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface OAPurchaseDialogCardRow : UIView

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *lbTitle;

- (void) setText:(NSString *)text image:(UIImage *)image;

- (void) updateFrame;

@end

NS_ASSUME_NONNULL_END
