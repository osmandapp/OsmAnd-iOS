//
//  OATableViewCellWithClickableAccessoryView.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 5/16/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "OATableViewCell.h"

@interface OATableViewCellWithClickableAccessoryView : OATableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style
       andCustomAccessoryView:(UIView*)customAccessoryView
              reuseIdentifier:(NSString *)reuseIdentifier;

@end
