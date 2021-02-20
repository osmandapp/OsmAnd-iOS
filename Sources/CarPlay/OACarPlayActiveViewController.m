//
//  OACarPlayActiveViewController.m
//  OsmAnd Maps
//
//  Created by Paul on 20.02.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OACarPlayActiveViewController.h"
#import "Localization.h"

@implementation OACarPlayActiveViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _messageLabel.text = OALocalizedString(@"carplay_active_message");
}

@end
