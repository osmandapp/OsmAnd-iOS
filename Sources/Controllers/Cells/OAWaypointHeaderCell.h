//
//  OAWaypointHeader.h
//  OsmAnd
//
//  Created by Alexey Kulish on 19/03/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OAWaypointHeaderCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *progressView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UISwitch *switchView;
@property (weak, nonatomic) IBOutlet UIButton *imageButton;
@property (weak, nonatomic) IBOutlet UIButton *textButton;

+ (CGFloat) getHeight:(NSString *)text cellWidth:(CGFloat)cellWidth;

@end
