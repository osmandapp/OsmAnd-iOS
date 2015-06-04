//
//  OAWikiWebViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 04/06/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAWikiWebViewController.h"
#import "Localization.h"

@interface OAWikiWebViewController ()

@end

@implementation OAWikiWebViewController

- (id)initWithLocalizedContent:(NSDictionary *)localizedContent
{
    self = [super init];
    if (self)
    {
        _localizedContent = localizedContent;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.buttonBack setTitle:OALocalizedString(@"shared_string_back") forState:UIControlStateNormal];

    NSString *content = [self.localizedContent objectForKey:[[NSLocale preferredLanguages] firstObject]];
    if (!content)
        content = [self.localizedContent objectForKey:@""];
    
    if (content)
        [_contentView loadHTMLString:content baseURL:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
