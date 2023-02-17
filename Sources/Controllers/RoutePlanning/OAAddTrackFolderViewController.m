//
//  OAAddTrackFolderViewController.m
//  OsmAnd
//
//  Created by nnngrach on 07.02.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OAAddTrackFolderViewController.h"
#import "OAColors.h"
#import "Localization.h"
#import "OAUtilities.h"
#import "OATextMultilineTableViewCell.h"
#import "OsmAndApp.h"

@interface OAAddTrackFolderViewController() <UITableViewDelegate, UITableViewDataSource, UITextViewDelegate>

@end

@implementation OAAddTrackFolderViewController
{
    NSArray<NSArray<NSDictionary *> *> *_data;
    NSString *_newFolderName;
    NSString *_inputFieldError;
    BOOL _doneButtonEnabled;
    BOOL _isFirstLaunch;
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
    self.doneButton.enabled = NO;
    _newFolderName = @"";
    _isFirstLaunch = YES;
}

- (void) generateData
{
    NSMutableArray *data = [NSMutableArray new];
    [data addObject:@[
        @{
            @"type" : [OATextMultilineTableViewCell getCellIdentifier],
            @"title" : @"",
            @"key" : @"input_name",
        }
    ]];
    _data = data;
}

- (void) applyLocalization
{
    [super applyLocalization];
    self.titleLabel.text = OALocalizedString(@"add_folder");
}

- (void)onDoneButtonPressed
{
    [self.delegate onTrackFolderAdded:[_newFolderName trim]];
}

#pragma mark - UITableViewDataSource

- (nonnull UITableViewCell *) tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    if ([item[@"type"] isEqualToString:[OATextMultilineTableViewCell getCellIdentifier]])
    {
        OATextMultilineTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OATextMultilineTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATextMultilineTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OATextMultilineTableViewCell *) nib[0];
            [cell leftIconVisibility:NO];
            cell.textView.userInteractionEnabled = YES;
            cell.textView.editable = YES;
            cell.textView.delegate = self;
            cell.textView.returnKeyType = UIReturnKeyDone;
            cell.textView.enablesReturnKeyAutomatically = YES;
        }
        if (cell)
        {
            if (_isFirstLaunch)
            {
                [cell.textView becomeFirstResponder];
                _isFirstLaunch = NO;
            }
            cell.textView.text = item[@"title"];
            cell.textView.tag = indexPath.section << 10 | indexPath.row;
            cell.clearButton.tag = cell.textView.tag;
            [cell.clearButton removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
            [cell.clearButton addTarget:self action:@selector(clearButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        }
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
    return OALocalizedString(@"shared_string_name");
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return (section == 0) ? _inputFieldError : nil;
}

#pragma mark - UITextViewDelegate

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if ([text isEqualToString:@"\n"])
    {
        [textView resignFirstResponder];
        return NO;
    }
    return YES;
}

- (void) textViewDidChange:(UITextView *)textView
{
    [self updateFileNameFromEditText:textView.text];

    [textView sizeToFit];
    [self.tableView beginUpdates];
    UITableViewHeaderFooterView *footer = [self.tableView footerViewForSection:0];
    footer.textLabel.textColor = _inputFieldError != nil ? UIColorFromRGB(color_primary_red) : UIColorFromRGB(color_text_footer);
    footer.textLabel.text = _inputFieldError;
    [footer sizeToFit];
    [self.tableView endUpdates];
}

#pragma mark - Selectors

- (void)clearButtonPressed:(UIButton *)sender
{
    _newFolderName = @"";
    _inputFieldError= @"";
    [self generateData];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
    self.doneButton.enabled = NO;
}

- (void) updateFileNameFromEditText:(NSString *)name
{
    _doneButtonEnabled = NO;
    NSString *text = name.trim;
    if (text.length == 0)
    {
        _inputFieldError = OALocalizedString(@"empty_filename");
    }
    else if ([self isIncorrectFileName:name])
    {
        _inputFieldError = OALocalizedString(@"incorrect_symbols");
    }
    else if ([self isFolderExist:name])
    {
        _inputFieldError = OALocalizedString(@"folder_already_exsists");
    }
    else
    {
        _inputFieldError = nil;
        _newFolderName = text;
        _doneButtonEnabled = YES;
    }
    self.doneButton.enabled = _doneButtonEnabled;
}

- (BOOL) isFolderExist:(NSString *)name
{
    BOOL hasReservedName = [name.lowerCase isEqualToString:OALocalizedString(@"shared_string_gpx_tracks").lowerCase] ||
                            [name.lowerCase isEqualToString:@"rec"] ;
    NSString *folderPath = [OsmAndApp.instance.gpxPath stringByAppendingPathComponent:name];
    return hasReservedName || [NSFileManager.defaultManager fileExistsAtPath:folderPath];
}

- (BOOL) isIncorrectFileName:(NSString *)fileName
{
    BOOL isFileNameEmpty = [fileName trim].length == 0;

    NSCharacterSet* illegalFileNameCharacters = [NSCharacterSet characterSetWithCharactersInString:@"/\\?%*|\"<>:;.,"];
    BOOL hasIncorrectSymbols = [fileName rangeOfCharacterFromSet:illegalFileNameCharacters].length != 0;
    
    return isFileNameEmpty || hasIncorrectSymbols;
}

@end
