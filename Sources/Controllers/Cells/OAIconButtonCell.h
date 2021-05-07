//
//  OAIconButtonCell.h
//  OsmAnd
//
//  Created by Alexey Kulish on 27/12/2016.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OABaseCell.h"

@interface OAIconButtonCell : OABaseCell

@property (weak, nonatomic) IBOutlet UIImageView *iconView;
@property (weak, nonatomic) IBOutlet UILabel *textView;
@property (weak, nonatomic) IBOutlet UIImageView *arrowIconView;

- (void) setImage:(UIImage *)image tint:(BOOL)tint;

@end
