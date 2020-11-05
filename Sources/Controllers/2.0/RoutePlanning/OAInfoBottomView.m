//
//  OAInfoBottomView.m
//  OsmAnd
//
//  Created by Paul on 03.11.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAInfoBottomView.h"

@implementation OAInfoBottomView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void) commonInit
{
    [NSBundle.mainBundle loadNibNamed:@"OAInfoBottomView" owner:self options:nil];
    [self addSubview:_contentView];
    _contentView.frame = self.bounds;
    _contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    _leftButton.layer.cornerRadius = 9.;
    _rightButton.layer.cornerRadius = 9.;
}

- (IBAction)leftButtonPressed:(id)sender {
    if (self.delegate)
        [self.delegate onLeftButtonPressed];
}
- (IBAction)rightButtonPressed:(id)sender {
    if (self.delegate)
        [self.delegate onRightButtonPressed];
}
- (IBAction)closeButtonPressed:(id)sender {
    if (self.delegate)
        [self.delegate onCloseButtonPressed];
}

@end
