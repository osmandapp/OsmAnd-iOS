//
//  OAViewTextTableViewCell.h
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 21.11.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OAViewTextTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIView *viewView;
@property (weak, nonatomic) IBOutlet UILabel *textView;
@property (weak, nonatomic) IBOutlet UIImageView *iconView;

-(void)setColor:(UIColor*)color;


@end
