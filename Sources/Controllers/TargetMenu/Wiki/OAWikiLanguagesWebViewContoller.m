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
    NSArray<NSString *> *_preferredLocales;
    OATableDataModel *_data;
}

#pragma mark - Initialzation

- (instancetype)initWithSelectedLocale:(NSString *)selectedLocale
                      availableLocales:(NSArray<NSString *> *)availableLocales
                      preferredLocales:(NSArray<NSString *> *)preferredLocales
{
    self = [super init];
    if (self)
    {
        _selectedLocale = selectedLocale;
        _availableLocales = availableLocales;
        _preferredLocales = preferredLocales;
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
    NSMutableSet<NSString *> *preferredLocales = [NSMutableSet set];
    NSArray<NSString *> *preferredLanguages = [NSLocale preferredLanguages];
    for (NSInteger i = 0; i < preferredLanguages.count; i ++)
    {
        NSString *preferredLocale = preferredLanguages[i];
        if ([preferredLocale containsString:@"-"])
            preferredLocale = [preferredLocale substringToIndex:[preferredLocale indexOf:@"-"]];
        if ([preferredLocale isEqualToString:@"en"])
            preferredLocale = @"";
        [preferredLocales addObject:preferredLocale];
    }

    for (NSString *preferredLocale in preferredLocales)
    {
        if ([_preferredLocales containsObject:preferredLocale])
        {
            [prefferedSection addRowFromDictionary:@{
                kCellTypeKey: [OASimpleTableViewCell getCellIdentifier],
                @"locale" : preferredLocale,
                @"language" : [OAUtilities translatedLangName:preferredLocale.length > 0 ? preferredLocale : @"en"].capitalizedString,
                @"selected" : @([_selectedLocale isEqualToString:preferredLocale])
            }];
        }
    }

    OATableSectionData *availableSection = [_data createNewSection];
    availableSection.headerText = OALocalizedString(@"available_languages");
    NSMutableArray<OATableRowData *> *availableLocaleRows = [NSMutableArray array];
    for (NSString *availableLocale in _availableLocales)
    {
        [availableLocaleRows addObject:[[OATableRowData alloc] initWithData:@{
            kCellTypeKey: [OASimpleTableViewCell getCellIdentifier],
            @"locale" : availableLocale,
            @"language" : [OAUtilities translatedLangName:availableLocale.length > 0 ? availableLocale : @"en"].capitalizedString,
            @"selected" : @([_selectedLocale isEqualToString:availableLocale])
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
