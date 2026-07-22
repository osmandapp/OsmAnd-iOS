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

typedef void (^OAWikiArticleSearchTaskBlockType)(void);

@class OAWorldRegion, OAPOI;

NS_ASSUME_NONNULL_BEGIN

@interface OAWikiArticleSearchTask : NSObject

- (instancetype)initWithLocations:(NSArray<CLLocation *> *)locations
                               url:(NSString *)url
                           onStart:(nullable OAWikiArticleSearchTaskBlockType)onStart
                        sourceView:(nullable UIView *)sourceView
                        onComplete:(nullable OAWikiArticleSearchTaskBlockType)onComplete;
- (void) execute;
- (void) cancel;

@end

@protocol OAWikiLanguagesWebDelegate

- (void)onLocaleSelected:(NSString *_Null_unspecified)locale;
- (void)showLocalesVC:(UIViewController *_Null_unspecified)vc;

@end


@interface OAWikiArticleHelper : NSObject

+ (nullable OAWorldRegion *) findWikiRegion:(nullable OAWorldRegion *)mapRegion;
+ (void) showWikiArticle:(CLLocation *)location url:(NSString *)url sourceView:(nullable UIView *)sourceView;
+ (void) showWikiArticle:(NSArray<CLLocation *> *)locations
                     url:(NSString *)url
                 onStart:(nullable OAWikiArticleSearchTaskBlockType)onStart
              sourceView:(nullable UIView *)sourceView
              onComplete:(nullable OAWikiArticleSearchTaskBlockType)onComplete;
+ (nullable NSString *) getFirstParagraph:(nullable NSString *)descriptionHtml;
+ (nullable NSString *) getPartialContent:(nullable NSString *)source;
+ (void) warnAboutExternalLoad:(NSString *)url sourceView:(nullable UIView *)sourceView;
+ (NSString *) normalizeFileUrl:(NSString *)url;
+ (nullable NSString *) getLang:(NSString *)url;
+ (nullable NSString *) getArticleNameFromUrl:(NSString *)url lang:(NSString *)lang;
+ (nullable NSString *) readArchiveString:(nullable NSData *)archiveData;
+ (nullable UIMenu *)createLanguagesMenu:(nullable NSArray<NSString *> *)availableLocales selectedLocale:(nullable NSString *)selectedLocale delegate:(id<OAWikiLanguagesWebDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END
