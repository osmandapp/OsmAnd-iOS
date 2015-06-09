//
//  OAWikiMenuViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 04/06/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OATargetMenuViewController.h"

@class OAWikiMenuViewController;

@protocol OAWikiMenuDelegate <NSObject>

@optional
- (void)openWiki:(OAWikiMenuViewController *)sender;

@end

@interface OAWikiMenuViewController : OATargetMenuViewController

@property (weak, nonatomic) IBOutlet UIWebView *webView;

@property (weak, nonatomic) id<OAWikiMenuDelegate> menuDelegate;

- (id)initWithContent:(NSString *)content;

@end
