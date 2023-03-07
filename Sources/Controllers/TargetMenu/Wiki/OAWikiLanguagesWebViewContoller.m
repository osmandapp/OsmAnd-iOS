//
//  OAWikiLanguagesWebViewContoller.m
//  OsmAnd Maps
//
//  Created by Skalii on 06.03.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OAWikiLanguagesWebViewContoller.h"
#import "OASimpleTableViewCell.h"
#import "OATableDataModel.h"
#import "OATableSectionData.h"
#import "OATableRowData.h"
#import "Localization.h"

@implementation OAWikiLanguagesWebViewContoller
{
    NSString *_selectedLocale;
    NSArray<NSString *> *_availableLocales;
    OATableDataModel *_data;
}

#pragma mark - Initialzation

- (instancetype)initWithSelectedLocale:(NSString *)selectedLocale availableLocales:(NSArray<NSString *> *)availableLocales
{
    self = [super init];
    if (self)
    {
        _selectedLocale = selectedLocale;
        _availableLocales = availableLocales;
    }
    return self;
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return OALocalizedString(@"change_language");
}

- (NSString *)getLeftNavbarButtonTitle
{
    return OALocalizedString(@"shared_string_cancel");
}

#pragma mark - Table data

- (void)generateData
{
    _data = [OATableDataModel model];

    OATableSectionData *prefferedSection = [_data createNewSection];
    prefferedSection.headerText = OALocalizedString(@"preferred_languages");
    NSMutableArray<NSString *> *preferredLocales = [NSMutableArray new];
    for (NSString *langCode in [NSLocale preferredLanguages])
    {
        NSInteger index = [langCode indexOf:@"-"];
        if (index != NSNotFound && index < langCode.length)
            [preferredLocales addObject:[langCode substringToIndex:index]];
    }

    for (NSString *preferredLocale in preferredLocales)
    {
        [prefferedSection addRowFromDictionary:@{
            kCellTypeKey: [OASimpleTableViewCell getCellIdentifier],
            @"locale" : preferredLocale,
            @"language" : [OAUtilities translatedLangName:preferredLocale].capitalizedString,
            @"selected" : @([_selectedLocale.length == 0 ? @"en" : _selectedLocale isEqualToString:preferredLocale])
        }];
    }

    OATableSectionData *availableSection = [_data createNewSection];
    availableSection.headerText = OALocalizedString(@"available_languages");
    NSMutableArray<OATableRowData *> *availableLocaleRows = [NSMutableArray array];
    for (NSString *availableLocale in _availableLocales)
    {
        [availableLocaleRows addObject:[[OATableRowData alloc] initWithData:@{
            kCellTypeKey: [OASimpleTableViewCell getCellIdentifier],
            @"locale" : availableLocale,
            @"language" : [OAUtilities translatedLangName:availableLocale].capitalizedString,
            @"selected" : @([_selectedLocale.length == 0 ? @"en" : _selectedLocale isEqualToString:availableLocale])
        }]];
    }
    [self languageCompare:availableLocaleRows];
    [availableSection addRows:availableLocaleRows];
}

- (NSString *)getTitleForHeader:(NSInteger)section
{
    return [_data sectionDataForIndex:section].headerText;
}

- (NSInteger)rowsCount:(NSInteger)section
{
    return [_data rowCount:section];
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    OATableRowData *item = [_data itemForIndexPath:indexPath];
    if ([item.cellType isEqualToString:[OASimpleTableViewCell getCellIdentifier]])
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
            cell.titleLabel.text = [item stringForKey:@"language"];
            cell.accessoryType = [item boolForKey:@"selected"] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
        }
        return cell;
    }
    return nil;
}

- (NSInteger)sectionsCount
{
    return [_data sectionCount];
}

- (void)onRowSelected:(NSIndexPath *)indexPath
{
    if (self.delegate)
    {
        OATableRowData *item = [_data itemForIndexPath:indexPath];
        NSString *locale = [item stringForKey:@"locale"];
        [self.delegate onLocaleSelected:locale];
        [self dismissViewController];
    }
}

#pragma mark - Additions

- (void)languageCompare:(NSMutableArray<OATableRowData *> *)rowsData
{
    [rowsData sortUsingComparator:^NSComparisonResult(OATableRowData *r1, OATableRowData *r2) {
        NSString *l1 = [r1 stringForKey:@"language"];
        NSString *l2 = [r2 stringForKey:@"language"];
        BOOL s1 = [r1 boolForKey:@"selected"];
        BOOL s2 = [r2 boolForKey:@"selected"];
        NSComparisonResult result = s2 ? (!s1 ? NSOrderedDescending : NSOrderedSame) : (s1 ? NSOrderedAscending : NSOrderedSame);
        return result != NSOrderedSame ? result : [l1 localizedCaseInsensitiveCompare:l2];
    }];
}

@end
