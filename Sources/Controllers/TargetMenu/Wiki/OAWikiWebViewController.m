//
//  OAWikiWebViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 04/06/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAWikiWebViewController.h"
#import "OAWikiLanguagesWebViewContoller.h"
#import "OARootViewController.h"
#import "OATableDataModel.h"
#import "OATableSectionData.h"
#import "OATableRowData.h"
#import "OAAppSettings.h"
#import "OADownloadMode.h"
#import "OAPlugin.h"
#import "OAPOI.h"
#import "OsmAndApp.h"
#import "OASizes.h"
#import "Localization.h"
#import <SafariServices/SafariServices.h>
#import <AFNetworking/AFNetworkReachabilityManager.h>

#define kHeaderImageHeight 170

@interface OAWikiWebViewController () <SFSafariViewControllerDelegate, OAWikiLanguagesWebDelegate>

@end

@implementation OAWikiWebViewController
{
    OsmAndAppInstance _app;
    OAPOI *_poi;
    NSLocale *_currentLocale;
    NSString *_contentLocale;
    NSString *_content;
    OATableDataModel *_data;
    UIBarButtonItem *_languageBarButtonItem;
    UIBarButtonItem *_imagesBarButtonItem;
    BOOL _isDownloadImagesOnlyNow;
}

#pragma mark - Initialization

- (instancetype)initWithPoi:(OAPOI *)poi
{
    self = [super init];
    if (self)
    {
        _poi = poi;
        [self postInit];
    }
    return self;
}

- (void)commonInit
{
    _app = [OsmAndApp instance];
}

- (void)postInit
{
    NSLocale *currentLocal = [NSLocale autoupdatingCurrentLocale];
    id localIdentifier = [currentLocal objectForKey:NSLocaleIdentifier];
    _currentLocale = [NSLocale localeWithLocaleIdentifier:localIdentifier];

    if (_poi.localizedContent.count == 1)
    {
        _contentLocale = _poi.localizedContent.allKeys.firstObject;
        _content = _poi.localizedContent.allValues.firstObject;
    }
    else
    {
        NSString *preferredMapLanguage = [[OAAppSettings sharedManager] settingPrefMapLanguage].get;
        if (!preferredMapLanguage || preferredMapLanguage.length == 0)
            preferredMapLanguage = NSLocale.currentLocale.languageCode;

        _contentLocale = [OAPlugin onGetMapObjectsLocale:_poi preferredLocale:preferredMapLanguage];
        if ([_contentLocale isEqualToString:@"en"])
            _contentLocale = @"";

        _content = _poi.localizedContent[_contentLocale];
        if (!_content)
        {
            NSArray *locales = _poi.localizedContent.allKeys;
            for (NSString *langCode in [NSLocale preferredLanguages])
            {
                if ([langCode containsString:@"-"])
                    _contentLocale = [langCode substringToIndex:[langCode indexOf:@"-"]];
                if ([locales containsObject:_contentLocale])
                {
                    _content = _poi.localizedContent[_contentLocale];
                    break;
                }
            }
            if (!_content)
                _content = _poi.localizedContent.allValues.firstObject;
        }
    }
    if (_content)
        _content = [self appendHeadToContent:_content];
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [self createLanguagesNavbarButton];
    [self createImagesNavbarButton];
    [super viewDidLoad];
}

#pragma mark - Base setup UI

- (void)addAccessibilityLabels
{
    _languageBarButtonItem.accessibilityLabel = OALocalizedString(@"select_language");
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return _poi.localizedNames[_contentLocale] ? _poi.localizedNames[_contentLocale] : OALocalizedString(@"download_wikipedia_maps");
}

- (void)createLanguagesNavbarButton
{
    UIMenu *languageMenu;
    NSMutableArray<UIMenuElement *> *languageOptions = [NSMutableArray array];
    if (_poi.localizedContent.allKeys.count > 1)
    {
        NSMutableArray<NSString *> *preferredLocales = [NSMutableArray new];
        for (NSString *langCode in [NSLocale preferredLanguages])
        {
            NSInteger index = [langCode indexOf:@"-"];
            if (index != NSNotFound && index < langCode.length)
                [preferredLocales addObject:[langCode substringToIndex:index]];
        }

        NSMutableArray<NSString *> *availableLocales = [NSMutableArray array];
        for (NSString *locale in _poi.localizedContent.allKeys)
        {
            NSString *localeKey = locale.length > 0 ? locale : @"en";
            if ([preferredLocales containsObject:localeKey])
            {
                UIAction *languageAction = [UIAction actionWithTitle:[OAUtilities translatedLangName:localeKey].capitalizedString
                                                       image:nil
                                                  identifier:nil
                                                     handler:^(__kindof UIAction * _Nonnull action) {
                    [self updateWikiData:locale];
                }];
                if ([locale isEqualToString:_contentLocale])
                    languageAction.state = UIMenuElementStateOn;
                [languageOptions addObject:languageAction];
            }
            else
            {
                [availableLocales addObject:localeKey];
            }
        }
        if (availableLocales.count > 0)
        {
            UIAction *availableLanguagesAction = [UIAction actionWithTitle:OALocalizedString(@"available_languages")
                                                                     image:[UIImage systemImageNamed:@"globe"]
                                                                identifier:nil
                                                                   handler:^(__kindof UIAction * _Nonnull action) {
                                          OAWikiLanguagesWebViewContoller *wikiLanguagesViewController = [[OAWikiLanguagesWebViewContoller alloc] initWithSelectedLocale:_contentLocale availableLocales:availableLocales];
                                          wikiLanguagesViewController.delegate = self;
                                          [self showModalViewController:wikiLanguagesViewController];
            }];
            if (![preferredLocales containsObject:_contentLocale.length == 0 ? @"en" : _contentLocale])
                availableLanguagesAction.state = UIMenuElementStateOn;
            UIMenu *availableLanguagesMenu = [UIMenu menuWithTitle:@""
                                                             image:nil
                                                        identifier:nil
                                                           options:UIMenuOptionsDisplayInline
                                                          children:@[availableLanguagesAction]];
            [languageOptions addObject:availableLanguagesMenu];
        }
        languageMenu = [UIMenu menuWithChildren:languageOptions];
    }
    _languageBarButtonItem = [self createRightNavbarButton:nil iconName:@"ic_navbar_languge" action:@selector(onLanguageNavbarButtonPressed) menu:languageMenu];
}

- (void)createImagesNavbarButton
{
    NSMutableArray<UIMenuElement *> *downloadModeOptions = [NSMutableArray array];
    NSString *selectedIconName = @"ic_navbar_image_disabled_outlined";
    NSArray<OADownloadMode *> *downloadModes = [OADownloadMode getDownloadModes];
    for (OADownloadMode *downloadMode in downloadModes)
    {
        UIAction *downloadModeAction = [UIAction actionWithTitle:downloadMode.title
                                                           image:nil
                                                      identifier:nil
                                                         handler:^(__kindof UIAction * _Nonnull action) {
            _app.data.wikipediaImagesDownloadMode = downloadMode;
            [self updateWikiData];
        }];
        if ([downloadMode isEqual:_app.data.wikipediaImagesDownloadMode])
        {
            downloadModeAction.state = _isDownloadImagesOnlyNow ? UIMenuElementStateMixed : UIMenuElementStateOn;
            selectedIconName = downloadMode.iconName;
        }
        [downloadModeOptions addObject:downloadModeAction];
    }

    UIAction *downloadOnlyNowModeAction = [UIAction actionWithTitle:OALocalizedString(@"download_only_now")
                                                              image:[UIImage systemImageNamed:@"square.and.arrow.down"]
                                                         identifier:nil
                                                            handler:^(__kindof UIAction * _Nonnull action) {
                                    OADownloadMode *imagesDownloadMode = [self getImagesDownloadMode];
                                    if ([[AFNetworkReachabilityManager sharedManager] isReachableViaWWAN] && ([imagesDownloadMode isDontDownload] || [imagesDownloadMode isDownloadOnlyViaWifi]))
                                    {
                                        UIAlertController *alert =
                                            [UIAlertController alertControllerWithTitle:OALocalizedString(@"wikivoyage_download_pics")
                                                                                message:OALocalizedString(@"download_over_cellular_network")
                                                                         preferredStyle:UIAlertControllerStyleAlert];
                                            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_cancel")
                                                                                                   style:UIAlertActionStyleDefault
                                                                                                 handler:nil];
                                            UIAlertAction *downloadAction = [UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_download")
                                                                                                     style:UIAlertActionStyleDefault
                                                                                                   handler:^(UIAlertAction * _Nonnull action) {
                                                _isDownloadImagesOnlyNow = YES;
                                                [self updateWikiData];
                                            }];
                                        [alert addAction:cancelAction];
                                        [alert addAction:downloadAction];
                                        alert.preferredAction = downloadAction;
                                        [self presentViewController:alert animated:YES completion:nil];
                                   }
                                   else if ([[AFNetworkReachabilityManager sharedManager] isReachableViaWiFi])
                                   {
                                       _isDownloadImagesOnlyNow = YES;
                                       [self updateWikiData];
                                   }
    }];
    if (_isDownloadImagesOnlyNow)
        downloadOnlyNowModeAction.state = UIMenuElementStateOn;
    UIMenu *downloadModeOnlyNow = [UIMenu menuWithTitle:@""
                                                  image:nil
                                             identifier:nil
                                                options:UIMenuOptionsDisplayInline
                                               children:@[downloadOnlyNowModeAction]];
    [downloadModeOptions addObject:downloadModeOnlyNow];

    _imagesBarButtonItem = [self createRightNavbarButton:nil
                                                iconName:selectedIconName
                                                  action:@selector(onImagesNavbarButtonPressed)
                                                    menu:[UIMenu menuWithChildren:downloadModeOptions]];
}

- (NSArray<UIBarButtonItem *> *)getRightNavbarButtons
{
    return @[_imagesBarButtonItem, _languageBarButtonItem];
}

- (EOABaseNavbarStyle)getNavbarStyle
{
    return EOABaseNavbarStyleCustomLargeTitle;
}

- (void)setupCustomLargeTitleView
{
}

- (UILayoutConstraintAxis)getBottomAxisMode
{
    return UILayoutConstraintAxisHorizontal;
}

- (NSString *)getTopButtonIconName
{
    return @"ic_custom_export_outlined";
}

- (NSString *)getBottomButtonIconName
{
    return @"ic_custom_safari";
}

- (EOABaseButtonColorScheme)getTopButtonColorScheme
{
    return EOABaseButtonColorSchemeGraySimple;
}

#pragma mark - Web Data

- (NSURL *)getUrl
{
    NSString *locale = _contentLocale.length == 0 ? @"en" : _contentLocale;
    NSString *wikipediaTitle = [self getWikipediaTitleURL];
    return [NSURL URLWithString:[NSString stringWithFormat:@"https://%@.wikipedia.org/wiki/%@", locale, wikipediaTitle]];
}

- (NSString *)getContent
{
    return _content;
}

- (OADownloadMode *)getImagesDownloadMode
{
    return _app.data.wikipediaImagesDownloadMode;
}

- (BOOL)isDownloadImagesOnlyNow
{
    return _isDownloadImagesOnlyNow;
}

- (void)resetDownloadImagesOnlyNow
{
    _isDownloadImagesOnlyNow = NO;
}

#pragma mark - Web load

- (void)loadHeaderImage:(void(^)(NSString *content))loadWebView
{
    OADownloadMode *imagesDownloadMode = [self getImagesDownloadMode];
    if (![self isDownloadImagesOnlyNow] && ([imagesDownloadMode isDontDownload] || ([imagesDownloadMode isDownloadOnlyViaWifi] && [[AFNetworkReachabilityManager sharedManager] isReachableViaWWAN])))
    {
        if (loadWebView)
            loadWebView([self getContent]);
    }
    else
    {
        NSString *locale = _contentLocale.length == 0 ? @"en" : _contentLocale;
        NSString *wikipediaTitle = [self getWikipediaTitleURL];
        NSString *titleImageLink = [NSString stringWithFormat:@"https://%@.wikipedia.org/w/api.php?action=query&titles=%@&prop=pageimages&format=json&pithumbsize=%lu",
                                    locale,
                                    wikipediaTitle,
                                    (NSInteger) self.view.frame.size.width];
        NSURL *titleImageURL = [NSURL URLWithString:titleImageLink];
        NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
        [[session dataTaskWithURL:titleImageURL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            NSString *content = [self getContent];
            NSString *imageSource = @"";
            if (((NSHTTPURLResponse *) response).statusCode == 200 && data)
            {
                if (data)
                {
                    NSDictionary *result = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
                    if ([result.allKeys containsObject:@"query"])
                    {
                        NSDictionary *queryResult = result[@"query"];
                        if ([queryResult.allKeys containsObject:@"pages"])
                        {
                            NSDictionary *pagesResult = queryResult[@"pages"];
                            if (pagesResult.allKeys.count > 0)
                            {
                                NSDictionary *sourceResult = pagesResult[pagesResult.allKeys.firstObject];
                                if ([sourceResult.allKeys containsObject:@"thumbnail"])
                                {
                                    NSDictionary *thumbnailResult = sourceResult[@"thumbnail"];
                                    imageSource = thumbnailResult[@"source"];
                                }
                            }
                        }
                    }
                }
                if (imageSource && imageSource.length > 0)
                {
                    content = [content stringByReplacingOccurrencesOfString:@"</header>"
                                                                 withString:[NSString stringWithFormat:@"<img src=%@ style=\"object-fit:cover; object-position:center; height:%dpx;\"></header>", imageSource, kHeaderImageHeight]];
                }
            }
            if (loadWebView)
                loadWebView(content);
        }] resume];
    }
}

#pragma mark - Selectors

- (void)onLanguageNavbarButtonPressed
{
    if (_poi.localizedContent.allKeys.count <= 1)
    {
        [OARootViewController showInfoAlertWithTitle:nil
                                             message:OALocalizedString(@"no_other_translations")
                                        inController:self];
        return;
    }
}

- (void)onImagesNavbarButtonPressed
{
}

- (void)onTopButtonPressed
{
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[[self getUrl]]
                                                                                         applicationActivities:nil];
    activityViewController.popoverPresentationController.sourceView = self.view;
    activityViewController.popoverPresentationController.sourceRect = self.topButton.frame;
    [self.navigationController presentViewController:activityViewController animated:YES completion:nil];
}

- (void)onBottomButtonPressed
{
    NSURL *url = [self getUrl];
    if (url)
    {
        SFSafariViewController *safariViewController = [[SFSafariViewController alloc] initWithURL:url];
        [self presentViewController:safariViewController animated:YES completion:nil];
    }
}

#pragma mark - UIScrollViewDelegate

- (CGFloat)getCustomTitleHeaderTopOffset
{
    OADownloadMode *imagesDownloadMode = [self getImagesDownloadMode];
    if (![self isDownloadImagesOnlyNow] && ([imagesDownloadMode isDontDownload] || ([imagesDownloadMode isDownloadOnlyViaWifi] && [[AFNetworkReachabilityManager sharedManager] isReachableViaWWAN])))
        return 0.;

    return kHeaderImageHeight;
}

#pragma mark - Additions

- (NSString *)getWikipediaTitleURL
{
    NSString *title = [self getTitle];
    BOOL hasLocalizedName = ![title isEqualToString:OALocalizedString(@"download_wikipedia_maps")];
    return !hasLocalizedName ? @"" : [[title stringByReplacingOccurrencesOfString:@" "
                                                                       withString:@"_"]
                                      stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet];
}

- (void)updateWikiData
{
    [self updateWikiData:_contentLocale];
}

- (void)updateWikiData:(NSString *)locale
{
    NSString *content = [self appendHeadToContent:_poi.localizedContent[locale]];
    if (content)
    {
        _contentLocale = locale;
        _content = content;
        [self createLanguagesNavbarButton];
        [self createImagesNavbarButton];
        [UIView transitionWithView:self.view
                          duration:.2
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^(void)
                        {
                            [self updateNavbar];
                            [self applyLocalization];
                            [self loadWebView];
                        }
                        completion:nil];
    }
}

- (NSString *)appendHeadToContent:(NSString *)content
{
    if (content == nil)
        return nil;

    NSString *head = @"<header><meta name='viewport' content='width=device-width, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0, user-scalable=no'></header><head></head><div class=\"main\">%@</div>";
    return [NSString stringWithFormat:head, content];
}

#pragma mark - WebView

- (void)webViewDidCommitted:(void(^)(void))onViewCommitted
{
    BOOL containsRTL = [[OAAppSettings sharedManager].rtlLanguages containsObject:_contentLocale];
    NSString *path = [[NSBundle mainBundle] pathForResource:@"article_style" ofType:@"css"];
    NSString *cssContents = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    cssContents = [cssContents stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
    NSString *javascriptWithCSSString = [NSString stringWithFormat:kLargeTitleJS, cssContents, [[self getTitle] stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"]];
    [self.webView evaluateJavaScript:kCollapseJS completionHandler:nil];
    [self.webView evaluateJavaScript:javascriptWithCSSString completionHandler:^(id _Nullable object, NSError * _Nullable error) {
        if (!containsRTL && onViewCommitted)
            onViewCommitted();
    }];
    if (containsRTL)
        [self.webView evaluateJavaScript:kRtlJS completionHandler:^(id _Nullable object, NSError * _Nullable error) {
            if (onViewCommitted)
                onViewCommitted();
        }];
}

#pragma mark - SFSafariViewControllerDelegate

- (void)safariViewControllerDidFinish:(SFSafariViewController *)controller
{
    [controller dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - OAWikiLanguagesWebDelegate

- (void)onLocaleSelected:(NSString *)locale
{
    [self updateWikiData:locale];
}

@end
