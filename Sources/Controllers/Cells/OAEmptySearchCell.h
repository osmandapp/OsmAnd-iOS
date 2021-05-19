//
//  OAEmptySearchCell.h
//  OsmAnd
//
//  Created by Alexey Kulish on 01/06/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OAEmptySearchCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *iconView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UILabel *messageView;

@end
