//
//  OAMenuSimpleCell.h
//  OsmAnd
//
//  Created by Alexey Kulish on 04/04/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OAMenuSimpleCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *imgView;
@property (weak, nonatomic) IBOutlet UILabel *textView;
@property (weak, nonatomic) IBOutlet UILabel *descriptionView;

+ (CGFloat) getHeight:(NSString *)text desc:(NSString *)desc cellWidth:(CGFloat)cellWidth;

@end
