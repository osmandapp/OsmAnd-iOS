//
//  OAGPXElevationTableViewCell.h
//  OsmAnd
//
//  Created by Alexey Kulish on 16/02/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OAGPXElevationTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *textView;
@property (weak, nonatomic) IBOutlet UIImageView *elev1ArrowView;
@property (weak, nonatomic) IBOutlet UILabel *elev1View;
@property (weak, nonatomic) IBOutlet UIImageView *elev2ArrowView;
@property (weak, nonatomic) IBOutlet UILabel *elev2View;

@property (nonatomic) BOOL showArrows;
@property (nonatomic) BOOL showUpDown;

@end
