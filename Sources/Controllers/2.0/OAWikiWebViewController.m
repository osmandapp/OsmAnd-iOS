//
//  OAWikiWebViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 04/06/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAWikiWebViewController.h"
#import "Localization.h"
#import "OAAppSettings.h"
#import "OAUtilities.h"
#import "OASizes.h"

NSString * COLLAPSE_JS = @"var script = document.createElement('script'); script.text = \"var coll = document.getElementsByTagName(\'H2\'); var i; for (i = 0; i < coll.length; i++){   coll[i].addEventListener(\'click\', function() { this.classList.toggle(\'active\'); var content = this.nextElementSibling; if (content.style.display === \'block\') { content.style.display = \'none\'; } else { content.style.display = \'block\';}}); } \"; document.head.appendChild(script);";

@interface OAWikiWebViewController () <UIActionSheetDelegate, WKNavigationDelegate>

@end

@implementation OAWikiWebViewController
{
    NSArray *_namesSorted;
    NSString *_contentLocale;
    NSURL *_baseUrl;
    
    CALayer *_horizontalLine;
    
    NSLocale *_currentLocal;
    id _localIdentifier;
    NSLocale *_theLocal;
}

- (id)initWithLocalizedContent:(NSDictionary *)localizedContent localizedNames:(NSDictionary *)localizedNames
{
    self = [super init];
    if (self)
    {
        _localizedNames = localizedNames;
        _localizedContent = localizedContent;
    }
    return self;
}

-(void)applyLocalization
{
    [_bottomButton setTitle:OALocalizedString(@"open_url") forState:UIControlStateNormal];
}

- (NSString *) getLocalizedTitle
{
    return [self.localizedNames objectForKey:_contentLocale] ? [self.localizedNames objectForKey:_contentLocale] : @"Wikipedia";
}

- (void)viewDidLoad
{
    // did load
    [super viewDidLoad];
    
    _currentLocal = [NSLocale autoupdatingCurrentLocale];
    _localIdentifier = [_currentLocal objectForKey:NSLocaleIdentifier];
    _theLocal = [NSLocale localeWithLocaleIdentifier:_localIdentifier];

    _horizontalLine = [CALayer layer];
    _horizontalLine.backgroundColor = [UIColorFromRGB(kBottomToolbarTopLineColor) CGColor];
    self.bottomView.backgroundColor = UIColorFromRGB(kBottomToolbarBackgroundColor);
    [self.bottomView.layer addSublayer:_horizontalLine];
    
    _contentLocale = [OAAppSettings sharedManager].settingPrefMapLanguage.get;
    if (!_contentLocale)
        _contentLocale = [OAUtilities currentLang];
    
    NSString *content = [self.localizedContent objectForKey:_contentLocale];
    if (!content)
    {
        _contentLocale = @"";
        content = [self.localizedContent objectForKey:_contentLocale];
    }
    if (!content && self.localizedContent.count > 0)
    {
        _contentLocale = self.localizedContent.allKeys[0];
        content = [self.localizedContent objectForKey:_contentLocale];
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

- (NSString *)getTranslatedLangname:(NSString *)lang
{
    return [_theLocal displayNameForKey:NSLocaleIdentifier value:lang];
}

- (IBAction)localeButtonClicked:(id)sender
{
    if (_localizedContent.allKeys.count <= 1)
    {
        [[[UIAlertView alloc] initWithTitle:@"" message:OALocalizedString(@"no_other_translations") delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        
        return;
    }
    
    UIActionSheet *actions = [[UIActionSheet alloc] initWithTitle:OALocalizedString(@"select_language") delegate:self cancelButtonTitle:OALocalizedString(@"shared_string_cancel") destructiveButtonTitle:nil otherButtonTitles:nil];
    
    NSMutableArray *locales = [NSMutableArray array];
    NSString *nativeStr;
    for (NSString *loc in _localizedContent.allKeys)
    {
        if (loc.length == 0)
            nativeStr = loc;
        else
            [locales addObject:loc];
    }
    
    [locales sortUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
        return [obj1 compare:obj2];
    }];
    
    if (nativeStr)
        [actions addButtonWithTitle:[[self getTranslatedLangname:@"en"] capitalizedStringWithLocale:[NSLocale currentLocale]]];

    for (NSString *loc in locales)
        [actions addButtonWithTitle:[[self getTranslatedLangname:loc] capitalizedStringWithLocale:[NSLocale currentLocale]]];
    
    if (nativeStr)
        [locales insertObject:@"" atIndex:0];
    
    _namesSorted = [NSArray arrayWithArray:locales];
    
    [actions showFromRect:_localeButton.frame inView:_navBar animated:YES];
}

- (NSString *) appendHeadToContent:(NSString *) content
{
    if (content == nil)
    {
        return nil;
    }
    NSString *head = @"<head></head><div class=\"main\">%@</div>";
    return [NSString stringWithFormat:head, content];
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != actionSheet.cancelButtonIndex)
    {
        _contentLocale = _namesSorted[buttonIndex - 1];
        
        NSString *content = [self appendHeadToContent:[self.localizedContent objectForKey:_contentLocale]];
        
        NSString *locBtnStr = (_contentLocale.length == 0 ? @"EN" : [_contentLocale uppercaseString]);
        [_localeButton setTitle:locBtnStr forState:UIControlStateNormal];
        
        _titleView.text = ([self.localizedNames objectForKey:_contentLocale] ? [self.localizedNames objectForKey:_contentLocale] : @"Wikipedia");

        [self buildBaseUrl];
        if (content)
            [_contentView loadHTMLString:content baseURL:_baseUrl];
    }
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
