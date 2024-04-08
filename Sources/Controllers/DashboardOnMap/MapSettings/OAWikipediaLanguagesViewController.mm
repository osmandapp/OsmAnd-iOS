//
//  OAWikipediaLanguagesViewController.mm
//  OsmAnd
//
//  Created by Skalii on 10.07.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OAWikipediaLanguagesViewController.h"
#import "OsmAndApp.h"
#import "OAWikipediaPlugin.h"
#import "OAPOIHelper.h"
#import "Localization.h"
#import "OAColors.h"
#import "OATableViewCustomHeaderView.h"
#import "OASwitchTableViewCell.h"
#import "OASimpleTableViewCell.h"
#import "OAPluginsHelper.h"

typedef NS_ENUM(NSInteger, EOAMapSettingsWikipediaLangSection)
{
    EOAMapSettingsWikipediaLangSectionAll = 0,
    EOAMapSettingsWikipediaLangSectionPreffered,
    EOAMapSettingsWikipediaLangSectionAvailable
};

@interface OAWikiLanguageItem ()

@property (nonatomic) NSString *locale;
@property (nonatomic) NSString *title;
@property (nonatomic) BOOL preferred;

@end

@implementation OAWikiLanguageItem

- (instancetype)initWithLocale:(NSString *)locale title:(NSString *)title checked:(BOOL)checked preferred:(BOOL)preferred
{
    self = [super init];
    if (self)
    {
        _locale = locale;
        _title = title;
        _checked = checked;
        _preferred = preferred;
    }
    return self;
}

- (NSComparisonResult)compare:(OAWikiLanguageItem *)object
{
    NSComparisonResult result = object.checked ? (!self.checked ? NSOrderedDescending : NSOrderedSame) : (self.checked ? NSOrderedAscending : NSOrderedSame);
    return result != NSOrderedSame ? result : [self.title localizedCaseInsensitiveCompare:object.title];
}

@end

@implementation OAWikipediaLanguagesViewController
{
    OsmAndAppInstance _app;

    OAWikipediaPlugin *_wikiPlugin;
    NSMutableArray<OAWikiLanguageItem *> *_languages;
    BOOL _isGlobalWikiPoiEnabled;

    NSArray<NSArray<NSDictionary *> *> *_data;
}

#pragma mark - Initialization

- (void)commonInit
{
    _app = [OsmAndApp instance];
    _wikiPlugin = (OAWikipediaPlugin *) [OAPluginsHelper getPlugin:OAWikipediaPlugin.class];
}

- (void)postInit
{
    _languages = [NSMutableArray array];
    NSMutableArray<NSString *> *preferredLocales = [NSMutableArray new];
    for (NSString *langCode in [NSLocale preferredLanguages])
    {
        NSInteger index = [langCode indexOf:@"-"];
        if (index != NSNotFound && index < langCode.length)
            [preferredLocales addObject:[langCode substringToIndex:index]];
    }

    _isGlobalWikiPoiEnabled = [_wikiPlugin isShowAllLanguages:self.appMode];
    if ([_wikiPlugin hasLanguagesFilter:self.appMode])
    {
        NSArray<NSString *> *enabledWikiPoiLocales = [_wikiPlugin getLanguagesToShow:self.appMode];
        for (NSString *locale in [[OAPOIHelper sharedInstance] getAllAvailableWikiLocales])
        {
            BOOL checked = [enabledWikiPoiLocales containsObject:locale];
            BOOL preferred = [preferredLocales containsObject:locale];
            [_languages addObject:[[OAWikiLanguageItem alloc] initWithLocale:locale title:[OAUtilities translatedLangName:locale] checked:checked preferred:preferred]];
        }
    }
    else
    {
        _isGlobalWikiPoiEnabled = YES;
        for (NSString *locale in [[OAPOIHelper sharedInstance] getAllAvailableWikiLocales])
        {
            BOOL preferred = [preferredLocales containsObject:locale];
            [_languages addObject:[[OAWikiLanguageItem alloc] initWithLocale:locale title:[OAUtilities translatedLangName:locale] checked:NO preferred:preferred]];
        }
    }
    [_languages sortUsingSelector:@selector(compare:)];
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.tableView setEditing:YES animated:YES];
    self.tableView.allowsMultipleSelectionDuringEditing = YES;
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return OALocalizedString(@"shared_string_language");
}

- (NSString *)getSubtitle
{
    return @"";
}

- (NSString *)getLeftNavbarButtonTitle
{
    return OALocalizedString(@"shared_string_cancel");
}

- (NSArray<UIBarButtonItem *> *)getRightNavbarButtons
{
    return @[[self createRightNavbarButton:OALocalizedString(@"shared_string_done")
                                  iconName:nil
                                    action:@selector(onRightNavbarButtonPressed)
                                      menu:nil]];
}

- (NSString *)getTableHeaderDescription
{
    return [NSString stringWithFormat:@"%@\n\n%@", OALocalizedString(@"some_articles_may_not_available_in_lang"), OALocalizedString(@"select_wikipedia_article_langs")];
}

#pragma mark - Table data

- (void)generateData
{
    NSMutableArray *dataArr = [NSMutableArray new];
    [dataArr addObject:@[@{
        @"type": [OASwitchTableViewCell getCellIdentifier],
        @"title": OALocalizedString(@"shared_string_all_languages")
    }]];

    if (!_isGlobalWikiPoiEnabled)
    {
        NSMutableArray *preferredLanguages = [NSMutableArray new];
        NSMutableArray *availableLanguages = [NSMutableArray new];
        
        for (OAWikiLanguageItem *language in _languages)
        {
            NSDictionary *lang = @{
                @"type": [OASimpleTableViewCell getCellIdentifier],
                @"item": language
            };
            
            if (language.preferred)
                [preferredLanguages addObject:lang];
            else
                [availableLanguages addObject:lang];
        }
        [dataArr addObject:preferredLanguages];
        [dataArr addObject:availableLanguages];
    }

    _data = dataArr;
}

- (NSDictionary *)getItem:(NSIndexPath *)indexPath
{
    return _data[indexPath.section][indexPath.row];
}

- (BOOL)hideFirstHeader
{
    return YES;
}

- (NSString *)getTitleForHeader:(NSInteger)section
{
    switch (section)
    {
        case EOAMapSettingsWikipediaLangSectionPreffered:
            return OALocalizedString(@"preferred_languages");
        case EOAMapSettingsWikipediaLangSectionAvailable:
            return OALocalizedString(@"available_languages");
        default:
            return @"";
    }
}

- (NSInteger)rowsCount:(NSInteger)section
{
    return _data[section].count;
}

- (UITableViewCell*)getRow:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    if ([item[@"type"] isEqualToString:[OASwitchTableViewCell getCellIdentifier]])
    {
        OASwitchTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OASwitchTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASwitchTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASwitchTableViewCell *) nib[0];
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
        }
        if (cell)
        {
            cell.titleLabel.text = item[@"title"];

            [cell.switchView setOn:_isGlobalWikiPoiEnabled];
            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
            [cell.switchView removeTarget:nil action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.switchView addTarget:self action:@selector(onSwitchPressed:) forControlEvents:UIControlEventValueChanged];
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:[OASimpleTableViewCell getCellIdentifier]])
    {
        OASimpleTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OASimpleTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASimpleTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASimpleTableViewCell *) nib[0];
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
        }
        if (cell)
        {
            OAWikiLanguageItem *language = item[@"item"];
            cell.titleLabel.text = language.title.capitalizedString;
        }
        return cell;
    }
    return nil;
}

- (NSInteger)sectionsCount
{
    return _data.count;
}

- (void)onRowSelected:(NSIndexPath *)indexPath
{
    OAWikiLanguageItem *language = [self getItem:indexPath][@"item"];
    language.checked = !language.checked;
}

- (void)onRowDeselected:(NSIndexPath *)indexPath
{
    OAWikiLanguageItem *language = [self getItem:indexPath][@"item"];
    language.checked = !language.checked;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    if ([item[@"type"] isEqualToString:[OASimpleTableViewCell getCellIdentifier]])
    {
        OAWikiLanguageItem *language = item[@"item"];
        [cell setSelected:language.checked animated:YES];
        if (language.checked)
            [tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
        else
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

#pragma mark - UITableViewDataSource

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [[self getItem:indexPath][@"type"] isEqualToString:[OASimpleTableViewCell getCellIdentifier]];
}

#pragma mark - Selectors

- (void)onRightNavbarButtonPressed
{
    [self applyPreference:NO];

    if (self.wikipediaDelegate)
        [self.wikipediaDelegate updateWikipediaSettings];

    [self dismissViewController];
}

- (void)onSwitchPressed:(UISwitch *)sw
{
    _isGlobalWikiPoiEnabled = sw.on;
    [UIView transitionWithView:self.view
                      duration:.2
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^(void)
                    {
                        [self generateData];
                        [self.tableView reloadData];
                    }
                    completion:nil];
}

- (void)applyPreference:(BOOL)applyToAllProfiles
{
    NSMutableArray<NSString *> *localesForSaving = [NSMutableArray new];
    [_languages sortUsingSelector:@selector(compare:)];
    for (OAWikiLanguageItem *language in _languages)
    {
        if (language.checked)
            [localesForSaving addObject:language.locale];
    }
    if (applyToAllProfiles)
    {
        for (OAApplicationMode *mode in [OAApplicationMode allPossibleValues])
        {
            [_wikiPlugin setLanguagesToShow:mode languagesToShow:localesForSaving];
            [_wikiPlugin setShowAllLanguages:mode showAllLanguages:localesForSaving.count == 0 ? YES : _isGlobalWikiPoiEnabled];
        }
    }
    else
    {
        [_wikiPlugin setLanguagesToShow:self.appMode languagesToShow:localesForSaving];
        [_wikiPlugin setShowAllLanguages:self.appMode showAllLanguages:localesForSaving.count == 0 ? YES : _isGlobalWikiPoiEnabled];
    }
    [_wikiPlugin updateWikipediaState];
}

@end
