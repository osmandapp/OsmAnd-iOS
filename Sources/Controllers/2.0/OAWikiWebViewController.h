//
//  OAWikiWebViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 04/06/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OACompoundViewController.h"

@interface OAWikiWebViewController : OACompoundViewController

@property (weak, nonatomic) IBOutlet UIView *navBar;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIButton *buttonBack;
@property (weak, nonatomic) IBOutlet UIButton *localeButton;
@property (weak, nonatomic) IBOutlet UIWebView *contentView;
@property (weak, nonatomic) IBOutlet UIView *bottomView;
@property (weak, nonatomic) IBOutlet UIButton *bottomButton;

@property (nonatomic, readonly) NSDictionary *localizedNames;
@property (nonatomic, readonly) NSDictionary *localizedContent;

- (id)initWithLocalizedContent:(NSDictionary *)localizedContent localizedNames:(NSDictionary *)localizedNames;

@end
