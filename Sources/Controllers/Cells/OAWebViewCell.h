//
//  OAWebViewCell.h
//  OsmAnd
//
//  Created by Alexey Kulish on 26/05/16.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

@interface OAWebViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *iconView;
@property (weak, nonatomic) IBOutlet UIImageView *arrowIconView;
@property (weak, nonatomic) IBOutlet WKWebView *webView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *webViewLeftConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *webViewRightConstraint;

@end
