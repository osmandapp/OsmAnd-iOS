//
//  OASettingsCheckCell.h
//  OsmAnd
//
//  Created by Alexey Kulish on 23/10/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OASettingsImageCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *imgView;
@property (weak, nonatomic) IBOutlet UILabel *textView;
@property (weak, nonatomic) IBOutlet UIImageView *secondaryImgView;

- (void) setSecondaryImage:(UIImage *)image;

+ (CGFloat) getHeight:(NSString *)title hasSecondaryImg:(BOOL)hasSecondaryImg cellWidth:(CGFloat)cellWidth;

@end
