//
//  OAWebViewController.h
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 27.11.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OACompoundViewController.h"

#import <WebKit/WebKit.h>

@interface OAWebViewController : OACompoundViewController
@property (weak, nonatomic) IBOutlet UIView *navBarView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet WKWebView *webView;

@property NSString* urlString;

-(id)initWithUrl:(NSString*)url;
-(id)initWithUrlAndTitle:(NSString*)url title:(NSString *) title;

@end
