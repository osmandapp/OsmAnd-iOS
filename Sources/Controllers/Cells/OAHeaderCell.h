//
//  OAHeaderCell.h
//  OsmAnd
//
//  Created by Alexey Kulish on 28/05/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OAHeaderCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *iconView;
@property (weak, nonatomic) IBOutlet UILabel *textView;

- (void) setImage:(UIImage *)image tint:(BOOL)tint;

@end
