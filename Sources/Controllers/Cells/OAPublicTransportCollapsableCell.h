//
//  OAPublicTransportCollapsableCell.h
//  OsmAnd
//
//  Created by Paul on 24/03/20.
//  Copyright (c) 2020 OsmAnd. All rights reserved.
//

#import "OABaseCell.h"

@interface OAPublicTransportCollapsableCell : OABaseCell

@property (weak, nonatomic) IBOutlet UIImageView *iconView;
@property (weak, nonatomic) IBOutlet UILabel *textView;
@property (weak, nonatomic) IBOutlet UILabel *descView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *textHeightSecondary;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *textHeightPrimary;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *descHeightPrimary;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *descHeightSecondary;
@property (weak, nonatomic) IBOutlet UIView *routeLineView;

@end
