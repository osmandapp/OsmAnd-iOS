//
//  OAWikiWebViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 04/06/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAWikiWebViewController.h"
#import "OARootViewController.h"
#import "Localization.h"
#import "OAAppSettings.h"
#import "OASizes.h"
#import "OAPlugin.h"
#import "OAPOI.h"

NSString * COLLAPSE_JS = @"var script = document.createElement('script'); script.text = \"var coll = document.getElementsByTagName(\'H2\'); var i; for (i = 0; i < coll.length; i++){   coll[i].addEventListener(\'click\', function() { this.classList.toggle(\'active\'); var content = this.nextElementSibling; if (content.style.display === \'block\') { content.style.display = \'none\'; } else { content.style.display = \'block\';}}); } \"; document.head.appendChild(script);";

@interface OAWikiWebViewController () <WKNavigationDelegate>

@end

@implementation OAWikiWebViewController
{
    OAPOI *_poi;
    NSString *_contentLocale;
    NSLocale *_currentLocale;

    NSURL *_baseUrl;

    CALayer *_horizontalLine;
}

- (id)initWithPoi:(OAPOI *)poi
{
    self = [super init];
    if (self)
    {
        _poi = poi;
    }
    return self;
}

-(void)applyLocalization
{
    [_bottomButton setTitle:OALocalizedString(@"open_url") forState:UIControlStateNormal];
}

- (NSString *) getLocalizedTitle
{
    return _poi.localizedNames[_contentLocale] ? _poi.localizedNames[_contentLocale] : @"Wikipedia";
}

- (void)viewDidLoad
{
    // did load
    [super viewDidLoad];
    
    NSLocale *currentLocal = [NSLocale autoupdatingCurrentLocale];
    id localIdentifier = [currentLocal objectForKey:NSLocaleIdentifier];
    _currentLocale = [NSLocale localeWithLocaleIdentifier:localIdentifier];

    _horizontalLine = [CALayer layer];
    _horizontalLine.backgroundColor = [UIColorFromRGB(kBottomToolbarTopLineColor) CGColor];
    self.bottomView.backgroundColor = UIColorFromRGB(kBottomToolbarBackgroundColor);
    [self.bottomView.layer addSublayer:_horizontalLine];

    NSString *content;
    if (_poi.localizedContent.count == 1)
    {
        _contentLocale = _poi.localizedContent.allKeys.firstObject;
        content = _poi.localizedContent.allValues.firstObject;
    }
    else
    {
        NSString *preferredMapLanguage = [[OAAppSettings sharedManager] settingPrefMapLanguage].get;
        if (!preferredMapLanguage || preferredMapLanguage.length == 0)
            preferredMapLanguage = NSLocale.currentLocale.languageCode;

        _contentLocale = [OAPlugin onGetMapObjectsLocale:_poi preferredLocale:preferredMapLanguage];
        if ([_contentLocale isEqualToString:@"en"])
            _contentLocale = @"";

        content = _poi.localizedContent[_contentLocale];
        if (!content)
        {
            NSArray *locales = _poi.localizedContent.allKeys;
            for (NSString *langCode in [NSLocale preferredLanguages])
            {
                if ([langCode containsString:@"-"])
                    _contentLocale = [langCode substringToIndex:[langCode indexOf:@"-"]];
                if ([locales containsObject:_contentLocale])
                {
                    content = _poi.localizedContent[_contentLocale];
                    break;
                }
            }
            if (!content)
                content = _poi.localizedContent.allValues.firstObject;
        }
    }

    _titleView.text = [self getLocalizedTitle];
    
    NSString *locBtnStr = (_contentLocale.length == 0 ? @"EN" : [_contentLocale uppercaseString]);
    [_localeButton setTitle:locBtnStr forState:UIControlStateNormal];
    
    [self buildBaseUrl];
    _contentView.navigationDelegate = self;
    if (content)
    {
        content = [self appendHeadToContent:content];
        [_contentView loadHTMLString:content baseURL:_baseUrl];
    }
    [self applySafeAreaMargins];
}

-(UIView *) getTopView
{
    return _navBar;
}

-(UIView *) getMiddleView
{
    return _contentView;
}

-(UIView *) getBottomView
{
    return _bottomView;
}

-(CGFloat) getToolBarHeight
{
    return wikiBottomViewHeight;
}

- (void) buildBaseUrl
{
    _baseUrl = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@.wikipedia.org/wiki/%@", (_contentLocale.length == 0 ? @"en" : _contentLocale), [_titleView.text isEqualToString:@"Wikipedia"] ? @"" : [[_titleView.text stringByReplacingOccurrencesOfString:@" " withString:@"_"] stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet]]];
    
    //NSLog(@"baseUrl=%@", _baseUrl);
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    _horizontalLine.frame = CGRectMake(0.0, 0.0, DeviceScreenWidth, 0.5);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)bottomButtonClicked:(id)sender
{
    if (_baseUrl)
        [[UIApplication sharedApplication] openURL:_baseUrl];
}

- (NSString *)getTranslatedLangName:(NSString *)lang
{
    return [_currentLocale displayNameForKey:NSLocaleIdentifier value:lang];
}

- (IBAction)localeButtonClicked:(id)sender
{
    if (_poi.localizedContent.allKeys.count <= 1)
    {
        [OARootViewController showInfoAlertWithTitle:nil
                                             message:OALocalizedString(@"no_other_translations")
                                        inController:self];
        return;
    }

    UIAlertController *alert = [UIAlertController
            alertControllerWithTitle:OALocalizedString(@"select_language")
                             message:nil
                      preferredStyle:UIAlertControllerStyleActionSheet];

    NSMutableArray<NSString *> *locales = [_poi.localizedContent.allKeys mutableCopy];
    [locales sortUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
        return [obj1 compare:obj2];
    }];

    for (NSString *locale in locales)
    {
        NSString *translate = [[self getTranslatedLangName:locale.length > 0 ? locale : @"en"]
                               capitalizedStringWithLocale:[NSLocale currentLocale]];
        if (translate)
        {
            [alert addAction:[UIAlertAction
                    actionWithTitle:translate
                              style:UIAlertActionStyleDefault
                            handler:^(UIAlertAction *action) {
                                _contentLocale = locale;

                                NSString *locBtnStr = (_contentLocale.length == 0 ? @"EN" : [_contentLocale uppercaseString]);
                                [_localeButton setTitle:locBtnStr forState:UIControlStateNormal];

                                _titleView.text = (_poi.localizedNames[_contentLocale]
                                        ? _poi.localizedNames[_contentLocale]
                                        : @"Wikipedia");

                                [self buildBaseUrl];
                                NSString *content = [self appendHeadToContent:_poi.localizedContent[_contentLocale]];
                                if (content)
                                    [_contentView loadHTMLString:content baseURL:_baseUrl];
                            }]];
        }
    }
    [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_cancel")
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (NSString *) appendHeadToContent:(NSString *) content
{
    if (content == nil)
    {
        return nil;
    }
    NSString *head = @"<header><meta name='viewport' content='width=device-width, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0, user-scalable=no'></header><head></head><div class=\"main\">%@</div>";
    return [NSString stringWithFormat:head, content];
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"article_style" ofType:@"css"];
    NSString *cssContents = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    cssContents = [cssContents stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
    NSString *javascriptString = @"var style = document.createElement('style'); style.innerHTML = '%@'; document.head.appendChild(style); var title = document.createElement('H1'); title.innerHTML = '%@'; var main = document.getElementsByClassName('main')[0]; main.insertAdjacentElement('afterbegin', title);";
    NSString *javascriptWithCSSString = [NSString stringWithFormat:javascriptString, cssContents, [[self getLocalizedTitle] stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"]];
    [webView evaluateJavaScript:COLLAPSE_JS completionHandler:nil];
    [webView evaluateJavaScript:javascriptWithCSSString completionHandler:nil];
    if ([[OAAppSettings sharedManager].rtlLanguages containsObject:_contentLocale])
    {
        NSString *appendRtl = @"document.body.setAttribute('dir', 'rtl');";
        [webView evaluateJavaScript:appendRtl completionHandler:nil];
    }
}

@end
