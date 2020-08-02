//
//  OANavigationSettingsHeader.h
//  OsmAnd
//
//  Created by nnngrach on 02.08.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OANavigationSettingsHeader : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *textView;
@property (weak, nonatomic) IBOutlet UIImageView *iconView;

+ (CGFloat) getHeight:(NSString *)title cellWidth:(CGFloat)cellWidth;

@end
