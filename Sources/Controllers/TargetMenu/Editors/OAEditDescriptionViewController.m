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
#import "OAIconTitleValueCell.h"
#import "OAWebViewCell.h"

@interface OAEditDescriptionViewController () <WKNavigationDelegate>

@end

@implementation OAEditDescriptionViewController
{
    CGFloat _keyboardHeight;
    BOOL _isNew;
    BOOL _readOnly;
    BOOL _isEditing;
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

- (void)applyLocalization
{
    _titleView.text = OALocalizedString(@"description");
    [_saveButton setTitle:OALocalizedString(@"shared_string_save") forState:UIControlStateNormal];
    [_backButton setTitle:OALocalizedString(@"shared_string_back") forState:UIControlStateNormal];
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
    return res;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupView];

    NSString *textHtml;
    if (![self isHtml:self.desc])
    {
        textHtml = [self.desc stringByReplacingOccurrencesOfString:@"\n" withString:@"<br/>"];
        textHtml = [NSString stringWithFormat:@"<p><font size=\"6\" face=\"-apple-system\"> %@ </font></p>", textHtml];
    }
    else
    {
        textHtml = self.desc;
    }
    [_webView loadHTMLString:textHtml baseURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]]];
    _textView.text = self.desc;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self registerForKeyboardNotifications];
    [self applySafeAreaMargins];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (_isNew)
        [self.textView becomeFirstResponder];
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
    return _webView;
}

-(void)setupView
{
    _textView.textContainerInset = UIEdgeInsetsMake(5,5,5,5);
    
    
    if (_isEditing)
    {
        _saveButton.hidden = NO;
        _editButton.hidden = YES;
        _textView.hidden = NO;
        _webView.hidden = YES;
        _toolbarView.backgroundColor = UIColorFromRGB(color_bottom_sheet_background);
        _titleView.textColor = UIColor.blackColor;
        _saveButton.tintColor = UIColorFromRGB(color_primary_purple);
        _backButton.tintColor = UIColorFromRGB(color_primary_purple);
        [_backButton setTitle:@"" forState:UIControlStateNormal];
        [_backButton setImage:[UIImage templateImageNamed:@"ic_navbar_close"] forState:UIControlStateNormal];
    }
    else
    {
        _editButton.hidden = _readOnly;
        _saveButton.hidden = YES;
        _textView.hidden = YES;
        _webView.hidden = NO;
        _toolbarView.backgroundColor = UIColorFromRGB(color_chart_orange);
        _titleView.textColor = UIColor.whiteColor;
        _backButton.tintColor = UIColor.whiteColor;
        [_backButton setTitle:OALocalizedString(@"shared_string_back") forState:UIControlStateNormal];
        [_backButton setImage:[UIImage templateImageNamed:@"ic_navbar_chevron"] forState:UIControlStateNormal];
        if ([self.view isDirectionRTL])
            _backButton.imageView.image = _backButton.imageView.image.imageFlippedForRightToLeftLayoutDirection;
    }
    _textView.editable = !_readOnly;
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
    self.desc = _textView.text;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(descriptionChanged)])
        [self.delegate descriptionChanged];
    
    [self backButtonClicked:self];
}

- (IBAction)editClicked:(id)sender
{
    _isEditing = YES;
    [self setupView];
    [_textView becomeFirstResponder];
}

@end
