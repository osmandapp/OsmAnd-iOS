//
//  OAWikiMenuViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 04/06/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAWikiMenuViewController.h"

@interface OAWikiMenuViewController ()

@end

@implementation OAWikiMenuViewController
{
    NSString *_content;
}

- (id)initWithContent:(NSString *)content
{
    self = [super init];
    if (self)
    {
        _content = content;
    }
    return self;
}


- (CGFloat)contentHeight
{
    return 148.0;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (_content)
        [self.webView loadHTMLString:_content baseURL:nil];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doTap)];
    [self.contentView addGestureRecognizer:tapGesture];
}

- (void)doTap
{
    if (self.menuDelegate && [self.menuDelegate respondsToSelector:@selector(openWiki:)])
        [self.menuDelegate openWiki:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
