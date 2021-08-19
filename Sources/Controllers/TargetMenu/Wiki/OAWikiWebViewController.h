//
//  OAWikiWebViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 04/06/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OACompoundViewController.h"

#import <WebKit/WebKit.h>

@class OAPOI;

@interface OAWikiWebViewController : OACompoundViewController

@property (weak, nonatomic) IBOutlet UIView *navBar;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIButton *buttonBack;
@property (weak, nonatomic) IBOutlet UIButton *localeButton;
@property (weak, nonatomic) IBOutlet WKWebView *contentView;
@property (weak, nonatomic) IBOutlet UIView *bottomView;
@property (weak, nonatomic) IBOutlet UIButton *bottomButton;

- (id)initWithPoi:(OAPOI *)poi;

@end
