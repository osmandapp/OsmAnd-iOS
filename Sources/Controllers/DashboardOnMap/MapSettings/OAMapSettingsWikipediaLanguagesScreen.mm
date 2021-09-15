//
//  OAMapSettingsWikipediaLanguagesScreen.mm
//  OsmAnd
//
//  Created by Skalii on 10.07.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OAMapSettingsWikipediaLanguagesScreen.h"
#import "OsmAndApp.h"
#import "OAWikipediaPlugin.h"
#import "OAPOIHelper.h"
#import "Localization.h"
#import "OAColors.h"
#import "OATableViewCustomHeaderView.h"
#import "OADividerCell.h"
#import "OASettingSwitchCell.h"
#import "OAMenuSimpleCellNoIcon.h"
#import "OARootViewController.h"

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
    self = [super self];
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

@interface OAMapSettingsWikipediaLanguagesScreen () <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;

@end

@implementation OAMapSettingsWikipediaLanguagesScreen
{
    OsmAndAppInstance _app;

    OAWikipediaPlugin *_wikiPlugin;
    NSMutableArray<OAWikiLanguageItem *> *_languages;
    BOOL _isGlobalWikiPoiEnabled;

    NSArray<NSArray<NSDictionary *> *> *_data;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _wikiPlugin = (OAWikipediaPlugin *) [OAPlugin getPlugin:OAWikipediaPlugin.class];
        _isGlobalWikiPoiEnabled = NO;
        _languages = [NSMutableArray new];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.editing = YES;
    self.tableView.tintColor = UIColorFromRGB(color_primary_purple);
    [self.tableView registerClass:OATableViewCustomHeaderView.class forHeaderFooterViewReuseIdentifier:[OATableViewCustomHeaderView getCellIdentifier]];

    [self initData];
}

- (void)applyLocalization
{
    self.titleLabel.text = OALocalizedString(@"language");
    [self.cancelButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
    [self.doneButton setTitle:OALocalizedString(@"shared_string_done") forState:UIControlStateNormal];
}

- (void)initData
{
    [self initLanguagesData];

    NSMutableArray *dataArr = [NSMutableArray new];
    [dataArr addObject:@[
            @{@"type": [OADividerCell getCellIdentifier]},
            @{
                    @"type": [OASettingSwitchCell getCellIdentifier],
                    @"title": OALocalizedString(@"shared_string_all_languages")
            },
            @{@"type": [OADividerCell getCellIdentifier]}
    ]];

    NSMutableArray *preferredLanguages = [NSMutableArray new];
    [preferredLanguages addObject:@{@"type": [OADividerCell getCellIdentifier]}];
    NSMutableArray *availableLanguages = [NSMutableArray new];
    [availableLanguages addObject:@{@"type": [OADividerCell getCellIdentifier]}];

    for (OAWikiLanguageItem *language in _languages)
    {
        NSDictionary *lang = @{
                @"type": [OAMenuSimpleCellNoIcon getCellIdentifier],
                @"item": language
        };

        if (language.preferred)
        {
            [preferredLanguages addObject:lang];
            [preferredLanguages addObject:@{@"type": [OADividerCell getCellIdentifier]}];
        }
        else
        {
            [availableLanguages addObject:lang];
            [availableLanguages addObject:@{@"type": [OADividerCell getCellIdentifier]}];
        }
    }
    [dataArr addObject:preferredLanguages];
    [dataArr addObject:availableLanguages];

    _data = dataArr;
}

- (void)initLanguagesData
{
    [_languages removeAllObjects];

    NSMutableArray<NSString *> *preferredLocales = [NSMutableArray new];
    for (NSString *langCode in [NSLocale preferredLanguages])
    {
        [preferredLocales addObject:[langCode substringToIndex:[langCode indexOf:@"-"]]];
    }

    _isGlobalWikiPoiEnabled = [_wikiPlugin isShowAllLanguages];
    if ([_wikiPlugin hasLanguagesFilter])
    {
        NSArray<NSString *> *enabledWikiPoiLocales = [_wikiPlugin getLanguagesToShow];
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
    [_languages setArray:[_languages sortedArrayUsingSelector:@selector(compare:)]];
}

- (void)applyPreference:(BOOL)applyToAllProfiles
{
    NSMutableArray<NSString *> *localesForSaving = [NSMutableArray new];
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
        [_wikiPlugin setLanguagesToShow:localesForSaving];
        [_wikiPlugin setShowAllLanguages:localesForSaving.count == 0 ? YES : _isGlobalWikiPoiEnabled];
    }
    [_wikiPlugin updateWikipediaState];
}

- (void)applyParameter:(id)sender
{
    if ([sender isKindOfClass:[UISwitch class]])
    {
        [self.tableView beginUpdates];
        UISwitch *sw = (UISwitch *) sender;
        _isGlobalWikiPoiEnabled = sw.on;
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:sw.tag & 0x3FF inSection:sw.tag >> 10]] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:EOAMapSettingsWikipediaLangSectionPreffered] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:EOAMapSettingsWikipediaLangSectionAvailable] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
    }
}

- (NSDictionary *)getItem:(NSIndexPath *)indexPath
{
    return _data[indexPath.section][indexPath.row];
}

- (NSString *)getTextForHeader:(NSInteger)section
{
    switch (section)
    {
        case EOAMapSettingsWikipediaLangSectionAll:
            return [NSString stringWithFormat:@"%@\n\n%@", OALocalizedString(@"some_articles_may_not_available_in_lang"), OALocalizedString(@"select_wikipedia_article_langs")];
        case EOAMapSettingsWikipediaLangSectionPreffered:
            return [OALocalizedString(@"preferred_languages") upperCase];
        case EOAMapSettingsWikipediaLangSectionAvailable:
            return [OALocalizedString(@"available_languages") upperCase];
        default:
            return @"";
    }
}

- (CGFloat)heightForRow:(NSIndexPath *)indexPath estimated:(BOOL)estimated
{
    NSDictionary *item = [self getItem:indexPath];
    if ([item[@"type"] isEqualToString:[OADividerCell getCellIdentifier]])
        return [OADividerCell cellHeight:0.5 dividerInsets:UIEdgeInsetsZero];
    else
        return estimated ? 48. : UITableViewAutomaticDimension;
}

- (CGFloat)getHeaderHeightForSection:(NSInteger)section
{
    return [OATableViewCustomHeaderView getHeight:[self getTextForHeader:section] width:self.tableView.frame.size.width yOffset:17. font:[UIFont systemFontOfSize:section == EOAMapSettingsWikipediaLangSectionAll ? 15.0 : 13.0]];
}

- (void)selectDeselectItem:(NSIndexPath *)indexPath
{
    if (indexPath.section != EOAMapSettingsWikipediaLangSectionAll)
    {
        [self.tableView beginUpdates];
        OAWikiLanguageItem *language = [self getItem:indexPath][@"item"];
        language.checked = !language.checked;
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        [self.tableView endUpdates];
    }
}

- (IBAction)cancelButtonPressed:(id)sender
{
    [self dismissViewController];
}

- (IBAction)doneButtonPressed:(id)sender
{
    [self applyPreference:NO];

    if (self.delegate)
        [self.delegate updateSelectedLanguage];

    [self dismissViewController];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section != EOAMapSettingsWikipediaLangSectionAll && _isGlobalWikiPoiEnabled)
        return 0;

    return _data[section].count;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    if ([item[@"type"] isEqualToString:[OADividerCell getCellIdentifier]])
    {
        OADividerCell *cell = [tableView dequeueReusableCellWithIdentifier:[OADividerCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OADividerCell getCellIdentifier] owner:self options:nil];
            cell = (OADividerCell *) nib[0];
            cell.backgroundColor = UIColor.whiteColor;
            cell.dividerColor = UIColorFromRGB(color_tint_gray);
            cell.dividerHight = 0.5;
        }
        if (cell)
        {
            CGFloat leftInset = indexPath.row == 0 || indexPath.row == [self tableView:tableView numberOfRowsInSection:indexPath.section] - 1 ? 0. : 62.;
            cell.dividerInsets = UIEdgeInsetsMake(0., leftInset, 0., 0.);
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:[OASettingSwitchCell getCellIdentifier]])
    {
        OASettingSwitchCell *cell = [tableView dequeueReusableCellWithIdentifier:[OASettingSwitchCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASettingSwitchCell getCellIdentifier] owner:self options:nil];
            cell = (OASettingSwitchCell *) nib[0];
        }

        if (cell)
        {
            cell.textView.text = item[@"title"];
            cell.descriptionView.hidden = YES;
            cell.imgView.hidden = YES;
            [cell.switchView setOn:_isGlobalWikiPoiEnabled];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
            [cell.switchView removeTarget:nil action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.switchView addTarget:self action:@selector(applyParameter:) forControlEvents:UIControlEventValueChanged];
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:[OAMenuSimpleCellNoIcon getCellIdentifier]])
    {
        OAWikiLanguageItem *language = item[@"item"];
        OAMenuSimpleCellNoIcon *cell = [tableView dequeueReusableCellWithIdentifier:[OAMenuSimpleCellNoIcon getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAMenuSimpleCellNoIcon getCellIdentifier] owner:self options:nil];
            cell = (OAMenuSimpleCellNoIcon *) nib[0];
            cell.tintColor = UIColorFromRGB(color_primary_purple);
            UIView *bgColorView = [[UIView alloc] init];
            bgColorView.backgroundColor = [UIColorFromRGB(color_primary_purple) colorWithAlphaComponent:.05];
            [cell setSelectedBackgroundView:bgColorView];
            cell.separatorInset = UIEdgeInsetsMake(0.0, 62.0, 0.0, 0.0);
            cell.descriptionView.hidden = YES;

            if ([cell needsUpdateConstraints])
                [cell updateConstraints];
        }
        if (cell)
        {
            cell.textView.text = [OAUtilities capitalizeFirstLetterAndLowercase:language.title];
        }
        return cell;
    }

    return nil;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [[self getItem:indexPath][@"type"] isEqualToString:[OAMenuSimpleCellNoIcon getCellIdentifier]];
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self heightForRow:indexPath estimated:NO];
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self heightForRow:indexPath estimated:YES];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    if ([item[@"type"] isEqualToString:[OAMenuSimpleCellNoIcon getCellIdentifier]])
    {
        OAWikiLanguageItem *language = item[@"item"];
        [cell setSelected:language.checked animated:YES];
        if (language.checked)
            [tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
        else
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [[self getItem:indexPath][@"type"] isEqualToString:[OAMenuSimpleCellNoIcon getCellIdentifier]] ? indexPath : nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[self getItem:indexPath][@"type"] isEqualToString:[OAMenuSimpleCellNoIcon getCellIdentifier]])
        [self selectDeselectItem:indexPath];
    else
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[self getItem:indexPath][@"type"] isEqualToString:[OAMenuSimpleCellNoIcon getCellIdentifier]])
        [self selectDeselectItem:indexPath];
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    if (section == EOAMapSettingsWikipediaLangSectionAll || !_isGlobalWikiPoiEnabled)
    {
        UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *) view;
        header.textLabel.textColor = UIColorFromRGB(color_text_footer);
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (section != EOAMapSettingsWikipediaLangSectionAll && _isGlobalWikiPoiEnabled)
        return nil;

    OATableViewCustomHeaderView *vw = [tableView dequeueReusableHeaderFooterViewWithIdentifier:[OATableViewCustomHeaderView getCellIdentifier]];
    NSString *text = [self getTextForHeader:section];
    vw.label.text = text;
    vw.label.font = [UIFont systemFontOfSize:section == EOAMapSettingsWikipediaLangSectionAll ? 15.0 : 13.0];
    return vw;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return [self getHeaderHeightForSection:section];
}

@end
