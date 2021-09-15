//
//  OAQuickSearchResultTableViewCell.h
//  OsmAnd
//
//  Created by nnngrach on 6/09/21.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OAQuickSearchResultTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *icon;
@property (weak, nonatomic) IBOutlet UIImageView *directionIcon;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *distanceLabel;
@property (weak, nonatomic) IBOutlet UILabel *coordinateLabel;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *titleLabelTopConstraint;

- (void) setDesriptionLablesVisible:(BOOL)isVisible;

@end
