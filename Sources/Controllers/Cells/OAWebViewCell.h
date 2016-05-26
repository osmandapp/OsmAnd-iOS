//
//  OAWebViewCell.h
//  OsmAnd
//
//  Created by Alexey Kulish on 26/05/16.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OAWebViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *iconView;
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UIImageView *arrowIconView;

@end
