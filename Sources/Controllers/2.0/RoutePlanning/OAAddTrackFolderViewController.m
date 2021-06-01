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
#import "OATextViewResizingCell.h"
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
            @"type" : [OATextViewResizingCell getCellIdentifier],
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

-(void) clearButtonPressed:(UIButton *)sender
{
    _newFolderName = @"";
    _inputFieldError= @"";
    [self generateData];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
    self.doneButton.enabled = NO;
}

- (void)onDoneButtonPressed
{
    [self.delegate onTrackFolderAdded:[_newFolderName trim]];
}

#pragma mark - UITableViewDataSource

- (nonnull UITableViewCell *) tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *cellType = item[@"type"];
    
    if ([cellType isEqualToString:[OATextViewResizingCell getCellIdentifier]])
    {
        OATextViewResizingCell* cell = [tableView dequeueReusableCellWithIdentifier:[OATextViewResizingCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATextViewResizingCell getCellIdentifier] owner:self options:nil];
            cell = (OATextViewResizingCell *)[nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if (cell)
        {
            if (_isFirstLaunch)
            {
                [cell.inputField becomeFirstResponder];
                _isFirstLaunch = NO;
            }
            cell.inputField.text = item[@"title"];
            cell.inputField.delegate = self;
            cell.inputField.textContainer.lineBreakMode = NSLineBreakByCharWrapping;
            cell.inputField.returnKeyType = UIReturnKeyDone;
            cell.inputField.enablesReturnKeyAutomatically = YES;
            cell.clearButton.tag = cell.inputField.tag;
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
    return OALocalizedString(@"fav_name");
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return (section == 0) ? _inputFieldError : nil;
}

#pragma mark - UITextViewDelegate

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

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if([text isEqualToString:@"\n"])
    {
        [textView resignFirstResponder];
        return NO;
    }
    return YES;
}

- (BOOL) isFolderExist:(NSString *)name
{
    BOOL hasReservedName = [name.lowerCase isEqualToString:OALocalizedString(@"tracks").lowerCase] ||
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
