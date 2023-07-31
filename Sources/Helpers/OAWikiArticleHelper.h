//
//  OAWikiArticleHelper.h
//  OsmAnd
//
//  Created by Paul on 03.03.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAResourcesBaseViewController.h"
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

- (instancetype) initWithLocations:(NSArray<CLLocation *> *)locations url:(NSString *)url onStart:(void (^)())onStart sourceView:(UIView *)sourceView sourceFrame:(CGRect)sourceFrame onComplete:(void (^)())onComplete;
- (void) execute;
- (void) cancel;

@end


@interface OAWikiArticleHelper : NSObject

+ (OAWorldRegion *) findWikiRegion:(OAWorldRegion *)mapRegion;
+ (OARepositoryResourceItem *) findResourceItem:(OAWorldRegion *)worldRegion;
+ (void) showWikiArticle:(CLLocation *)location url:(NSString *)url sourceView:(UIView *)sourceView sourceFrame:(CGRect)sourceFrame;
+ (void) showWikiArticle:(NSArray<CLLocation *> *)locations url:(NSString *)url onStart:(void (^)())onStart sourceView:(UIView *)sourceView sourceFrame:(CGRect)sourceFrame onComplete:(void (^)())onComplete;
+ (void) showHowToOpenWikiAlert:(OARepositoryResourceItem *)item url:(NSString *)url sourceView:(UIView *)sourceView sourceFrame:(CGRect)sourceFrame;
+ (NSString *) getFirstParagraph:(NSString *)descriptionHtml;
+ (NSString *) getPartialContent:(NSString *)source;
+ (void) warnAboutExternalLoad:(NSString *)url;
+ (NSString *) normalizeFileUrl:(NSString *)url;
+ (NSString *) getLang:(NSString *)url;
+ (NSString *) getArticleNameFromUrl:(NSString *)url lang:(NSString *)lang;

@end
