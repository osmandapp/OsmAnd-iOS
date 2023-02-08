//
//  OACarPlayActiveViewController.m
//  OsmAnd Maps
//
//  Created by Paul on 20.02.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OACarPlayActiveViewController.h"

@interface OACarPlayActiveViewController ()

@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *iconWidthConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *iconHeightConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *spacingConstraint;

@end

@implementation OACarPlayActiveViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _messageLabel.text = self.messageText;
    if (self.smallLogo)
    {
        _iconWidthConstraint.constant = 42.;
        _iconHeightConstraint.constant = 42.;
        _spacingConstraint.constant = 15.;
        _messageLabel.font = [UIFont scaledSystemFontOfSize:17.];
    }
}

@end
