//
//  OARearrangeCustomFiltersViewController.mm
//  OsmAnd
//
// Created by Skalii Dmitrii on 19.04.2021.
// Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OARearrangeCustomFiltersViewController.h"
#import "OAPOIFiltersHelper.h"
#import "Localization.h"
#import "OsmAnd_Maps-Swift.h"
#import "OAQuickSearchHelper.h"
#import "OARightIconTableViewCell.h"
#import "OAAppSettings.h"
#import "OAQuickSearchButtonListItem.h"
#import "OAPOIHelper.h"
#import "OASizes.h"
#import "GeneratedAssetSymbols.h"

#define kAllFiltersSection 0
#define kHiddenFiltersSection 1
#define kActionsSection 2

@interface OAEditFilterItem : NSObject

@property (nonatomic) int order;
@property (nonatomic) OAPOIUIFilter *filter;

- (instancetype) initWithFilter:(OAPOIUIFilter *)filter;

@end

@implementation OAEditFilterItem

- (instancetype) initWithFilter:(OAPOIUIFilter *)filter
{
    self = [super init];
    if (self) {
        _filter = filter;
        _order = filter.order;
    }
    return self;
}

@end

@interface OAActionItem : NSObject

@property (nonatomic) NSString *title;
@property (nonatomic) UIImage *icon;
@property (nonatomic) OACustomSearchButtonOnClick onClickFunction;

- (instancetype)initWithIcon:(UIImage *)icon title:(NSString *)title onClickFunction:(OACustomSearchButtonOnClick)onClickFunction;
- (void)onClick;

@end

@implementation OAActionItem

- (instancetype)initWithIcon:(UIImage *)icon title:(NSString *)title onClickFunction:(OACustomSearchButtonOnClick)onClickFunction
{
    self = [super init];
    if (self) {
        _title = title;
        _icon = icon;
        _onClickFunction = onClickFunction;
    }
    return self;
}

- (void)onClick
{
    self.onClickFunction(self);
}

@end

@interface OARearrangeCustomFiltersViewController() <OATableViewCellDelegate>

@end

@implementation OARearrangeCustomFiltersViewController
{
    OAAppSettings *_settings;
    OAPOIFiltersHelper *_filtersHelper;
    BOOL _isChanged;
    BOOL _orderModified;
    BOOL _hiddenModified;
    BOOL _wasReset;

    NSArray<OAActionItem *> *_actionsItems;
    NSMutableArray<OAEditFilterItem *> *_filtersItems;
    NSMutableArray<OAEditFilterItem *> *_hiddenFiltersItems;
    NSMapTable<NSString *, NSNumber *> *_filtersOrders;
    NSMutableArray<NSString *> *_hiddenFiltersKeys;
    NSArray<OAPOIUIFilter *> *_filters;
}

#pragma mark - Initialization

- (instancetype)initWithFilters:(NSArray<OAPOIUIFilter *> *)filters
{
    self = [super init];
    if (self)
    {
        _filters = filters;
    }
    return self;
}

- (void)commonInit
{
    _settings = [OAAppSettings sharedManager];
    _filtersHelper = [OAPOIFiltersHelper sharedInstance];
    _orderModified = [_settings.poiFiltersOrder get] != nil;
    _hiddenModified = [_settings.inactivePoiFilters get] != nil;
}

#pragma mark - UIViewColontroller

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.editing = YES;
    self.tableView.allowsSelectionDuringEditing = YES;
    [self.navigationController.interactivePopGestureRecognizer addTarget:self
                                                                  action:@selector(swipeToCloseRecognized:)];
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return OALocalizedString(@"rearrange_categories");
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
    return OALocalizedString(@"create_custom_categories_list_promo");
}

- (EOABaseNavbarColorScheme)getNavbarColorScheme
{
    return EOABaseNavbarColorSchemeOrange;
}

#pragma mark - Table data

- (void)generateData
{
    _filtersItems = [NSMutableArray new];
    _hiddenFiltersItems = [NSMutableArray new];
    _filtersOrders = [NSMapTable new];
    _hiddenFiltersKeys = [NSMutableArray new];

    for (int i = 0; i < _filters.count; i++)
    {
        OAPOIUIFilter *filter = _filters[i];
        OAEditFilterItem *filterItem = [[OAEditFilterItem alloc] initWithFilter:filter];
        [_filtersOrders setObject:@(i) forKey:filter.filterId];
        if (!filter.isActive)
        {
            [_hiddenFiltersKeys addObject:filter.filterId];
            [_hiddenFiltersItems addObject:filterItem];
        }
        else
            [_filtersItems addObject:filterItem];
    }
    [self setupActionItems];
}

- (void)setupActionItems
{
    OAActionItem *actionResetToDefault = [[OAActionItem alloc] initWithIcon:[UIImage imageNamed:@"ic_custom_reset"] title:OALocalizedString(@"reset_to_default") onClickFunction:^(id sender) {
        _isChanged = YES;
        _wasReset = YES;
        NSInteger countHiddenCells = [self.tableView numberOfRowsInSection:kHiddenFiltersSection];
        if (countHiddenCells > 0) {
            while (countHiddenCells != 0) {
                CGRect rectInSection = [self.tableView rectForSection:kHiddenFiltersSection];
                NSArray<NSIndexPath *> *indexPathsInSection = [self.tableView indexPathsForRowsInRect:rectInSection];
                [self restoreMode:indexPathsInSection[0]];
                countHiddenCells -= 1;
            }
        }
        [_filtersItems setArray:[_filtersItems sortedArrayUsingComparator:^(OAEditFilterItem *obj1, OAEditFilterItem *obj2) {
            if ([obj1.filter.filterId isEqualToString:obj2.filter.filterId]) {
                NSString *filterByName1 = obj1.filter.filterByName == nil ? @"" : obj1.filter.filterByName;
                NSString *filterByName2 = obj2.filter.filterByName == nil ? @"" : obj2.filter.filterByName;
                return [filterByName1 localizedCaseInsensitiveCompare:filterByName2];
            } else
                return [obj1.filter.name localizedCaseInsensitiveCompare:obj2.filter.name];
        }]];
        [[OAQuickSearchHelper instance] refreshCustomPoiFilters];
    }];
    _actionsItems = @[actionResetToDefault];
}

- (OAEditFilterItem *)getItem:(NSIndexPath *)indexPath
{
    OAEditFilterItem *filterItem;
    if (indexPath.section == kAllFiltersSection)
        filterItem = _filtersItems[indexPath.row];
    else if (indexPath.section == kHiddenFiltersSection)
        filterItem = _hiddenFiltersItems[indexPath.row];
    return filterItem;
}

- (void)updateFiltersIndexes
{
    for (int i = 0; i < _filtersItems.count; i++)
        _filtersItems[i].order = i;
}

- (NSString *)getTitleForHeader:(NSInteger)section
{
    NSString *title;
    if (section == kAllFiltersSection)
        title = OALocalizedString(@"visible_categories");
    else if (section == kHiddenFiltersSection)
        title = OALocalizedString(@"hidden_categories");
    else
        title = OALocalizedString(@"shared_string_actions");
    return title;
}

- (NSString *)getTitleForFooter:(NSInteger)section
{
    return section == kActionsSection ? OALocalizedString(@"reset_to_default_category_button_promo") : @"";
}

- (NSInteger)rowsCount:(NSInteger)section
{
    if (section == kAllFiltersSection)
        return _filtersItems.count;
    else if (section == kHiddenFiltersSection)
        return _hiddenFiltersItems.count;
    else
        return _actionsItems.count;
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    NSString *cellType = indexPath.section == kActionsSection ? [OARightIconTableViewCell getCellIdentifier] : [OASimpleTableViewCell getCellIdentifier];
    if ([cellType isEqualToString:[OASimpleTableViewCell getCellIdentifier]])
    {
        OASimpleTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OASimpleTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASimpleTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASimpleTableViewCell *) nib[0];
            [cell leftEditButtonVisibility:YES];
            [cell descriptionVisibility:NO];
            cell.delegate = self;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.leftIconView.tintColor = [UIColor colorNamed:ACColorNameIconColorDefault];
            cell.leftIconView.contentMode = UIViewContentModeCenter;
        }
        if (cell)
        {
            BOOL isAllFilters = indexPath.section == kAllFiltersSection;
            OAPOIUIFilter *filter = isAllFilters ? _filtersItems[indexPath.row].filter : _hiddenFiltersItems[indexPath.row].filter;
            cell.titleLabel.text = filter.name;

            UIImage *icon;
            NSObject *res = [filter getIconResource];
            if ([res isKindOfClass:[NSString class]])
            {
                NSString *iconName = (NSString *)res;
                icon = [OAUtilities getMxIcon:iconName];
            }
            if (!icon)
                icon = [OAPOIHelper getCustomFilterIcon:filter];
            [cell.leftIconView setImage:[icon imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];

            NSString *imageName = isAllFilters ? @"ic_custom_delete" : @"ic_custom_plus";
            [cell.leftEditButton setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
            cell.leftEditButton.tag = indexPath.section << 10 | indexPath.row;
            [cell.leftEditButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
            [cell.leftEditButton addTarget:self action:@selector(onEditButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        }
        return cell;
    }
    else if ([cellType isEqualToString:[OARightIconTableViewCell getCellIdentifier]])
    {
        OARightIconTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OARightIconTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OARightIconTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OARightIconTableViewCell *) nib[0];
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
            cell.titleLabel.textColor = [UIColor colorNamed:ACColorNameTextColorActive];
            cell.titleLabel.font = [UIFont scaledSystemFontOfSize:17. weight:UIFontWeightMedium];
            cell.rightIconView.tintColor = [UIColor colorNamed:ACColorNameIconColorActive];
        }
        if (cell)
        {
            cell.separatorInset = UIEdgeInsetsMake(0., [OAUtilities getLeftMargin] + kPaddingOnSideOfContent, 0., 0.);
            OAActionItem *actionItem = _actionsItems[indexPath.row];
            cell.rightIconView.image = [actionItem.icon imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.titleLabel.text = actionItem.title;
        }
        return cell;
    }
    return nil;
}

- (NSInteger)sectionsCount
{
    return 3;
}

- (void)onRowSelected:(NSIndexPath *)indexPath
{
    if (indexPath.section == kActionsSection)
    {
        OAActionItem *actionItem = _actionsItems[indexPath.row];
        [actionItem onClick];
    }
}

#pragma mark - UITableViewDataSource

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return indexPath.section == kAllFiltersSection;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return indexPath.section == kAllFiltersSection;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    _isChanged = YES;
    _orderModified = YES;
    OAEditFilterItem *filterItem = [self getItem:sourceIndexPath];
    [CATransaction begin];
    [CATransaction setCompletionBlock:^{
        [self.tableView reloadData];
    }];
    [_filtersItems removeObjectAtIndex:sourceIndexPath.row];
    [_filtersItems insertObject:filterItem atIndex:destinationIndexPath.row];
    [_filtersOrders removeObjectForKey:filterItem.filter.filterId];
    [_filtersOrders setObject:@(destinationIndexPath.row) forKey:filterItem.filter.filterId];
    [self updateFiltersIndexes];
    [CATransaction commit];
}

#pragma mark - UITableViewDelegate

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleNone;
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath
{
    if (proposedDestinationIndexPath.section != kAllFiltersSection)
        return sourceIndexPath;
    return proposedDestinationIndexPath;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == kActionsSection)
        return indexPath;
    else
        return nil;
}

#pragma mark - Additions

- (void)showChangesAlert
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:OALocalizedString(@"exit_without_saving") preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_exit") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self.navigationController popViewControllerAnimated:YES];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_cancel") style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)hideMode:(NSIndexPath *)indexPath
{
    OAEditFilterItem *filterItem = _filtersItems[indexPath.row];
    [_filtersItems removeObject:filterItem];
    [_hiddenFiltersItems addObject:filterItem];
    [_hiddenFiltersKeys addObject:filterItem.filter.filterId];
    filterItem.filter.isActive = NO;
    [self updateFiltersIndexes];
    NSIndexPath *targetPath = [NSIndexPath indexPathForRow:_hiddenFiltersItems.count - 1 inSection:kHiddenFiltersSection];
    [CATransaction begin];
    [CATransaction setCompletionBlock:^{
        [self.tableView reloadData];
    }];
    [self.tableView beginUpdates];
    [self.tableView moveRowAtIndexPath:indexPath toIndexPath:targetPath];
    [self.tableView endUpdates];
    [CATransaction commit];
}

- (void)restoreMode:(NSIndexPath *)indexPath
{
    OAEditFilterItem *filterItem = _hiddenFiltersItems[indexPath.row];
    int order = filterItem.order;
    order = order > _filtersItems.count ? (int) _filtersItems.count : order;
    NSIndexPath *targetPath = [NSIndexPath indexPathForRow:order inSection:kAllFiltersSection];
    [CATransaction begin];
    [CATransaction setCompletionBlock:^{
        [self.tableView reloadData];
    }];
    [_hiddenFiltersItems removeObjectAtIndex:indexPath.row];
    [_filtersItems insertObject:filterItem atIndex:order];
    [_hiddenFiltersKeys removeObject:filterItem.filter.filterId];
    filterItem.filter.isActive = YES;
    [self.tableView beginUpdates];
    [self.tableView moveRowAtIndexPath:indexPath toIndexPath:targetPath];
    [self.tableView endUpdates];
    [CATransaction commit];
}

#pragma mark - Selectors

- (void)onLeftNavbarButtonPressed
{
    if (_isChanged)
        [self showChangesAlert];
    else
        [self.navigationController popViewControllerAnimated:YES];
}

- (void)onRightNavbarButtonPressed
{
    if (_isChanged)
    {
        OAApplicationMode *appMode = _settings.applicationMode.get;
        if (_hiddenModified)
            [_filtersHelper saveInactiveFilters:appMode filterIds:_hiddenFiltersKeys];
        else if (_wasReset)
            [_filtersHelper saveInactiveFilters:appMode filterIds:nil];
        if (_orderModified)
        {
            NSMutableArray<NSString *> *filterIds = [NSMutableArray new];
            for (OAEditFilterItem *filterItem in _filtersItems) {
                OAPOIUIFilter *filter = filterItem.filter;
                NSString *filterId = filter.filterId;
                NSNumber *order = [_filtersOrders objectForKey:filterId];
                if (order == nil)
                    order = @(filter.order);
                BOOL isActive = ![_hiddenFiltersKeys containsObject:filterId];
                filter.isActive = isActive;
                filter.order = [order intValue];
                if (isActive)
                    [filterIds addObject:filter.filterId];
            }
            [_filtersHelper saveFiltersOrder:appMode filterIds:filterIds];
        }
        else if (_wasReset)
        {
            [_filtersHelper saveFiltersOrder:appMode filterIds:nil];
        }
    }
    [[OAQuickSearchHelper instance] refreshCustomPoiFilters];
    [self dismissViewController];
}

- (void)onEditButtonPressed:(UIButton *)sender
{
    [self onLeftEditButtonPressed:sender.tag];
}

- (void)swipeToCloseRecognized:(UIGestureRecognizer *)recognizer
{
    if (_isChanged)
    {
        recognizer.enabled = NO;
        recognizer.enabled = YES;
        [self showChangesAlert];
    }
}

#pragma mark - OATableViewCellDelegate

- (void)onLeftEditButtonPressed:(NSInteger)tag
{
    _isChanged = YES;
    _hiddenModified = YES;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:tag & 0x3FF inSection:tag >> 10];
    if (indexPath.section == kAllFiltersSection)
        [self hideMode:indexPath];
    else if (indexPath.section == kHiddenFiltersSection)
        [self restoreMode:indexPath];
}

@end
