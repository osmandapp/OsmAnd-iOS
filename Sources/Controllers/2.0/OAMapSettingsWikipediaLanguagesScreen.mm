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

static const NSInteger allSection = 0;
static const NSInteger preferredSection = 1;
static const NSInteger availableSection = 2;

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
    self.tableView.rowHeight = kEstimatedRowHeight;
    self.tableView.estimatedRowHeight = kEstimatedRowHeight;
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

    NSMutableArray *dataArr = [@[@[
            @{@"type": [OADividerCell getCellIdentifier]},
            @{
                    @"type": [OASettingSwitchCell getCellIdentifier],
                    @"title": OALocalizedString(@"shared_string_all_languages")
            },
            @{@"type": [OADividerCell getCellIdentifier]}
    ]] mutableCopy];

    NSMutableArray *preferredLanguages = [@[@{@"type": [OADividerCell getCellIdentifier]}] mutableCopy];
    NSMutableArray *availableLanguages = [@[@{@"type": [OADividerCell getCellIdentifier]}] mutableCopy];

    for (OAWikiLanguageItem *language in _languages)
    {
        NSDictionary *lang = @{
                @"type": [OAMenuSimpleCellNoIcon getCellIdentifier],
                @"item": language
        };

        if (language.preferred)
            [preferredLanguages addObject:lang];
        else
            [availableLanguages addObject:lang];
    }

    [preferredLanguages addObject:@{@"type": [OADividerCell getCellIdentifier]}];
    [availableLanguages addObject:@{@"type": [OADividerCell getCellIdentifier]}];
    [dataArr addObject:preferredLanguages];
    [dataArr addObject:availableLanguages];

    _data = [NSArray arrayWithArray:dataArr];
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
        [self applyPreference:NO];
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:sw.tag & 0x3FF inSection:sw.tag >> 10]] withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:preferredSection] withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:availableSection] withRowAnimation:UITableViewRowAnimationFade];
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
        case allSection:
            return [NSString stringWithFormat:@"%@\n\n%@", OALocalizedString(@"some_articles_may_not_available_in_lang"), OALocalizedString(@"select_wikipedia_article_langs")];
        case preferredSection:
            return [OALocalizedString(@"preferred_languages") upperCase];
        case availableSection:
            return [OALocalizedString(@"available_languages") upperCase];
        default:
            return @"";
    }
}

- (CGFloat)getHeaderHeightForSection:(NSInteger)section
{
    return [OATableViewCustomHeaderView getHeight:[self getTextForHeader:section] width:self.tableView.frame.size.width yOffset:17. font:[UIFont systemFontOfSize:section == allSection ? 15.0 : 13.0]];
}

- (void)selectDeselectItem:(NSIndexPath *)indexPath
{
    if (indexPath.section != allSection)
    {
        [self.tableView beginUpdates];
        OAWikiLanguageItem *language = [self getItem:indexPath][@"item"];
        language.checked = !language.checked;
        [self.tableView endUpdates];
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
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
    if (section != allSection && _isGlobalWikiPoiEnabled)
        return 0;

    return _data[section].count;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    if ([item[@"type"] isEqualToString:[OADividerCell getCellIdentifier]])
    {
        OADividerCell* cell = [tableView dequeueReusableCellWithIdentifier:[OADividerCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OADividerCell getCellIdentifier] owner:self options:nil];
            cell = (OADividerCell *) nib[0];
            cell.backgroundColor = UIColor.whiteColor;
            cell.dividerColor = UIColorFromRGB(color_tint_gray);
            cell.dividerInsets = UIEdgeInsetsZero;
            cell.dividerHight = 0.5;
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:[OASettingSwitchCell getCellIdentifier]])
    {
        OASettingSwitchCell* cell = [tableView dequeueReusableCellWithIdentifier:[OASettingSwitchCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASettingSwitchCell getCellIdentifier] owner:self options:nil];
            cell = (OASettingSwitchCell *) nib[0];
        }

        if (cell)
        {
            cell.separatorInset = UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0);
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
            bgColorView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.0];
            [cell setSelectedBackgroundView:bgColorView];
        }
        if (cell)
        {
            cell.separatorInset = UIEdgeInsetsMake(0.0, 62.0, 0.0, 0.0);
            cell.textView.text = [OAUtilities capitalizeFirstLetterAndLowercase:language.title];
            cell.descriptionView.hidden = YES;

            if ([cell needsUpdateConstraints])
                [cell updateConstraints];
            return cell;
        }
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
    if ([[self getItem:indexPath][@"type"] isEqualToString:[OADividerCell getCellIdentifier]])
        return [OADividerCell cellHeight:0.5 dividerInsets:UIEdgeInsetsZero];
    else
        return UITableViewAutomaticDimension;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section != allSection)
    {
        OAWikiLanguageItem *language = [self getItem:indexPath][@"item"];
        [cell setSelected:language.checked animated:NO];
        if (language.checked)
            [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        else
            [tableView deselectRowAtIndexPath:indexPath animated:NO];
    }
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    return indexPath.section != allSection ? indexPath : nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section != allSection)
        [self selectDeselectItem:indexPath];
    else
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section != allSection)
        [self selectDeselectItem:indexPath];
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    if (section == allSection || !_isGlobalWikiPoiEnabled)
    {
        UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *) view;
        header.textLabel.textColor = UIColorFromRGB(color_text_footer);
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (section != allSection && _isGlobalWikiPoiEnabled)
        return nil;

    OATableViewCustomHeaderView *vw = [tableView dequeueReusableHeaderFooterViewWithIdentifier:[OATableViewCustomHeaderView getCellIdentifier]];
    NSString *text = [self getTextForHeader:section];
    vw.label.text = text;
    vw.label.font = [UIFont systemFontOfSize:section == allSection ? 15.0 : 13.0];
    return vw;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return [self getHeaderHeightForSection:section];
}

@end
