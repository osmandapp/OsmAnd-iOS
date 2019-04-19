//
//  OAMultiIconTextDescCell.h
//  OsmAnd
//
//  Created by Paul on 18/04/19.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OAMultiIconTextDescCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *iconView;
@property (weak, nonatomic) IBOutlet UILabel *textView;
@property (weak, nonatomic) IBOutlet UILabel *descView;
@property (weak, nonatomic) IBOutlet UIButton *overflowButton;

+ (CGFloat) getHeight:(NSString *)title value:(NSString *)value cellWidth:(CGFloat)cellWidth;

-(void)showImage:(BOOL)show;

@end
