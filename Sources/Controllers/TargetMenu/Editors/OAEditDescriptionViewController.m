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
#import "GeneratedAssetSymbols.h"

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
    self.tableView.backgroundColor = [UIColor colorNamed:ACColorNameViewBg];
    
    [self setupView];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [self setupNavigationBar];
    [self registerForKeyboardNotifications];
    [self applySafeAreaMargins];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [self.navigationController setNavigationBarHidden:YES animated:YES];
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

-(void)setupNavigationBar
{
    self.navigationItem.title = _isEditing ? OALocalizedString(@"context_menu_edit_descr") : _isComment ? OALocalizedString(@"poi_dialog_comment") : OALocalizedString(@"shared_string_description");
    UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
    [appearance configureWithOpaqueBackground];
    appearance.backgroundColor = _isEditing ? self.tableView.backgroundColor : [UIColor colorNamed:ACColorNameNavBarBgColorPrimary];
    appearance.titleTextAttributes = @{
        NSFontAttributeName : [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline],
        NSForegroundColorAttributeName : _isEditing ? [UIColor colorNamed:ACColorNameTextColorPrimary] : [UIColor colorNamed:ACColorNameNavBarTextColorPrimary]
    };
    UINavigationBarAppearance *blurAppearance = [[UINavigationBarAppearance alloc] init];

    self.navigationController.navigationBar.standardAppearance = blurAppearance;
    self.navigationController.navigationBar.scrollEdgeAppearance = appearance;
    self.navigationController.navigationBar.tintColor = _isEditing ? [UIColor colorNamed:ACColorNameIconColorActive] : [UIColor colorNamed:ACColorNameNavBarTextColorPrimary];
    self.navigationController.navigationBar.prefersLargeTitles = NO;
    
    if (_isEditing)
    {
        UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithImage:[UIImage templateImageNamed:@"ic_navbar_close"] style:UIBarButtonItemStylePlain target:self action:@selector(onLeftNavbarButtonPressed)];
        [self.navigationController.navigationBar.topItem setLeftBarButtonItem:cancelButton animated:YES];
        
        UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithTitle:OALocalizedString(@"shared_string_save") style:UIBarButtonItemStylePlain target:self action:@selector(saveClicked)];
        [self.navigationController.navigationBar.topItem setRightBarButtonItem:saveButton animated:YES];
    }
    else
    {
        if (!_readOnly)
        {
            UIBarButtonItem *editButton = [[UIBarButtonItem alloc] initWithImage:[UIImage templateImageNamed:@"ic_navbar_pencil"] style:UIBarButtonItemStylePlain target:self action:@selector(editClicked)];
            [self.navigationController.navigationBar.topItem setRightBarButtonItem:editButton animated:YES];
        }
        [self.navigationController.navigationBar.topItem setLeftBarButtonItem:nil animated:YES];
    }
}

-(UIView *) getMiddleView
{
    return _tableView;
}

-(void)setupView
{
    [self generateData];
    if (_isEditing)
        _webView.hidden = YES;
    else
        _webView.hidden = NO;
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
    return [[ThemeManager shared] isLightTheme] ? UIStatusBarStyleDarkContent : UIStatusBarStyleLightContent;
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

- (void)saveClicked
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(descriptionChanged:)])
        [self.delegate descriptionChanged:self.desc];

    [self dismissViewController];
}

- (void)editClicked
{
    _isEditing = YES;
    [self setupView];
    [self setupNavigationBar];
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
