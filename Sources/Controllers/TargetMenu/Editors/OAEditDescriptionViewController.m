//
//  OAEditDescriptionViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 03/06/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAEditDescriptionViewController.h"
#import "Localization.h"
#import "OAColors.h"
#import "OATextViewSimpleCell.h"

@interface OAEditDescriptionViewController () <UITableViewDelegate, UITableViewDataSource, UITextViewDelegate>

@end

@implementation OAEditDescriptionViewController
{
    CGFloat _keyboardHeight;
    BOOL _isNew;
    BOOL _readOnly;
    BOOL _isEditing;
    NSArray<NSDictionary<NSString *, NSString *> *> *_cellsData;
    NSString *_textViewContent;
}

-(id)initWithDescription:(NSString *)desc isNew:(BOOL)isNew isEditing:(BOOL)isEditing readOnly:(BOOL)readOnly
{
    self = [super init];
    if (self)
    {
        self.desc = desc;
        _isNew = isNew;
        _readOnly = readOnly;
        _keyboardHeight = 0.0;
        _isEditing = isEditing || ((desc.length == 0) && !readOnly);
    }
    return self;
}

- (BOOL)isHtml:(NSString *)text
{
    BOOL res = NO;
    res = res || [text containsString:@"<html>"];
    res = res || [text containsString:@"<body>"];
    res = res || [text containsString:@"<div>"];
    res = res || [text containsString:@"<a>"];
    res = res || [text containsString:@"<p>"];
    res = res || [text containsString:@"<html "];
    res = res || [text containsString:@"<body "];
    res = res || [text containsString:@"<div "];
    res = res || [text containsString:@"<a "];
    res = res || [text containsString:@"<p "];
    res = res || [text containsString:@"<img "];
    return res;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorInset = UIEdgeInsetsMake(0., DBL_MAX, 0., 0.);
    self.tableView.backgroundColor = UIColorFromRGB(color_bottom_sheet_background);
    
    NSString *textHtml = self.desc;
    if (![self isHtml:textHtml])
    {
        textHtml = [textHtml stringByReplacingOccurrencesOfString:@"\n" withString:@"<br/>"];
    }
    if (![textHtml containsString:@"<header"])
    {
        NSString *head = @"<header><meta name='viewport' content='width=device-width, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0, user-scalable=no'><style> body { font-family: -apple-system; font-size: 17px; color:#000009} b {font-family: -apple-system; font-weight: bolder; font-size: 17px; color:#000000 }</style></header><head></head><div class=\"main\">%@</div>";
        textHtml = [NSString stringWithFormat:head, textHtml];
    }
    [_webView loadHTMLString:textHtml baseURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]]];
    
    [self setupView];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self registerForKeyboardNotifications];
    [self applySafeAreaMargins];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self unregisterKeyboardNotifications];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(UIView *) getTopView
{
    return _toolbarView;
}

-(UIView *) getMiddleView
{
    return _tableView;
}

-(void)setupView
{
    [self generateData];
    if (_isEditing)
    {
        _titleView.text = OALocalizedString(@"context_menu_edit_descr");
        _tableView.hidden = NO;
        _webView.hidden = YES;
        _saveButton.hidden = NO;
        _editButton.hidden = YES;
        _toolbarView.backgroundColor = UIColorFromRGB(color_bottom_sheet_background);
        _titleView.textColor = UIColor.blackColor;
        _saveButton.tintColor = UIColorFromRGB(color_primary_purple);
        _backButton.tintColor = UIColorFromRGB(color_primary_purple);
        [_backButton setTitle:@"" forState:UIControlStateNormal];
        [_backButton setImage:[UIImage templateImageNamed:@"ic_navbar_close"] forState:UIControlStateNormal];
    }
    else
    {
        _titleView.text = OALocalizedString(@"description");
        _tableView.hidden = YES;
        _webView.hidden = NO;
        _editButton.hidden = _readOnly;
        _saveButton.hidden = YES;
        _toolbarView.backgroundColor = UIColorFromRGB(color_chart_orange);
        _titleView.textColor = UIColor.whiteColor;
        _editButton.tintColor = UIColor.whiteColor;
        [_editButton setImage:[UIImage templateImageNamed:@"ic_navbar_pencil"] forState:UIControlStateNormal];
        _backButton.tintColor = UIColor.whiteColor;
        [_backButton setTitle:OALocalizedString(@"shared_string_back") forState:UIControlStateNormal];
        [_backButton setImage:[UIImage templateImageNamed:@"ic_navbar_chevron"] forState:UIControlStateNormal];
        if ([self.view isDirectionRTL])
            _backButton.imageView.image = _backButton.imageView.image.imageFlippedForRightToLeftLayoutDirection;
    }
    [self.tableView reloadData];
}

- (void) generateData
{
    if (_isEditing)
    {
        _cellsData = @[
            @{
                @"type" : [OATextViewSimpleCell getCellIdentifier],
                @"title" : self.desc,
                @"separatorInset" : @0
            }
        ];
    }
    else
    {
        _cellsData = @[];
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return _isEditing ? UIStatusBarStyleBlackOpaque : UIStatusBarStyleLightContent;
}

// keyboard notifications register+process
- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillChangeFrame:)
                                                 name:UIKeyboardWillChangeFrameNotification object:nil];
    
}

- (void)unregisterKeyboardNotifications
{
    //unregister the keyboard notifications while not visible
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardWillShow:(NSNotification*)aNotification
{
     CGRect keyboardFrame = [[[aNotification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
     CGRect convertedFrame = [self.view convertRect:keyboardFrame fromView:self.view.window];

    _keyboardHeight = convertedFrame.size.height;
    [self forceUpdateLayout];
}

- (void)keyboardWillChangeFrame:(NSNotification*)aNotification
{
    CGRect keyboardFrame = [[[aNotification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    CGRect convertedFrame = [self.view convertRect:keyboardFrame fromView:self.view.window];
    
    _keyboardHeight = convertedFrame.size.height;
    [self forceUpdateLayout];
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    [self forceUpdateLayout];
}

- (void)forceUpdateLayout
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:.3 animations:^{
            [self.view setNeedsLayout];
        }];
    });
}

#pragma mark - Actions

- (IBAction)saveClicked:(id)sender
{
    self.desc = _textViewContent;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(descriptionChanged)])
        [self.delegate descriptionChanged];
    
    [self backButtonClicked:self];
}

- (IBAction)editClicked:(id)sender
{
    _isEditing = YES;
    [self setupView];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _cellsData.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _cellsData[indexPath.row];
    
    if ([item[@"type"] isEqualToString:[OATextViewSimpleCell getCellIdentifier]])
    {
        OATextViewSimpleCell *cell = [tableView dequeueReusableCellWithIdentifier:[OATextViewSimpleCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATextViewSimpleCell getCellIdentifier] owner:self options:nil];
            cell = (OATextViewSimpleCell *)[nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if (cell)
        {
            NSNumber *inset = item[@"separatorInset"];
            cell.separatorInset = UIEdgeInsetsMake(0, inset.floatValue, 0, 0);
            cell.textView.delegate = self;
            cell.textView.text = item[@"title"];
            cell.textView.font = [UIFont systemFontOfSize:16];
            [cell.textView sizeToFit];
            cell.textView.editable = YES;
            [cell.textView becomeFirstResponder];
        }
        return cell;
    }

    return nil;
}

#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView
{
    _textViewContent = textView.text;
    [_tableView beginUpdates];
    [_tableView endUpdates];
}

@end
