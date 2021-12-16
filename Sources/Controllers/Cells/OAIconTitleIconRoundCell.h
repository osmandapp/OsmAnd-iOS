//
//  OAIconTitleIconRoundCell.h
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 06.08.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OAIconTitleIconRoundCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *iconView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIView *contentContainer;
@property (weak, nonatomic) IBOutlet UIImageView *secondaryImageView;
@property (weak, nonatomic) IBOutlet UIView *separatorView;

+ (CGFloat) getHeight:(NSString *)text cellWidth:(CGFloat)cellWidth;

- (void) roundCorners:(BOOL)topCorners bottomCorners:(BOOL)bottomCorners;

@end
