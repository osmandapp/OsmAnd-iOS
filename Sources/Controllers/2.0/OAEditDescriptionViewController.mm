//
//  OAEditDescriptionViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 03/06/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAEditDescriptionViewController.h"
#import "Localization.h"

@interface OAEditDescriptionViewController ()

@end

@implementation OAEditDescriptionViewController
{
    CGFloat _keyboardHeight;
    BOOL _isNew;
}

-(id)initWithDescription:(NSString *)desc isNew:(BOOL)isNew
{
    self = [super init];
    if (self)
    {
        self.desc = desc;
        _isNew = isNew;
        _keyboardHeight = 0.0;
    }
    return self;
}

- (void)applyLocalization
{
    _titleView.text = OALocalizedString(@"description");
    [_backButton setTitle:OALocalizedString(@"shared_string_back") forState:UIControlStateNormal];
    [_saveButton setTitle:OALocalizedString(@"shared_string_save") forState:UIControlStateNormal];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _textView.text = self.desc;
    [self setupView];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self registerForKeyboardNotifications];
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

-(void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    _textView.frame = CGRectMake(0.0, 64.0, DeviceScreenWidth, DeviceScreenHeight - _keyboardHeight - 64.0);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)setupView
{
    _textView.textContainerInset = UIEdgeInsetsMake(5,5,5,5);
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

@end
