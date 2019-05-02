//
//  OAButtonCell.h
//  OsmAnd
//
//  Created by Paul on 26/12/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OAButtonCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIButton *button;
@property (weak, nonatomic) IBOutlet UIImageView *iconView;

+ (CGFloat) getHeight:(NSString *)text desc:(NSString *)desc cellWidth:(CGFloat)cellWidth;

-(void)showImage:(BOOL)show;

@end
