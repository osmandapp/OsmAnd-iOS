//
//  OAWikiArticleHelper.h
//  OsmAnd
//
//  Created by Paul on 03.03.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kPagePrefixHttp @"http://"
#define kPagePrefixHttps @"https://"
#define kPagePrefixFile @"file://"
#define kWikiDomain @".wikipedia.org/wiki/"
#define kWikiDomainCom @".wikipedia.com/wiki/"
#define kWikivoyageDomain @".wikivoyage.org/wiki/"

typedef void(^OAWikiArticleSearchTaskBlockType)(void);

@class OAWorldRegion, OAPOI;

@interface OAWikiArticleSearchTask : NSObject

- (instancetype) initWithLocations:(NSArray<CLLocation *> *)locations url:(NSString *)url onStart:(void (^)())onStart sourceView:(UIView *)sourceView onComplete:(void (^)())onComplete;
- (void) execute;
- (void) cancel;

@end

@protocol OAWikiLanguagesWebDelegate

- (void)onLocaleSelected:(NSString *)locale;
- (void)showLocalesVC:(UIViewController *)vc;

@end


@interface OAWikiArticleHelper : NSObject

+ (OAWorldRegion *) findWikiRegion:(OAWorldRegion *)mapRegion;
+ (void) showWikiArticle:(CLLocation *)location url:(NSString *)url sourceView:(UIView *)sourceView;
+ (void) showWikiArticle:(NSArray<CLLocation *> *)locations url:(NSString *)url onStart:(void (^)())onStart sourceView:(UIView *)sourceView onComplete:(void (^)())onComplete;
+ (NSString *) getFirstParagraph:(NSString *)descriptionHtml;
+ (NSString *) getPartialContent:(NSString *)source;
+ (void) warnAboutExternalLoad:(NSString *)url sourceView:(UIView *)sourceView;
+ (NSString *) normalizeFileUrl:(NSString *)url;
+ (NSString *) getLang:(NSString *)url;
+ (NSString *) getArticleNameFromUrl:(NSString *)url lang:(NSString *)lang;
+ (UIMenu *)createLanguagesMenu:(NSArray<NSString *> *)availableLocales selectedLocale:(NSString *)selectedLocale delegate:(id<OAWikiLanguagesWebDelegate>)delegate;

@end
