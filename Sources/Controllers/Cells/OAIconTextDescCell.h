//
//  OAIconTextDescCell.h
//  OsmAnd
//
//  Created by Alexey Kulish on 20/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OAIconTextDescCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *iconView;
@property (weak, nonatomic) IBOutlet UILabel *textView;
@property (weak, nonatomic) IBOutlet UILabel *descView;
@property (weak, nonatomic) IBOutlet UIImageView *arrowIconView;

@end
