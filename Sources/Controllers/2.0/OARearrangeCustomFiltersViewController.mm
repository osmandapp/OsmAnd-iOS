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
#import "OADeleteButtonTableViewCell.h"
#import "OAColors.h"
#import "OAQuickSearchHelper.h"
#import "OAButtonRightIconCell.h"
#import "OAAppSettings.h"
#import "OAQuickSearchButtonListItem.h"

#define kAllFiltersSection 0
#define kHiddenFiltersSection 1
#define kActionsSection 2
#define kHideButtonCell @"OADeleteButtonTableViewCell"
#define kButtonRightIconCell @"OAButtonRightIconCell"
#define kHeaderViewFont [UIFont systemFontOfSize:15.0]

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

@interface OARearrangeCustomFiltersViewController() <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UIView *navBar;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;

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
}

- (instancetype)initWithFilters:(NSArray<OAPOIUIFilter *> *)filters
{
    self = [super init];
    if (self)
    {
        _settings = [OAAppSettings sharedManager];
        _filtersHelper = [OAPOIFiltersHelper sharedInstance];
        _orderModified = [_settings poiFiltersOrder] != nil;
        _hiddenModified = [_settings inactivePoiFilters] != nil;
        [self generateData:filters];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView setEditing:YES];
    self.tableView.allowsSelectionDuringEditing = YES;
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    _tableView.tableHeaderView = [OAUtilities setupTableHeaderViewWithText:OALocalizedString(@"rearrange_categories_descr") font:kHeaderViewFont textColor:UIColorFromRGB(color_text_footer) lineSpacing:6.0 isTitle:NO];
}

- (void)applyLocalization
{
    self.titleLabel.text = OALocalizedString(@"rearrange_categories");
    [self.cancelButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
    [self.doneButton setTitle:OALocalizedString(@"shared_string_done") forState:UIControlStateNormal];
}

- (void)generateData:(NSArray<OAPOIUIFilter *> *)filters
{
    _filtersItems = [NSMutableArray new];
    _hiddenFiltersItems = [NSMutableArray new];
    _filtersOrders = [NSMapTable new];
    _hiddenFiltersKeys = [NSMutableArray new];

    for (int i = 0; i < filters.count; i++)
    {
        OAPOIUIFilter *filter = filters[i];
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

- (IBAction)onCancelButtonClicked:(id)sender
{
    if (_isChanged)
        [self showChangesAlert];
    else
        [self dismissViewController];
}

- (IBAction)onDoneButtonClicked:(id)sender
{
    if (_isChanged)
    {
        OAApplicationMode *appMode = _settings.applicationMode;
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

- (void)onRowButtonClicked:(UIButton *)sender
{
    _isChanged = YES;
    _hiddenModified = YES;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:sender.tag & 0x3FF inSection:sender.tag >> 10];
    if (indexPath.section == kAllFiltersSection)
        [self hideMode:indexPath];
    else if (indexPath.section == kHiddenFiltersSection)
        [self restoreMode:indexPath];
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
        [_tableView reloadData];
    }];
    [_tableView beginUpdates];
    [_tableView moveRowAtIndexPath:indexPath toIndexPath:targetPath];
    [_tableView endUpdates];
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
        [_tableView reloadData];
    }];
    [_hiddenFiltersItems removeObjectAtIndex:indexPath.row];
    [_filtersItems insertObject:filterItem atIndex:order];
    [_hiddenFiltersKeys removeObject:filterItem.filter.filterId];
    filterItem.filter.isActive = YES;
    [_tableView beginUpdates];
    [_tableView moveRowAtIndexPath:indexPath toIndexPath:targetPath];
    [_tableView endUpdates];
    [CATransaction commit];
}

- (void)updateFiltersIndexes
{
    for (int i = 0; i < _filtersItems.count; i++)
        _filtersItems[i].order = i;
}

- (void)showChangesAlert
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:OALocalizedString(@"osm_editing_lost_changes_title") preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_exit") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self dismissViewController];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_cancel") style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - UITableViewDataSource

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    NSString *cellType = indexPath.section == kActionsSection ? kButtonRightIconCell : kHideButtonCell;
    if ([cellType isEqualToString:kHideButtonCell])
    {
        BOOL isAllFilters = indexPath.section == kAllFiltersSection;
        OAPOIUIFilter *filter = isAllFilters ? _filtersItems[indexPath.row].filter : _hiddenFiltersItems[indexPath.row].filter;
        OADeleteButtonTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:kHideButtonCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:kHideButtonCell owner:self options:nil];
            cell = (OADeleteButtonTableViewCell *) nib[0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.separatorInset = UIEdgeInsetsMake(0.0, 58.0, 0.0, 0.0);
        }
        if (cell)
        {
            cell.titleLabel.text = filter.name;
            UIImage *poiIcon = [UIImage templateImageNamed:filter.getIconId];
            cell.iconImageView.image = poiIcon ? poiIcon : [UIImage templateImageNamed:@"ic_custom_user"];
            NSString *imageName = isAllFilters ? @"ic_custom_delete" : @"ic_custom_plus";
            [cell.deleteButton setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
            cell.deleteButton.tag = indexPath.section << 10 | indexPath.row;
            [cell.deleteButton addTarget:self action:@selector(onRowButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        }
        return cell;
    }
    else if ([cellType isEqualToString:kButtonRightIconCell])
    {
        OAButtonRightIconCell *cell = [tableView dequeueReusableCellWithIdentifier:kButtonRightIconCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:kButtonRightIconCell owner:self options:nil];
            cell = nib[0];
            cell.separatorInset = UIEdgeInsetsMake(0., 65., 0., 0.);
        }
        if (cell) {
            OAActionItem *actionItem = _actionsItems[indexPath.row];
            cell.iconView.image = [actionItem.icon imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.iconView.tintColor = UIColorFromRGB(color_primary_purple);
            [cell.button setTitle:actionItem.title forState:UIControlStateNormal];
            cell.button.enabled = NO;
            return cell;
        }
    }
    return nil;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == kActionsSection)
        return indexPath;
    else
        return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == kActionsSection) {
        OAActionItem *actionItem = _actionsItems[indexPath.row];
        [actionItem onClick];
    }
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
        [_tableView reloadData];
    }];
    [_filtersItems removeObjectAtIndex:sourceIndexPath.row];
    [_filtersItems insertObject:filterItem atIndex:destinationIndexPath.row];
    [_filtersOrders removeObjectForKey:filterItem.filter.filterId];
    [_filtersOrders setObject:@(destinationIndexPath.row) forKey:filterItem.filter.filterId];
    [self updateFiltersIndexes];
    [CATransaction commit];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *title;
    if (section == kAllFiltersSection)
        title = OALocalizedString(@"visible_categories");
    else if (section == kHiddenFiltersSection)
        title = OALocalizedString(@"hidden_categories");
    else
        title = OALocalizedString(@"actions");
    return title;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return section == kActionsSection ? OALocalizedString(@"rearrange_categories_reset") : @"";
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == kAllFiltersSection)
        return _filtersItems.count;
    else if (section == kHiddenFiltersSection)
        return _hiddenFiltersItems.count;
    else
        return _actionsItems.count;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return indexPath.section == kAllFiltersSection;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    if ([view isKindOfClass:[UITableViewHeaderFooterView class]])
    {
        UITableViewHeaderFooterView *headerView = (UITableViewHeaderFooterView *) view;
        headerView.textLabel.textColor = UIColorFromRGB(color_text_footer);
    }
}

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

@end
