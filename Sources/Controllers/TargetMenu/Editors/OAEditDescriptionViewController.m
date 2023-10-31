//
//  OAEditDescriptionViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 03/06/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAEditDescriptionViewController.h"
#import "Localization.h"
#import "OsmAnd_Maps-Swift.h"
#import "OATextMultilineTableViewCell.h"
#import "OAWebViewCell.h"

@interface OAEditDescriptionViewController () <UITableViewDelegate, UITableViewDataSource, UITextViewDelegate>

@property (nonatomic) NSString *desc;
@property (weak, nonatomic) IBOutlet WKWebView *webView;

@end

@implementation OAEditDescriptionViewController
{
    CGFloat _keyboardHeight;
    BOOL _isNew;
    BOOL _readOnly;
    BOOL _isEditing;
    BOOL _isComment;
    NSArray<NSDictionary<NSString *, NSString *> *> *_cellsData;
}

-(instancetype)initWithDescription:(NSString *)desc isNew:(BOOL)isNew isEditing:(BOOL)isEditing readOnly:(BOOL)readOnly
{
    return [self initWithDescription:desc isNew:isNew isEditing:isEditing isComment:NO readOnly:readOnly];
}

-(instancetype)initWithDescription:(NSString *)desc isNew:(BOOL)isNew isEditing:(BOOL)isEditing isComment:(BOOL)isComment readOnly:(BOOL)readOnly
{
    self = [super init];
    if (self)
    {
        self.desc = desc ? desc : @"";
        _isNew = isNew;
        _readOnly = readOnly;
        _keyboardHeight = 0.0;
        _isComment = isComment;
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
    self.tableView.tableFooterView = [[UIView alloc] init];
    self.tableView.backgroundColor = UIColor.viewBgColor;
    
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

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        if(!_isEditing)
        {
            [self generateData];
            [_tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
        
    } completion:nil];
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
        _saveButton.hidden = NO;
        _editButton.hidden = YES;
        _toolbarView.backgroundColor = UIColor.viewBgColor;
        _titleView.textColor = UIColor.textColorPrimary;
        _saveButton.tintColor = UIColor.iconColorActive;
        _backButton.tintColor =  UIColor.iconColorActive;
        [_backButton setTitle:@"" forState:UIControlStateNormal];
        [_backButton setImage:[UIImage templateImageNamed:@"ic_navbar_close"] forState:UIControlStateNormal];
        _webView.hidden = YES;
    }
    else
    {
        _titleView.text = _isComment ? OALocalizedString(@"poi_dialog_comment") : OALocalizedString(@"shared_string_description");
        _editButton.hidden = _readOnly;
        _saveButton.hidden = YES;
        _toolbarView.backgroundColor = UIColor.navBarBgColorPrimary;
        _titleView.textColor = UIColor.whiteColor;
        _editButton.tintColor = UIColor.whiteColor;
        [_editButton setImage:[UIImage templateImageNamed:@"ic_navbar_pencil"] forState:UIControlStateNormal];
        _backButton.tintColor = UIColor.whiteColor;
        [_backButton setTitle:OALocalizedString(@"shared_string_back") forState:UIControlStateNormal];
        [_backButton setImage:[UIImage templateImageNamed:@"ic_navbar_chevron"] forState:UIControlStateNormal];
        if ([self.view isDirectionRTL])
            _backButton.imageView.image = _backButton.imageView.image.imageFlippedForRightToLeftLayoutDirection;
        _webView.hidden = NO;
    }
}

- (void) generateData
{
    if (_isEditing)
    {
        _cellsData = @[
            @{
                @"type" : [OATextMultilineTableViewCell getCellIdentifier],
                @"title" : self.desc,
                @"separatorInset" : @0
            }
        ];
    }
    else
    {
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
        [_webView loadHTMLString:textHtml  baseURL:nil];
        
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
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    
}

- (void)unregisterKeyboardNotifications
{
    //unregister the keyboard notifications while not visible
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) keyboardWillShow:(NSNotification *)notification;
{
    NSDictionary *userInfo = [notification userInfo];
    NSValue *keyboardBoundsValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGFloat keyboardHeight = [keyboardBoundsValue CGRectValue].size.height;

    CGFloat duration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    NSInteger animationCurve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    UIEdgeInsets insets = [[self tableView] contentInset];
    [UIView animateWithDuration:duration delay:0. options:animationCurve animations:^{
        [[self tableView] setContentInset:UIEdgeInsetsMake(insets.top, insets.left, keyboardHeight, insets.right)];
        [[self view] layoutIfNeeded];
    } completion:nil];
}

- (void) keyboardWillHide:(NSNotification *)notification;
{
    NSDictionary *userInfo = [notification userInfo];
    CGFloat duration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    NSInteger animationCurve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    UIEdgeInsets insets = [[self tableView] contentInset];
    [UIView animateWithDuration:duration delay:0. options:animationCurve animations:^{
        [[self tableView] setContentInset:UIEdgeInsetsMake(insets.top, insets.left, 0., insets.right)];
        [[self view] layoutIfNeeded];
    } completion:nil];
}

#pragma mark - Actions

- (IBAction)saveClicked:(id)sender
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(descriptionChanged:)])
        [self.delegate descriptionChanged:self.desc];

    [self dismissViewController];
}

- (IBAction)editClicked:(id)sender
{
    _isEditing = YES;
    [self setupView];
    [_tableView reloadData];
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
    
    if ([item[@"type"] isEqualToString:[OATextMultilineTableViewCell getCellIdentifier]])
    {
        OATextMultilineTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OATextMultilineTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATextMultilineTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OATextMultilineTableViewCell *) nib[0];
            [cell leftIconVisibility:NO];
            [cell clearButtonVisibility:NO];
            cell.textView.userInteractionEnabled = YES;
            cell.textView.editable = YES;
            cell.textView.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCallout];
        }
        if (cell)
        {
            NSNumber *inset = item[@"separatorInset"];
            cell.separatorInset = UIEdgeInsetsMake(0, inset.floatValue, 0, 0);
            cell.textView.delegate = self;
            cell.textView.text = item[@"title"];
            [cell.textView sizeToFit];
            [cell.textView becomeFirstResponder];
        }
        return cell;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewAutomaticDimension;
}

#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView
{
    self.desc = textView.text;
    [_tableView beginUpdates];
    [_tableView endUpdates];
}

@end
