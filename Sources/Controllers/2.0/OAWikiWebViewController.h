//
//  OAWikiWebViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 04/06/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OASuperViewController.h"

@interface OAWikiWebViewController : OASuperViewController

@property (weak, nonatomic) IBOutlet UIView *navBar;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIButton *buttonBack;
@property (weak, nonatomic) IBOutlet UIWebView *contentView;

@property (nonatomic, readonly) NSDictionary *localizedContent;

- (id)initWithLocalizedContent:(NSDictionary *)localizedContent;

@end
