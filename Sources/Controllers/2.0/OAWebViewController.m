//
//  OAWebViewController.m
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 27.11.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAWebViewController.h"
#import "Localization.h"

@interface OAWebViewController ()

@end

@implementation OAWebViewController
{
    NSString *_title;
}

-(id)initWithUrl:(NSString*)url {
    self = [super init];
    if (self) {
        self.urlString = url;
    }
    return self;
}

-(id)initWithUrlAndTitle:(NSString*)url title:(NSString *) title
{
    self = [super init];
    if (self) {
        self.urlString = url;
        _title = title;
    }
    return self;
}

-(void)applyLocalization
{
    _titleLabel.text = _title ? _title : OALocalizedString(@"help_quiz");
    [_backButton setTitle:OALocalizedString(@"shared_string_back") forState:UIControlStateNormal];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self applySafeAreaMargins:self.view.frame.size];
}

-(UIView *) getTopView
{
    return _navBarView;
}

-(UIView *) getMiddleView
{
    return _webView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    NSURL *websiteUrl = [NSURL URLWithString:self.urlString];
    if ([websiteUrl.scheme isEqualToString:@"file"]) {
        NSString* content = [NSString stringWithContentsOfFile:websiteUrl.path
                                                      encoding:NSUTF8StringEncoding
                                                         error:NULL];
        [_webView loadHTMLString:content baseURL:[NSURL URLWithString:@"https://osmand.net/"]];
    }
    else
    {
        NSURLRequest *urlRequest = [NSURLRequest requestWithURL:websiteUrl];
        [_webView loadRequest:urlRequest];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}





@end
