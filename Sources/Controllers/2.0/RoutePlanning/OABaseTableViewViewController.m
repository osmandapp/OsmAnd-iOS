//
//  OABaseTableViewViewController.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 15.01.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OABaseTableViewViewController.h"
#import "Localization.h"

@interface OABaseTableViewViewController()

@end

@implementation OABaseTableViewViewController
{
    NSArray<NSArray<NSDictionary *> *> *_data;
}

- (instancetype)init
{
    return [super initWithNibName:@"OABaseTableViewViewController" bundle:nil];
}

- (void) viewDidLoad
{
    [super viewDidLoad];
}

- (void) applyLocalization
{
    [super applyLocalization];
    [self.cancelButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
}

- (IBAction)cancelButtonPressed:(id)sender
{
    [self dismissViewController];
}

- (IBAction)backButtonPressed:(id)sender
{
    [self dismissViewController];
}

@end
