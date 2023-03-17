//
//  OATextMultilineTableViewCell.m
//  OsmAnd
//
//  Created by Skalii on 22.12.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OATextMultilineTableViewCell.h"
#import "OAColors.h"

@interface OATextMultilineTableViewCell ()

@property (weak, nonatomic) IBOutlet UIView *clearButtonContainer;

@end

@implementation OATextMultilineTableViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];

    self.textView.textContainerInset = UIEdgeInsetsZero;
    [self.clearButton setImage:[UIImage templateImageNamed:@"ic_custom_clear_field"] forState:UIControlStateNormal];
    self.clearButton.tintColor = UIColorFromRGB(color_tint_gray);
}

- (void)clearButtonVisibility:(BOOL)show
{
    self.clearButtonContainer.hidden = !show;
}

- (void)textViewVisibility:(BOOL)show
{
    self.textView.hidden = !show;
    if (!show)
        [self clearButtonVisibility:NO];

    [self updateMargins];
}

- (BOOL)checkSubviewsToUpdateMargins
{
    return !self.textView.hidden;
}

@end
