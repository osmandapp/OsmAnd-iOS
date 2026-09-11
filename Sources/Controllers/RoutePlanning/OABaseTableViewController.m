//
//  OABaseTableViewController.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 15.01.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OABaseTableViewController.h"
#import "Localization.h"
#import "OsmAnd_Maps-Swift.h"

@interface OABaseTableViewController()

@end

@implementation OABaseTableViewController
{
    NSArray<NSArray<NSDictionary *> *> *_data;
}

- (instancetype)init
{
    return [super initWithNibName:@"OABaseTableViewController" bundle:nil];
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    self.tableView.separatorColor = [SeparatorAppearance color];
}

- (void) applyLocalization
{
    [super applyLocalization];
    [self.cancelButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
}

- (IBAction)cancelButtonPressed:(id)sender
{
    [self onCancelButtonPressed];
    [self dismissViewController];
}

- (IBAction)doneButtonPressed:(id)sender
{
    [self onDoneButtonPressed];
    [self dismissViewController];
}

- (void)onCancelButtonPressed
{
}

- (void)onDoneButtonPressed
{
}

- (IBAction)backButtonPressed:(id)sender
{
    [self dismissViewController];
}

@end
