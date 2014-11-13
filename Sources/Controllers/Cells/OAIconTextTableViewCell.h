//
//  OAIconTextTableViewCell.h
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 08.11.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OAIconTextTableViewCell : UITableViewCell

    @property (weak, nonatomic) IBOutlet UIImageView *iconView;
    @property (weak, nonatomic) IBOutlet UILabel *textView;
    @property (weak, nonatomic) IBOutlet UIImageView *arrowIconView;

    @property (weak, nonatomic) IBOutlet NSLayoutConstraint *imageWidthConstraint;


-(void)showImage:(BOOL)show;

@end
