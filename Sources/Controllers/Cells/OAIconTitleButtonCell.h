//
//  OAIconTitleButtonCell.h
//  OsmAnd
//
//  Created by Paul on 31/05/2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OAIconTitleButtonCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *iconView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIButton *buttonView;


-(void)showImage:(BOOL)show;
- (void) setButtonText:(NSString *)text;

+ (CGFloat) getHeight:(NSString *)text cellWidth:(CGFloat)cellWidth;

@end
