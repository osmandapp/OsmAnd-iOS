//
//  OATableViewCellWithButton.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 4/1/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "OATableViewCell.h"

@interface OATableViewCellWithButton : OATableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style
      andButtonType:(UIButtonType)buttonType
    reuseIdentifier:(NSString *)reuseIdentifier;

@property(readonly) UIButton* buttonView;

@end
