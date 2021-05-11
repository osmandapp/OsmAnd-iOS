//
//  OADeleteButtonTableViewCell.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 23.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OADeleteButtonTableViewCell.h"
#import "OAColors.h"

@implementation OADeleteButtonTableViewCell
{
    UIImage *_reorderImage;
}

+ (NSString *) getCellIdentifier
{
    return @"OADeleteButtonTableViewCell";
}

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (void) setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:YES];
    if (editing)
        for (UIView* view in self.subviews)
        {
            if ([NSStringFromClass([view class]) rangeOfString: @"Reorder"].location != NSNotFound)
            {
                for (UIView * subview in view.subviews)
                    if ([subview isKindOfClass: [UIImageView class]])
                    {
                        UIImageView *imageView = (UIImageView *)subview;
                        if (_reorderImage == nil)
                        {
                            UIImage *myImage = imageView.image;
                            _reorderImage = [myImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                            
                        }
                        imageView.image = _reorderImage;
                        imageView.tintColor = UIColorFromRGB(color_icon_inactive);
                    }
            }
        }
}

@end
