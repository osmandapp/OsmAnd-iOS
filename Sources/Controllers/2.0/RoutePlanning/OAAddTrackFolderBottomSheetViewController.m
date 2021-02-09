//
//  OAAddTrackFolderBottomSheetViewController.m
//  OsmAnd
//
//  Created by nnngrach on 07.02.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OAAddTrackFolderBottomSheetViewController.h"
#import "OAColors.h"
#import "Localization.h"
#import "OAUtilities.h"
#import "OATextInputCell.h"

#define kCellTypeInput @"OATextInputCell"

@interface OAAddTrackFolderBottomSheetViewController() <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>

@end

@implementation OAAddTrackFolderBottomSheetViewController
{
    NSArray<NSArray<NSDictionary *> *> *_data;
    NSString *_newName;
}

- (instancetype) init
{
    self = [super initWithNibName:@"OABaseTableViewController" bundle:nil];
    if (self)
    {
        [self generateData];
    }
    return self;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorColor = UIColorFromRGB(color_tint_gray);
    self.doneButton.hidden = NO;
    _newName = [self getName];
}

- (void) generateData
{
    NSMutableArray *data = [NSMutableArray new];
    
    [data addObject:@[
        @{
           @"type" : kCellTypeInput,
           @"title" : [self getName]
        }
    ]];
    
    _data = data;
}

- (NSString *) getName
{
    //TODO: fetch data
    return @"";
}

- (void) applyLocalization
{
    [super applyLocalization];
    self.titleLabel.text = OALocalizedString(@"add_new_folder");
}

- (IBAction)doneButtonPressed:(id)sender
{
    //TODO: save _newName
    [self.delegate updateFolderName];
    [super doneButtonPressed:sender];
}

#pragma mark - UITableViewDataSource

- (nonnull UITableViewCell *) tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *cellType = item[@"type"];
    
    if ([cellType isEqualToString:kCellTypeInput])
    {
        static NSString* const identifierCell = @"OATextInputCell";
        OATextInputCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OATextInputCell" owner:self options:nil];
            cell = (OATextInputCell *)[nib objectAtIndex:0];
            [cell.inputField addTarget:self action:@selector(textViewDidChange:) forControlEvents:UIControlEventEditingChanged];
            cell.inputField.autocapitalizationType = UITextAutocapitalizationTypeSentences;
            cell.inputField.placeholder = OALocalizedString(@"enter_name");
        }
        cell.inputField.text = item[@"title"];
        cell.inputField.delegate = self;
        return cell;
    }
    
    return nil;
}

- (NSInteger) tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _data[section].count;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return OALocalizedString(@"fav_name");
}

#pragma mark - UITextFieldDelegate

- (BOOL) textFieldShouldReturn:(UITextField *)sender
{
    [sender resignFirstResponder];
    return YES;
}

- (void) textViewDidChange:(UITextView *)textView
{
    _newName = textView.text;
}

@end
