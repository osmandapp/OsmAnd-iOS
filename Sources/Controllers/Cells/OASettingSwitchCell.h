//
//  OASettingSwitchCell.h
//  OsmAnd
//
//  Created by Alexey Kulish on 03/10/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OASettingSwitchCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *imgView;
@property (weak, nonatomic) IBOutlet UILabel *textView;
@property (weak, nonatomic) IBOutlet UILabel *descriptionView;
@property (weak, nonatomic) IBOutlet UIImageView *secondaryImgView;
@property (weak, nonatomic) IBOutlet UISwitch *switchView;

-(void)showPrimaryImage:(BOOL)show;

+ (CGFloat) getHeight:(NSString *)text desc:(NSString *)desc hasSecondaryImg:(BOOL)hasSecondaryImg cellWidth:(CGFloat)cellWidth;

@end
