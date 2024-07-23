//
//  OABaseWebViewController.h
//  OsmAnd
//
//  Created by Skalii on 06.03.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OABaseButtonsViewController.h"
#import <WebKit/WebKit.h>

#define kLargeTitleJS @"var style = document.createElement('style'); style.innerHTML = '%@'; document.head.appendChild(style); var title = document.createElement('H1'); title.innerHTML = '%@'; var main = document.getElementsByClassName('main')[0]; main.insertAdjacentElement('afterbegin', title);"
#define kCollapseJS @"var script = document.createElement('script'); script.text = \"var coll = document.getElementsByTagName(\'H2\'); var i; for (i = 0; i < coll.length; i++){   coll[i].addEventListener(\'click\', function() { this.classList.toggle(\'active\'); var content = this.nextElementSibling; if (content.style.display === \'block\') { content.style.display = \'none\'; } else { content.style.display = \'block\';}}); } \"; document.head.appendChild(script);"
#define kRtlJS @"document.body.setAttribute('dir', 'rtl');"
#define kImagesBlockRules @" [{ \"trigger\": { \"url-filter\": \".*\", \"resource-type\": [\"image\"] }, \"action\": { \"type\": \"block\" } }] "

@class OADownloadMode;

@interface OABaseWebViewController : OABaseButtonsViewController <WKNavigationDelegate>

@property (weak, nonatomic) IBOutlet WKWebView *webView;

- (NSURL *)getUrl;
- (NSString *)getContent;
- (OADownloadMode *)getImagesDownloadMode;
- (BOOL)isDownloadImagesOnlyNow;
- (void)setDownloadImagesOnlyNow:(BOOL)onlyNow;

- (void)loadHeaderImage:(void(^)(NSString *content))loadWebView;
- (void)loadWebView;
- (void)webViewDidCommitted:(void(^)(void))onViewCommitted;

@end
